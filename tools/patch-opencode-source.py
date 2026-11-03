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

    upgrade = root / "packages/cli/src/commands/handlers/upgrade.ts"
    replace_once(
        upgrade,
        'import { stripVTControlCharacters } from "node:util"\n',
        'import { stripVTControlCharacters } from "node:util"\n'
        'import { Global } from "@opencode/util/global"\n'
        'import path from "node:path"\n',
    )
    replace_once(
        upgrade,
        '      intro("Upgrade")\n      const updater = yield* Updater.Service\n',
        '      intro("Upgrade")\n'
        '      const global = yield* Global.Service\n'
        '      if (process.execPath === path.join(global.home, ".local", "bin", "opencode")) {\n'
        '        return yield* Effect.fail(new Error(\n'
        '          "This native Termux build must be upgraded with its verified release installer: " +\n'
        '          "curl -fsSL https://github.com/Spectra010s/opencode-termux/raw/native-android/install.sh | sh"\n'
        '        ))\n'
        '      }\n'
        '      const updater = yield* Updater.Service\n',
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
