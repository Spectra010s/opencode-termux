#!/usr/bin/env python3
"""Clear top-byte tags from pointers in OpenTUI's Bun FFI shim.

On some Android/Termux builds bionic hands out heap pointers whose top byte
carries a tag (top-byte-ignore tagging, e.g. 0xb4000075ac80a000 for a mapping
at 0x75ac400000). The address itself stays in the low 48 bits; only the tag
byte is extra.

OpenTUI 0.8.0 converts native pointers to JS numbers and rejects anything above
Number.MAX_SAFE_INTEGER, so every tagged pointer looks unsafe and the TUI dies
at ot_context_create with "Pointer exceeds safe integer range" before drawing a
single frame. Unpatched, `opencode --version` and the server keep working --
only the renderer aborts.

The mask is lossless and strictly additive: a pointer that already fits the
safe range has a zero top byte, so masking changes nothing for it, and only
conversions that used to throw become usable. Untagged platforms are unaffected.

    patch-opentui-ffi.py <opencode-source-tree>
"""

import argparse
import re
from pathlib import Path

MASK = "0x00ffffffffffffffn"
FUNC = re.compile(r"function toSafeNumberPointer\((?P<arg>[A-Za-z_$][\w$]*)\)")


def patch_file(path: Path) -> bool | None:
    """Return True when patched, False when already patched, None without a shim."""
    text = path.read_text(encoding="utf-8")
    match = FUNC.search(text)
    if not match:
        return None
    arg = match.group("arg")

    check = re.search(
        rf"^(?P<indent>[ \t]*)if \({re.escape(arg)} > BigInt\(Number\.MAX_SAFE_INTEGER\)\)",
        text[match.end() :],
        re.MULTILINE,
    )
    if not check:
        raise SystemExit(
            f"patch-opentui-ffi: {path}: toSafeNumberPointer found without its "
            "unsafe-integer check; upstream changed the shim"
        )

    position = match.end() + check.start()
    if MASK in text[match.start() : position]:
        return False

    indent = check.group("indent")
    insert = f"{indent}{arg} &= {MASK};\n"
    path.write_text(text[:position] + insert + text[position:], encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("tree", type=Path, help="OpenCode source tree")
    args = parser.parse_args()
    if not args.tree.is_dir():
        raise SystemExit(f"patch-opentui-ffi: not a directory: {args.tree}")

    candidates = sorted(args.tree.glob("**/node_modules/@opentui/core/chunk-*.js"))
    if not candidates:
        raise SystemExit(
            "patch-opentui-ffi: no @opentui/core chunks found; run bun install first"
        )

    patched, seen = [], 0
    for path in candidates:
        state = patch_file(path)
        if state is None:
            continue
        seen += 1
        if state:
            patched.append(path)
    if not seen:
        raise SystemExit(
            "patch-opentui-ffi: no toSafeNumberPointer shim in @opentui/core chunks"
        )

    for path in patched:
        print(f"patch-opentui-ffi: masked top-byte pointer tags in {path.name}")
    if not patched:
        print(f"patch-opentui-ffi: already applied to {seen} chunk(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
