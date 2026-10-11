#!/usr/bin/env python3
"""Make the pinned OpenCode source compile with a verified Bun 1.4.0 runtime.

This patches only the build-time Bun version gate and lets the upstream build
script use a preverified Linux ARM64 Bun executable instead of downloading one.
The source tarball is SHA-256 checked before this script runs.
"""

import json
import sys
from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    source = path.read_text(encoding="utf-8")
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"expected one build anchor in {path}, found {count}: {old!r}")
    path.write_text(source.replace(old, new, 1), encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch-opencode-source-bun140.py SOURCE_ROOT")
    root = Path(sys.argv[1])
    package = root / "package.json"
    metadata = json.loads(package.read_text(encoding="utf-8"))
    if metadata.get("packageManager") != "bun@1.4.2":
        raise SystemExit(f"unexpected packageManager: {metadata.get('packageManager')!r}")
    replace_once(package, '"packageManager": "bun@1.4.2"', '"packageManager": "bun@1.4.0"')

    build = root / "packages/cli/script/build.ts"
    replace_once(
        build,
        "async function compileExecutable(item: (typeof allTargets)[number]) {\n",
        "async function compileExecutable(item: (typeof allTargets)[number]) {\n"
        ' const pinned = process.env.BUN_SOURCE_TARGET_ELF\n'
        ' if (pinned) {\n'
        '   if (item.os !== "linux" || item.arch !== "arm64" || item.abi) throw new Error("unexpected source-build target")\n'
        '   if (!(await Bun.file(pinned).exists())) throw new Error("pinned Bun target missing")\n'
        '   return pinned\n'
        ' }\n',
    )


if __name__ == "__main__":
    main()
