#!/usr/bin/env python3
"""Patch pinned OpenCode source for the verified Android/Bionic release.

The source is fetched at the commit recorded in the supply-chain lock before
this script runs. Each replacement must match exactly once so upstream changes
fail the build instead of silently dropping a safety patch.
"""

import json
import os
import sys
from pathlib import Path

LOCK = Path(__file__).resolve().parent / "supply-chain-lock.json"


def lock_bun_version(root: Path) -> str:
    lock = json.loads(LOCK.read_text(encoding="utf-8"))
    return lock["opencode"][lock["current"]]["bun_version"]


def replace_once(path: Path, old: str, new: str) -> None:
    source = path.read_text(encoding="utf-8")
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"expected one build anchor in {path}, found {count}: {old!r}")
    path.write_text(source.replace(old, new, 1), encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch-opencode-source.py SOURCE_ROOT")
    root = Path(sys.argv[1])
    package = root / "package.json"
    metadata = json.loads(package.read_text(encoding="utf-8"))
    declared = metadata.get("packageManager") or ""
    if not declared.startswith("bun@") or declared.count(".") != 2:
        raise SystemExit(f"unexpected packageManager: {declared!r}")
    # Upstream bumps this every release; rewrite it to the Bun that actually
    # compiles this build instead of pinning a literal here.
    pinned_bun = os.environ.get("OPENCODE_BUN_VERSION") or lock_bun_version(root)
    replace_once(package, f'"packageManager": "{declared}"', f'"packageManager": "bun@{pinned_bun}"')

    build = root / "packages/cli/script/build.ts"
    replace_once(
        build,
        "async function compileExecutable(item: (typeof allTargets)[number]) {\n",
        "async function compileExecutable(item: (typeof allTargets)[number]) {\n"
        ' const pinned = process.env.BUN_SOURCE_TARGET_ELF\n'
        ' if (pinned) {\n'
        '   if (item.os !== "linux" || item.arch !== "arm64" || item.abi) throw new Error("unexpected source-build target " + item.os + "-" + item.arch + (item.abi ? "-" + item.abi : "") + " (set OPENCODE_TARGET=linux-arm64)")\n'
        '   if (!(await Bun.file(pinned).exists())) throw new Error("pinned Bun target missing")\n'
        '   return pinned\n'
        ' }\n',
    )

    # Bionic has no glibc pty helper: for a cross arm64 build upstream resolves
    # @opencode/pty-linux-arm64-gnu and embeds that binary. It cannot exec on
    # Android. build.ts already emits "export default undefined" when the asset
    # is missing, so resolve it only when host and target agree.
    replace_once(
        build,
        "  const opencodePty = await resolveOpencodePty({\n"
        "    platform: item.os,\n"
        "    arch: item.arch,\n"
        '    ...(item.os === "linux" ? { libc: item.abi ?? "glibc" } : {}),\n'
        "  })\n",
        "  const opencodePty: Awaited<ReturnType<typeof resolveOpencodePty>> =\n"
        "    item.os === process.platform && item.arch === process.arch\n"
        "      ? await resolveOpencodePty({\n"
        "          platform: item.os,\n"
        "          arch: item.arch,\n"
        '          ...(item.os === "linux" ? { libc: item.abi ?? "glibc" } : {}),\n'
        "        })\n"
        "      : undefined\n",
    )

    # The CLI aliases `update` to `upgrade`; the TUI's /update calls Updater.apply.
    # Keep the native installer in their shared service so both paths use it.
    updater = root / "packages/cli/src/services/updater.ts"
    replace_once(
        updater,
        'export const methods = ["curl", "npm", "pnpm", "bun", "yarn", "vp", "brew", "winget"] as const\n',
        'export const methods = ["curl", "npm", "pnpm", "bun", "yarn", "vp", "brew", "winget", "apt"] as const\n',
    )
    replace_once(updater, '  winget: "WinGet",\n', '  winget: "WinGet",\n  apt: "APT",\n')
    replace_once(
        updater,
        '  const curlBinary = yield* fs.realPath(curlPath).pipe(Effect.orElseSucceed(() => curlPath))\n',
        '  const curlBinary = yield* fs.realPath(curlPath).pipe(Effect.orElseSucceed(() => curlPath))\n'
        '  const termuxPath = path.join(global.home, ".local", "bin", "opencode")\n'
        '  const termuxBinary = yield* fs.realPath(termuxPath).pipe(Effect.orElseSucceed(() => termuxPath))\n'
        '  const nativeTermux = executable === termuxBinary\n',
    )
    replace_once(
        updater,
        '    if (executable === curlBinary) return "curl"\n',
        '    if (executable === curlBinary) return "curl"\n'
        '    const prefix = process.env.PREFIX\n'
        '    if (prefix && executable === path.join(prefix, "bin", "opencode")) {\n'
        '      const owner = yield* exec(["dpkg-query", "-S", executable]).pipe(Effect.orElseSucceed(() => undefined))\n'
        '      if (owner?.code === 0 && owner.stdout.split("\\n").includes(`opencode: ${executable}`)) return "apt"\n'
        '    }\n'
        '    if (nativeTermux) return "curl"\n'
        '    if (prefix) return\n',
    )
    replace_once(
        updater,
        '    if (method === "winget") return ["winget", "uninstall", ...wingetArgs]\n',
        '    if (method === "winget") return ["winget", "uninstall", ...wingetArgs]\n'
        '    if (method === "apt") return ["apt-get", "remove", "--yes", "opencode"]\n',
    )
    replace_once(
        updater,
        '  const latest = (selected?: Method) =>\n',
        '  const termuxLatest = Effect.tryPromise({\n'
        '    try: async (signal) => {\n'
        '      const response = await fetch("https://api.github.com/repos/Spectra010s/opencode-termux/releases/latest", {\n'
        '        signal: AbortSignal.any([signal, AbortSignal.timeout(10_000)]),\n'
        '        headers: { Accept: "application/vnd.github+json" },\n'
        '      })\n'
        '      if (!response.ok) throw new Error(`GitHub releases returned HTTP ${response.status}`)\n'
        '      const data: { tag_name?: string } = await response.json()\n'
        '      const version = data.tag_name?.replace(/^v/, "")\n'
        '      if (!version || !/^\\d+\\.\\d+\\.\\d+$/.test(version)) throw new Error("Latest release has no valid version")\n'
        '      return version\n'
        '    },\n'
        '    catch: (cause) => new Error(`Could not check native Termux releases: ${errorDetail(cause)}`),\n'
        '  })\n'
        '  const latest = (selected?: Method) =>\n',
    )
    replace_once(
        updater,
        '  const latest = (selected?: Method) =>\n'
        '    (selected ? Effect.succeed(selected) : method()).pipe(\n'
        '      Effect.flatMap((method) =>\n'
        '        method === "winget" ? wingetVersion() : release(method).pipe(Effect.map((data) => data.version)),\n'
        '      ),\n'
        '    )\n',
        '  const latest = (selected?: Method) =>\n'
        '    (selected ? Effect.succeed(selected) : method()).pipe(\n'
        '      Effect.flatMap((detected) =>\n'
        '        nativeTermux || detected === "apt"\n'
        '          ? termuxLatest\n'
        '          : detected === "winget" ? wingetVersion() : release(detected).pipe(Effect.map((data) => data.version)),\n'
        '      ),\n'
        '    )\n',
    )
    replace_once(
        updater,
        '    const version = input.trim().replace(/^v/, "")\n    const packageName =\n',
        '    const version = input.trim().replace(/^v/, "")\n'
        '    if (method === "apt") {\n'
        '      const prefix = process.env.PREFIX\n'
        '      if (!prefix || executable !== path.join(prefix, "bin", "opencode"))\n'
        '        return yield* Effect.fail(new Error("This binary is not installed by APT"))\n'
        '      const owner = yield* exec(["dpkg-query", "-S", executable]).pipe(Effect.orElseSucceed(() => undefined))\n'
        '      if (!owner || owner.code !== 0 || !owner.stdout.split("\\n").includes(`opencode: ${executable}`))\n'
        '        return yield* Effect.fail(new Error("This binary is not owned by the OpenCode APT package"))\n'
        '      yield* Effect.scoped(Effect.gen(function* () {\n'
        '        yield* flock.acquire("cli-upgrade", undefined, { timeoutMs: Duration.toMillis("5 hours") })\n'
        '        const updated = yield* exec(["apt-get", "update"], "30 minutes")\n'
        '        if (updated.code !== 0) return yield* Effect.fail(new Error(resultDetail(updated)))\n'
        '        const installed = yield* exec(["apt-get", "install", "--only-upgrade", "--yes", "opencode"], "4 hours")\n'
        '        if (installed.code !== 0) return yield* Effect.fail(new Error(resultDetail(installed)))\n'
        '        const actual = yield* exec([executable, "--version"])\n'
        '        if (actual.code !== 0 || actual.stdout.trim() !== version)\n'
        '          return yield* Effect.fail(new Error(`APT did not install OpenCode ${version}: ${resultDetail(actual)}`))\n'
        '      }))\n'
        '      return\n'
        '    }\n'
        '    if (nativeTermux) {\n'
        '      if (!/^\\d+\\.\\d+\\.\\d+$/.test(version)) return yield* Effect.fail(new Error(`Unsupported native Termux release: ${input}`))\n'
        '      yield* Effect.scoped(Effect.gen(function* () {\n'
        '        yield* flock.acquire("cli-upgrade", undefined, { timeoutMs: Duration.toMillis("5 hours") })\n'
        '        yield* fs.makeDirectory(global.cache, { recursive: true })\n'
        '        const directory = yield* temporaryDirectory("update-")\n'
        '        const installer = path.join(directory, "install.sh")\n'
        '        yield* runUpgrade({\n'
        '          method: "curl",\n'
        '          command: ["curl", "-fsSL", "--retry", "3", "-o", installer, `https://raw.githubusercontent.com/Spectra010s/opencode-termux/v${version}/install.sh`],\n'
        '          title: "Could not download the native Termux installer",\n'
        '        })\n'
        '        const result = yield* exec(["sh", installer, "--version", version], "4 hours")\n'
        '        if (result.code !== 0) return yield* Effect.fail(new Error(resultDetail(result)))\n'
        '      }))\n'
        '      return\n'
        '    }\n'
        '    const packageName =\n',
    )
    replace_once(
        updater,
        '    const commands: Record<Exclude<Method, "bun" | "curl" | "brew" | "winget">, string[]> = {\n',
        '    const commands: Record<Exclude<Method, "bun" | "curl" | "brew" | "winget" | "apt">, string[]> = {\n',
    )
    replace_once(
        updater,
        '        new Error(\n'
        '          "Could not detect the installation method. Update with your package manager or download the latest release.",\n',
        '        new Error(\n'
        '          "Could not detect the installation method. See https://github.com/Spectra010s/opencode-termux#install for manual installation.",\n',
    )
    replace_once(
        updater,
        '        message:\n'
        '          "Could not detect the installation method. Update with your package manager or download the latest release.",\n',
        '        message:\n'
        '          "Could not detect the installation method. See https://github.com/Spectra010s/opencode-termux#install for manual installation.",\n',
    )

    upgrade = root / "packages/cli/src/commands/handlers/upgrade.ts"
    replace_once(
        upgrade,
        '          new Error("Could not detect the installation method. Pass --method to choose how to upgrade OpenCode."),\n',
        '          new Error("Could not detect the installation method. See https://github.com/Spectra010s/opencode-termux#install for manual installation."),\n',
    )

    uninstall = root / "packages/cli/src/commands/handlers/uninstall.ts"
    replace_once(
        uninstall,
        '    const method = yield* updater.method()\n',
        '    const nativeBinary = process.execPath === path.join(global.home, ".local", "bin", "opencode")\n'
        '    const method = yield* updater.method()\n',
    )
    replace_once(
        uninstall,
        '    if (method === "curl") log.info(`  Binary (manual removal): ${process.execPath}`)\n'
        '    if (!method) log.warn("Could not detect the installation method. Remove the installation manually after cleanup.")\n',
        '    if (nativeBinary) log.info(`  Binary: ${process.execPath}`)\n'
        '    else if (method === "curl") log.info(`  Binary (manual removal): ${process.execPath}`)\n'
        '    if (!method && !nativeBinary) log.warn("Could not detect the installation method. Remove the installation manually after cleanup.")\n',
    )
    replace_once(
        uninstall,
        '    if (method === "curl") {\n      log.message("To finish removing the binary, run:")\n',
        '    if (nativeBinary) {\n'
        '      yield* fs.remove(process.execPath).pipe(\n'
        '        Effect.catch((error) => Effect.sync(() => errors.push(`Binary: ${errorMessage(error)}`))),\n'
        '      )\n'
        '    }\n'
        '    if (method === "curl") {\n      log.message("To finish removing the binary, run:")\n',
    )


if __name__ == "__main__":
    main()
