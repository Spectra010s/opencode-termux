# Native v2 build

OpenCode for Termux is the pinned upstream source with a set of patches applied
before `Bun.build`, plus native libraries cross-built for bionic aarch64. The
result is JavaScript under `$PREFIX/lib/opencode/` run by Termux's `bun`, with
a launcher at `$PREFIX/bin/opencode`.

This document records what is patched and why. The executable steps are
`.github/workflows/build-native-android.yml` and the scripts under `scripts/ci/`.

## Pinned inputs

`supply-chain-lock.json` is the only source of build inputs: the upstream commit
and its hash, the OpenTUI commit and Zig version with archive hash, the host Bun
archive hash, the bun-pty ref and the package revision. `scripts/ocver.py` is
the only reader:

```sh
python3 scripts/ocver.py current
python3 scripts/ocver.py tag
python3 scripts/ocver.py field bun_version
python3 scripts/ocver.py field opentui_version
```

The host Bun in the lock is the compiler that runs `Bun.build`; it is never
shipped. The device gets whatever `bun` Termux installs, via the deb's
`Depends: bun (>= ...)`.

## Patches to the OpenCode source

All of these run on the pinned checkout before the bundle is built. Binary-level
edits after `Bun.build` are useless because `bytecode: true` freezes the JS.

### `scripts/patch-opencode-source.py`

- Rewrites upstream's `packageManager` to the Bun that actually builds this
  release, so the pinned source and the build tool agree.
- Resolves the pty helper only when host and target match. Upstream would embed
  `@opencode/pty-linux-arm64-gnu`, which cannot exec on bionic; the bionic PTY
  comes from `librust_pty_arm64.so` instead.
- Adds `android` to the recursive-watcher platform check. Termux reports
  `process.platform === "android"`, and without this the watcher silently has
  no backend even though the bionic `@parcel/watcher` module works.
- Adds `apt` to the installer methods and points unsupported-install messages
  at this repo's install page.
- Makes updater method detection and uninstall use `OPENCODE_LAUNCHER` instead
  of `process.execPath`. Under `bun`, `process.execPath` is the interpreter, so
  uninstall would otherwise delete the user's Bun binary.

Every replacement must match exactly once. An upstream move fails the build
rather than silently dropping a patch.

### `scripts/patch-opencode-bundle.py`

- Adds a `linux-arm64-android` bundle target that emits the module graph as
  JavaScript into `@TERMUX_PREFIX@/lib/opencode`, instead of compiling a
  single ELF that embeds Bun and every native asset.
- Keeps `compileExecutable` out of the Android target: the product is a bundle,
  not a compiled binary.
- Emits installed assets with `{ type: "file" }` and an absolute `publicPath`,
  so Bun records the runtime path rather than a build-machine path.
- Wires the separately built bionic watcher module into the bundle; there is no
  `@parcel/watcher-linux-arm64-android` package for Bun to resolve.

### `scripts/patch-fff-android.py`

`@ff-labs/fff-bun` ships an `aarch64-linux-android` library, but its resolver
only names darwin, win32 and linux. On Termux it returns null and falls back to
`rg --files` every ten seconds. The patch adds the Android branch that imports
the packaged `.so` as a file asset, the same way the other platforms do.

## Patches to OpenTUI

### `scripts/patch-opentui-android.py`

Upstream has no Android target, so these `build.zig` hooks are required:

- Add bionic include paths to every `translate-c` step, plus an empty
  `src/bionic-include-next/limits.h` to stop bionic's `#include_next` from
  falling through to host glibc headers.
- For `.linux` targets with `BIONIC_LIB_DIR` set, link `dl` and `m` but not
  `pthread`, which lives in libc on Android.
- Compile `patches/opentui/tlsdesc-shim.c` into the module: bionic before 11
  ignores TLSDESC relocations, and there is no `pthread_tryjoin_np` library.
- Skip the static archive and its `bundle-libcxx` step on Android. That step
  spawns a nested `zig build-lib` which never receives this build's bionic
  `--libc` file, and Zig carries no bionic libc. The bundle ships only the
  shared `libopentui.so`.

The integer-overflow guards in buffer/renderer are optional: applied when their
anchor exists, skipped when upstream has already fixed them. Required hooks
fail loudly if upstream moves them.

### `scripts/patch-opentui-ffi.py`

Bionic can hand out heap pointers with a tag in the top byte. OpenTUI's
`toSafeNumberPointer()` rejects anything above `Number.MAX_SAFE_INTEGER`, so the
TUI dies at context creation. The patch passes the tagged BigInt straight to
Bun's FFI. Masking the tag only moves the crash to `free()` with a Scudo
"Pointer tag ... was truncated" abort.

### `scripts/patch-opentui-loader.py`

The asset loader maps `process.platform` to a Node triple. Termux reports
`android`, which has no table entry. The patch maps it to the
`linux-arm64-musl` slot — where this build installs the bionic library — in both
`getCurrentNodeAssetTarget()` and `resolveNativeLibraryPath()`.

### `scripts/remap-binary-prefix.py`

Replaces the absolute GitHub Actions workspace path embedded in the `.so` with
`/usr/src`, without changing file length. It runs after `zig build` and before
the guard check.

### `scripts/opentui/check-ffi-guard.py`

Scans the unstripped `.so` for compiled guard patterns: a `#0x7fffffff` clamp
and a saturating add with `csel ..., vs`. It has to run before `llvm-strip`,
which removes the local symbols it reads. This is the gate that replaced the
old transplant-era guard harness.

## Native libraries built outside Bun

- `scripts/opentui/tlsdesc-shim.c` — the C shim described above.
- `scripts/ci/build-rust-pty-android.sh` — cargo cross-build of bun-pty's
  `librust_pty_arm64.so` against the NDK.
- `@parcel/watcher`'s Android module — installed as a file asset by the bundle
  build.

## Build and release shape

The workflow resolves the lock, fetches the two pinned sources, installs the
hash-verified Zig, applies the patches above, builds OpenTUI with the NDK
sysroot and a `--libc` file, runs the guard gate, strips one shared library,
then calls `scripts/ci/build-opencode-bundle.sh`. That script installs the
stripped library into every `@opentui/core-linux-*` slot so Bun emits one
hashed asset, copies in the PTY and watcher natives, and stages the bundle.

`scripts/ci/package-release-bundle.sh` builds the deb and tarball;
`.github/workflows/publish-native-android.yml` verifies, signs and publishes
them on a tag push. See [`../apt-repository.md`](../apt-repository.md) for the
signed flat APT source.

Build checks that must hold: the `@TERMUX_PREFIX@` placeholder survives, the
FFI marker survives minification, the guard gate passed on the unstripped
library, and the first five curated highlights are present in the emitted JS.
