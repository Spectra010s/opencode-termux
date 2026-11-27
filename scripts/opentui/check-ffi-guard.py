#!/usr/bin/env python3
"""Verify that an unstripped bionic libopentui.so carries the compiled guards.

Scans the code ranges of the guard-owning symbols for the AArch64 patterns:
a `#0x7fffffff` clamp (MOVN #0x8000, LSL #16) and a saturating add with
`csel ..., vs`. Stripping drops the local symbols this needs, so the workflow
runs this before llvm-strip.

Usage: python3 scripts/opentui/check-ffi-guard.py <libopentui.so>
Exit 0 when both patterns are present, 1 otherwise.
"""
import argparse
import struct
import sys
from pathlib import Path


def _iter_func_syms(data: bytes):
    """Yield (name, FILE OFFSET, st_size) for every defined STT_FUNC symbol in
    SHT_SYMTAB, falling back to SHT_DYNSYM after distribution stripping.
    st_value is a virtual address: translate through PT_LOAD segments."""
    if data[4] != 2:  # EI_CLASS != ELFCLASS64
        raise ValueError("not ELF64")
    e_phoff = struct.unpack_from("<Q", data, 0x20)[0]
    e_phentsize = struct.unpack_from("<H", data, 0x36)[0]
    e_phnum = struct.unpack_from("<H", data, 0x38)[0]
    loads = []
    for n in range(e_phnum):
        po = e_phoff + n * e_phentsize
        p_type = struct.unpack_from("<I", data, po + 0x0)[0]
        if p_type == 1:  # PT_LOAD
            p_offset = struct.unpack_from("<Q", data, po + 0x8)[0]
            p_vaddr = struct.unpack_from("<Q", data, po + 0x10)[0]
            p_filesz = struct.unpack_from("<Q", data, po + 0x20)[0]
            loads.append((p_vaddr, p_offset, p_filesz))

    def vaddr_to_off(v):
        for p_vaddr, p_offset, p_filesz in loads:
            if p_vaddr <= v < p_vaddr + p_filesz:
                return v - p_vaddr + p_offset
        raise ValueError(f"symbol vaddr {v:#x} not in any PT_LOAD")

    e_shoff = struct.unpack_from("<Q", data, 0x28)[0]
    e_shentsize = struct.unpack_from("<H", data, 0x3A)[0]
    e_shnum = struct.unpack_from("<H", data, 0x3C)[0]
    symtab_off = symtab_size = symtab_entsize = strtab_off = None
    for wanted_type in (2, 11):  # SHT_SYMTAB, then SHT_DYNSYM
        for n in range(e_shnum):
            so = e_shoff + n * e_shentsize
            s_type = struct.unpack_from("<I", data, so + 0x4)[0]
            if s_type == wanted_type:
                symtab_off = struct.unpack_from("<Q", data, so + 0x18)[0]
                symtab_size = struct.unpack_from("<Q", data, so + 0x20)[0]
                symtab_entsize = struct.unpack_from("<Q", data, so + 0x38)[0]
                link = struct.unpack_from("<I", data, so + 0x28)[0]
                strtab_so = e_shoff + link * e_shentsize
                strtab_off = struct.unpack_from("<Q", data, strtab_so + 0x18)[0]
                break
        if symtab_off is not None:
            break
    if symtab_off is None:
        raise ValueError("no SHT_SYMTAB or SHT_DYNSYM function table")
    for off in range(symtab_off, symtab_off + symtab_size, symtab_entsize):
        st_name = struct.unpack_from("<I", data, off)[0]
        st_info = data[off + 4]
        st_shndx = struct.unpack_from("<H", data, off + 6)[0]
        st_value = struct.unpack_from("<Q", data, off + 8)[0]
        st_size = struct.unpack_from("<Q", data, off + 16)[0]
        if st_shndx == 0 or st_size == 0 or (st_info & 0xF) != 2:  # STT_FUNC
            continue
        end = data.index(b"\x00", strtab_off + st_name)
        name = data[strtab_off + st_name:end].decode("utf-8", "replace")
        yield name, vaddr_to_off(st_value), st_size


# Functions whose code contains (or inlines) the FFI guard logic. Scanning all
# of their ranges is inlining-agnostic: the crashfix-era build inlined
# isPointInScissor into bufferDrawChar, while the 0.1.101 build keeps them
# out-of-line (setCellWithAlphaBlending etc).
_GUARD_OWNER_SUBSTRINGS = (
    "bufferDrawChar",
    "isPointInScissor",
    "isRectInScissor",
    "clipRectToScissor",
    "setCellWithAlphaBlending",
    "drawGrayscaleBuffer",
    "drawTextBufferInternal",
    "clipRectToHitScissor",
    "addToHitGrid",
    "pushScissorRect",
)

def has_ffi_guard(lib: bytes) -> bool:
    """Guard verification: scan the code ranges of all
    guard-owning symbols for the compiled guard patterns: `mov wN,
    #0x7fffffff` clamps (MOVN #0x8000,LSL#16) + saturating-add `csel ..., vs`.
    An unguarded build has plain adds + b.vs integerOutOfBounds branches in
    those ranges instead. Verified differentially: crashfix v2 .so passes,
    1.18.27 batch .so fails."""
    try:
        owners = []
        for name, value, size in _iter_func_syms(lib):
            if any(sub in name for sub in _GUARD_OWNER_SUBSTRINGS):
                owners.append((name, value, min(size, len(lib) - value)))
    except ValueError as e:
        print(f"check-ffi-guard: guard check cannot run: {e}", file=sys.stderr)
        return False
    if not owners:
        print("check-ffi-guard: guard check cannot run: no guard-owner symbols found", file=sys.stderr)
        return False
    clamp = csel_vs = 0
    for _, start, size in owners:
        for off in range(start, start + size - 3, 4):
            w = struct.unpack_from("<I", lib, off)[0]
            if (w & 0xFFFFFFE0) == 0x12B00000:  # movn wd, #0x8000, lsl #16 => mov wd, #0x7fffffff
                clamp += 1
            elif (w & 0xFFE00C00) == 0x1A800000 and ((w >> 12) & 0xF) == 6:  # csel wd,wn,wm,vs
                csel_vs += 1
    print(f"check-ffi-guard: guard scan over {len(owners)} owner symbols: clamp={clamp} csel_vs={csel_vs}")
    return clamp >= 1 and csel_vs >= 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("lib", type=Path, help="unstripped libopentui.so")
    args = ap.parse_args()
    try:
        lib = args.lib.read_bytes()
    except OSError as e:
        print(f"check-ffi-guard: cannot read {args.lib}: {e}", file=sys.stderr)
        return 1
    return 0 if has_ffi_guard(lib) else 1


if __name__ == "__main__":
    raise SystemExit(main())
