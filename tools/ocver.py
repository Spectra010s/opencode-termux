#!/usr/bin/env python3
"""Read pinned versions from tools/supply-chain-lock.json.

The lock file is the single source of truth. Workflows, CI scripts and the
installer must ask this helper instead of repeating a version literal.

    ocver.py current                 -> <version> from the lock
    ocver.py tag [version]           -> v<version>
    ocver.py field <name> [version]  -> lock["opencode"][version][name]
    ocver.py asset [strategy]        -> opencode-<version>-android-aarch64-<strategy>

`version` defaults to the lock's "current" entry. `strategy` defaults to
bundle.
"""
import json
import sys
from pathlib import Path

LOCK = Path(__file__).resolve().parent / "supply-chain-lock.json"


def load() -> dict:
    return json.loads(LOCK.read_text(encoding="utf-8"))


def resolve(argv: list[str]) -> str:
    if not argv:
        raise SystemExit(__doc__)
    command, rest = argv[0], argv[1:]
    lock = load()

    if command == "current":
        return lock["current"]

    if command == "tag":
        return "v" + (rest[0] if rest else lock["current"])

    if command == "field":
        if not rest:
            raise SystemExit("ocver: field needs a name")
        name, tail = rest[0], rest[1:]
        version = tail[0] if tail else lock["current"]
        try:
            value = lock["opencode"][version][name]
        except KeyError:
            raise SystemExit(f"ocver: no {name!r} for opencode {version}")
        return value if isinstance(value, str) else json.dumps(value)

    if command == "asset":
        strategy = rest[0] if rest else "source"
        version = rest[1] if len(rest) > 1 else lock["current"]
        if strategy in ("bundle", "bundle-el"):
            return f"opencode-{version}-android-aarch64-bundle"
        suffix = "" if strategy == "upstream-transplant" else f"-{strategy}"
        return f"opencode-{version}-android-aarch64{suffix}"

    if command == "bunpty":
        if not rest:
            raise SystemExit("ocver: bunpty needs a field (ref, commit, portable_pty)")
        try:
            return lock["bun_pty"][rest[0]]
        except KeyError:
            raise SystemExit(f"ocver: no bun-pty {rest[0]!r} in the lock")

    raise SystemExit(f"ocver: unknown command {command!r}")


if __name__ == "__main__":
    print(resolve(sys.argv[1:]))
