# PROJECT KNOWLEDGE BASE

## ACTIVE NATIVE V2 WORK (2026-11-27)

- Released: `2.3.2` is the newest published bundle (tag `v2.3.2`, merged into `native-android` as `583151d`). Pins live in `supply-chain-lock.json`; `scripts/ocver.py` is the only reader, and `current`/`package_revision` drive CI, publishing and `install.sh`.
- In flight: branch `feat/2.4.2`, lock `current: 2.4.2` (commit `fc31a48`), `package_revision: 1`, OpenTUI `0.9.9`, Zig `0.17.1`, `bun_version 1.4.4` (CI bundling only; the deb depends on `bun (>= 1.4.4)` and never pins it).
- `2.4.1` never shipped: its build (Actions run 45446416586) failed at the OpenTUI step because 0.9.4 added a `bundle-libcxx` step that is not wired to the `--libc` file (`zig build-lib`: `unable to provide libc for target "aarch64-linux.5.10...7.2-android.28"`). The lock therefore skips it, and `.release/v2.4.2.md` covers `2.3.2 → 2.4.2` in one range.
- `bundle-libcxx` fix: `scripts/patch-opentui-android.py` skips OpenTUI's static archive on Android. That archive spawns a nested `zig build-lib` which never sees this build's bionic `--libc` file, and Zig has no bundled bionic libc. The bundle ships only the shared `libopentui.so`. Verified against the pinned 0.9.9 tree with Zig `0.17.1` (patch idempotent, `zig fmt --check` clean, build.zig compiles); no full CI build has run yet. Zig stays `0.17.1`; 0.9.9's `build.zig.zon` requires exactly that.
- The bundle is `$PREFIX/lib/opencode/` plus a `$PREFIX/bin/opencode` launcher that execs `bun`; `bun`, `libc++` and `ripgrep` are dependencies instead of embedded. Build with `scripts/ci/build-opencode-bundle.sh`, package with `scripts/ci/package-release-bundle.sh`. Actions call the scripts directly; there is no top-level wrapper.
- Release policy: pushing the tag is the only way to publish, and `publish-native-android.yml` runs the build workflow as its first job (`uses: ./.github/workflows/build-native-android.yml`), so the released files are built by that run. There is no candidate lookup and no provenance step: test the published release, and if it is broken bump `package_revision`, tag `v<version>-<revision>` (`v2.2.7-2`) and let the Debian version rise with it. `--target` must be `$GITHUB_SHA`; a release created for another commit is refused with `HTTP 403`.
- Android bionic tags heap pointers in the top byte; OpenTUI's `toSafeNumberPointer()` rejects them, so `scripts/patch-opentui-ffi.py` passes the tagged BigInt straight to Bun's FFI (masking the tag makes Scudo abort at `free()` with "Pointer tag … was truncated"). It must run before `Bun.build` (`bytecode:true` makes binary-level JS edits dead); CI greps the built ELF for the `BigInt.asUintN` marker.
- Zig `0.17.1` needs every field in the `--libc` file (`cc_dir` is mandatory for linux/Android) and its `translate-c` also searches the host `/usr/include`, which bionic's `#include_next <limits.h>` then follows into glibc. `scripts/patch-opentui-android.py` injects an empty `src/bionic-include-next/limits.h` to stop that inside the sysroot.
- Build guide: `docs/guides/native-v2-build.md`. Release builds run in GitHub Actions for reproducibility. On-device local builds are allowed; Termux already is Bionic so no NDK. Needs Termux `python3`, `npm`, `clang` (`zig` only to rebuild OpenTUI) and network.
- Scope: pacman packaging, `docs/history/`, the v1 wrapper/standalone packaging, the transplant comparison pipeline, the system-skills hook runner, `.omo/` and the translated READMEs were removed in the 2026-11 cleanup.
- Pin current native workflow actions to immutable commit SHAs, with the version in a comment. Use v6 where available.

**Generated:** 2026-11-27 **Branch:** feat/2.4.2

## OVERVIEW
Termux-first OpenCode build/packaging workspace. Since 2.2.7 the mainline is a runtime bundle under `$PREFIX/lib/opencode/` executed by Termux's `bun`, built by `scripts/ci/build-opencode-bundle.sh` and shipped as one `opencode` deb. The older single-ELF line (transplant revival, `opencode-wrapper`, `opencode-wrapper-standalone`) stays on disk for comparison builds only. Releases are built and published by GitHub Actions on tag push; see `docs/guides/native-v2-build.md`.

## STRUCTURE
```text
opencode-termux/
├── scripts/                    # CI entrypoints, transforms, lock reader, plugin CLIs
├── packing/                    # launcher template
├── docs/                       # guides/ (how-to), reference/ (internals), ops/ (runbooks)
├── artifacts/                  # generated runtime/staging outputs (disposable)
└── .github/workflows/          # CI handoff workflows
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build orchestration | `scripts/ci/*.sh` | Actions call the scripts directly; no top-level wrapper |
| Runtime bundle (2.2.7+) | `scripts/ci/build-opencode-bundle.sh`, `scripts/patch-opencode-bundle.py`, `scripts/patch-opentui-loader.py` | lock-driven bundle + bionic natives; build.ts gets an `android` bundle target |
| Bundle installer bits | `packing/launcher/opencode`, `scripts/materialize-bundle.sh`, `install.sh` | launcher template, `@TERMUX_PREFIX@` substitution, curl install path |
| Release notes | `.release/v<version>.md`, `.release/v<version>-highlights.md` | body notes and the embedded TUI banner; publish reads them by lock version |
| Release packaging | `scripts/ci/package-release-bundle.sh`, `.github/workflows/build-native-android.yml` | packages the runtime bundle in CI; takes `REVISION` from the lock |
| Signed APT source | `scripts/ci/write-flat-apt-release.py`, `scripts/ci/sign-apt-index.sh`, `setup-apt.sh`, `apt/opencode-termux.gpg` | CI indexes and signs Release; setup installs the scoped public key and source |
| Plugin lifecycle | `scripts/plugin-manager.sh`, `scripts/plugin-selfcheck.sh`, `docs/guides/plugin-management.md` | local file plugin path + snapshot rollback model |
| Pinned versions | `supply-chain-lock.json`, `scripts/ocver.py` | single source of truth; `current` drives CI/publish/install |
| Bundle source patches | `scripts/patch-opencode-source.py`, `scripts/patch-opentui-ffi.py`, `scripts/patch-fff-android.py` | edits applied to the pinned source and installed packages before the host Bun bundles the graph |
| OpenTUI Android build | `scripts/patch-opentui-android.py`, `scripts/opentui/tlsdesc-shim.c` | build.zig hooks + the TLSDESC shim the workflow compiles |
| Guard verification | `scripts/transplant/swap_tui.py` | `has_ffi_guard()` is the gate the workflow runs on the unstripped .so |

## CODE MAP
| Symbol | Type | Location | Refs | Role |
|---|---|---|---:|---|
| `build_plugin` | shell function | `scripts/plugin-manager.sh` | medium | plugin build pipeline (bun/npm + fallback) |
| `cmd_install` / `cmd_update` / `cmd_rollback` | shell functions | `scripts/plugin-manager.sh` | high | plugin lifecycle commands |

## CONVENTIONS
- Shell scripts use strict mode (`set -euo pipefail`) and fail-fast checks for required binaries/files.
- Build scripts read versions from `supply-chain-lock.json`; never hardcode them.
- The launcher template lives at `packing/launcher/opencode`; the deb is assembled by `scripts/ci/package-release-bundle.sh`.

## ANTI-PATTERNS (THIS PROJECT)
- Do not use musl/proot as official Termux final runtime path.
- Do not add a 32-bit (armv7/arm32) target: 32-bit Bun builds fail and were removed.
- Do not edit generated outputs (`artifacts/`, versioned `.deb` / `.tar.gz`).
- Do not run staging/packaging scripts against shared or wrong prefixes: several flows use destructive `rm -rf` cleanup.

## UNIQUE STYLES
- Plugin management is Termux-biased toward local `file://.../index.js` registration instead of bare plugin name mode.

## COMMANDS
```bash
# Runtime bundle, then the release artefacts (NDK + llvm-strip)
VER="$(python3 scripts/ocver.py current)"
REV="$(python3 scripts/ocver.py revision)"
bash scripts/ci/build-opencode-bundle.sh
bash scripts/ci/package-release-bundle.sh "artifacts/bundle/$VER" "$VER" artifacts/release "$REV"

# Validation
./scripts/plugin-selfcheck.sh
./tests/run.sh

# What the lock says is current
python3 scripts/ocver.py current

# Publish: push the tag from the lock; CI builds and publishes in one run
git push origin "$(python3 scripts/ocver.py tag)"
```

## NOTES
- `packing/` holds only the launcher template; package outputs go to `artifacts/`.
- When adding new workflow-critical scripts, update both `docs/README.md` navigation and this root map.
