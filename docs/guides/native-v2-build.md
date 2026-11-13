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
python3 tools/ocver.py current            # 2.2.7
python3 tools/ocver.py tag                # v2.2.7
python3 tools/ocver.py field bun_version  # 1.4.4
```

Current release record: OpenCode `2.2.7` (commit `fedc6f20…`) on Bun `1.4.4`,
OpenTUI `0.8.1` (commit `9a09079c…`), bun-pty `0.4.11` against
`portable-pty 0.9`, Zig `0.17.0`, `ANDROID_API=28`. Bun `1.4.4` is the only
supported host and base — upstream `package.json` declares
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
4. Runs `scripts/ci/build-opencode-bundle.sh`. This is the default strategy
   (`strategy: bundle`). It patches `build.ts` for a `linux-arm64-android`
   bundle with install directory `@TERMUX_PREFIX@/lib/opencode`, cross-builds
   `librust_pty_arm64.so` (`scripts/ci/build-rust-pty-android.sh`), installs the
   `@parcel/watcher` Android module, and makes every `@opentui/core-linux-*`
   slot byte-identical so Bun emits one hashed `libopentui` asset instead of
   four.
5. Stages the candidate with `scripts/ci/package-release-bundle.sh`: the
   `.deb`, the `tar.gz`, `Packages`/`Release`, and one `SHA256SUMS`.
6. Publishes through `.github/workflows/publish-native-android.yml` on a tag
   push. The publish run calls this same build workflow as its first job, so
   the released files are the ones that run built: it re-verifies the
   checksums, signs the APT index, and publishes
   [`.release/v<version>.md`](../../.release). See
   [`../ops/apt-repository.md`](../ops/apt-repository.md) for the signed source and its failure modes.

The bundle build refuses to produce a product unless the embedded OpenTUI passes
the FFI guard scan (`clamp=9`, `csel_vs>0`; the marker survives because the
build patches source before `Bun.build`), the `@TERMUX_PREFIX@` placeholder is
still unsubstituted, and the curated highlights from
`.release/v<version>-highlights.md` landed in an emitted chunk.

## Path 2 — on-device (Termux, no NDK)

Termux is already Bionic, so this path needs no NDK. Full guide:
`docs/reference/transplant.md`.

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

2.2.7 ships a bundle, not a spliced ELF, so the release path no longer touches
`swap_tui.py`. The `source` strategy and `make transplant` still compile
against the Android Bun ELF for comparison builds; running `transplant.py all`
on an already compiled 1.4.4 ELF produced a binary that failed on device, which
is why the bundle is the default.
