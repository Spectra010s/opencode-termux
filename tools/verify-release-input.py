#!/usr/bin/env python3
"""Resolve and verify immutable OpenCode/Bun build inputs."""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LOCK = ROOT / "tools" / "supply-chain-lock.json"
VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")


def fail(message: str) -> None:
    print(f"verify-release-input: ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--kind",
        required=True,
        choices=("opencode", "opencode-cli", "bun-archive", "bun-elf"),
    )
    parser.add_argument("--version", required=True)
    parser.add_argument("--file", type=Path)
    parser.add_argument(
        "--print-field",
        choices=("commit", "source_sha256", "cli_linux_arm64_sha256", "archive_sha256", "elf_sha256"),
    )
    args = parser.parse_args()

    if not VERSION_RE.fullmatch(args.version):
        fail(f"invalid version: {args.version!r}")
    lock = json.loads(LOCK.read_text(encoding="utf-8"))
    family = "opencode" if args.kind.startswith("opencode") else "android_bun"
    entry = lock.get(family, {}).get(args.version)
    if not entry:
        fail(f"{family} {args.version} is not pinned in {LOCK}")

    if args.print_field:
        value = entry.get(args.print_field)
        if not value:
            fail(f"field {args.print_field} is not pinned for {family} {args.version}")
        print(value)
        return 0

    if args.file is None or not args.file.is_file():
        fail("--file must name an existing regular file")
    field = {
        "opencode": "source_sha256",
        "opencode-cli": "cli_linux_arm64_sha256",
        "bun-archive": "archive_sha256",
        "bun-elf": "elf_sha256",
    }[args.kind]
    expected = entry.get(field)
    if not expected:
        fail(f"missing {field} for {family} {args.version}")
    actual = digest(args.file)
    if actual != expected:
        fail(f"SHA-256 mismatch for {args.file}: expected {expected}, got {actual}")
    print(f"verified {args.kind} {args.version}: {actual}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
