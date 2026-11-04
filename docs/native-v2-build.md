# Native v2 build

Target: OpenCode native Android/aarch64 Bionic, no proot and no glibc.

## Pinned inputs

`tools/supply-chain-lock.json` is the source of truth for CI build inputs.
The build workflow reads its `current` version. The release installer pins its
tag so a tagged copy cannot silently install a later release.

| Key | Meaning |
|---|---|
| `current` | OpenCode version this branch builds and publishes |
| `opencode[current]` | upstream commit + `source_sha256` + `bun_version` + `opentui_version` |
| `opentui[<ver>]` | OpenTUI commit, required Zig version, Zig archive hash |
| `android_bun[<ver>]` | Android/Bionic Bun base archive + ELF hashes |
| `source_build_bun_<ver>` | host Bun archive hash used to compile the CLI |

`tools/ocver.py` is the only reader. Use it instead of hardcoding:

```sh
python3 tools/ocver.py current            # 2.2.5
python3 tools/ocver.py tag                # v2.2.5
python3 tools/ocver.py field bun_version  # 1.4.4
python3 tools/ocver.py asset source       # opencode-2.2.5-android-aarch64-source
```

Current release record: OpenCode `2.2.5` (commit `9bbb8ce1…`) on Bun `1.4.4`,
OpenTUI `0.8.0` (commit `738067f4…`), Zig `0.16.0`, `ANDROID_API=28`. Bun `1.4.4`
is the only supported host and base — upstream `package.json` declares
`packageManager: bun@1.4.4`, and there is no 1.4.2 fallback.

## Path 1 — CI (release path)

`.github/workflows/build-native-android.yml`:

1. Resolves `OPENCODE_VERSION`, `BUN_VERSION`, `OPENTUI_VERSION` and `ZIG_VERSION`
   from the lock.
2. Fetches the pinned OpenCode commit, rewrites `packageManager` to the pinned
   Bun via `tools/patch-opencode-source.py`, and installs with the pinned host Bun.
3. Cross-compiles OpenTUI for `aarch64-linux-android.28` with the NDK sysroot,
   Zig, and `patches/opentui/tlsdesc-shim.c`. `tools/patch-opentui-android.py`
   applies the bionic build hooks and the FFI guards. It is version-agnostic: a
   missing required anchor fails the build, while guards upstream already fixed
   are skipped.
4. Runs `scripts/ci/build-opencode-source.sh`, which compiles the CLI with
   `BUN_SOURCE_TARGET_ELF` set to the pinned Android Bun, then swaps the
   bionic `libopentui.so` into that compiled ELF. The 1.4.4 build does not
   re-splice the already Android-targeted graph.
5. Publishes through `.github/workflows/publish-native-android.yml` after
   verifying the artifact. Bump the tag in `install.sh` when preparing each
   release, and keep it aligned with the lock's `current` version.

The pipeline refuses to produce a product unless the embedded OpenTUI passes the
FFI guard scan (`clamp=9`, `csel_vs>0`) and the swap reports `status: ok`.

## Path 2 — on-device (Termux, no NDK)

Termux is already Bionic, so this path needs no NDK. Full guide:
`docs/transplant.md`.

```sh
pkg install python3 nodejs clang make zig   # zig only to rebuild OpenTUI
make transplant VER=<version>
```

`transplant.py` resolves the Bun base from
`tools/transplant/config/bun-bind.json`, which is pinned to the same Bun version
as the lock entry; a mismatch aborts instead of silently pairing the wrong base.

Output: `artifacts/transplant/<ver>/opencode-native-tui` plus `report.json`.
Then test: `opencode --version`, TUI smoke, auth, prompt, clean exit.

The on-device path needs a prebuilt `artifacts/transplant/opentui-bionic/libopentui.so`
for the swap. Without it the Makefile marks the report `tui: absent` — an
explicit gap, never a silent skip.

## Why the transplant tools remain

For 2.2.5, CI compiles directly against the Android Bun ELF and uses only
`swap_tui.py` from the transplant tools. The older `transplant.py all` path
remains for supported transplant builds; running it on this already compiled
1.4.4 ELF produced a binary that failed on device.
