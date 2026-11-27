# PROJECT KNOWLEDGE BASE

## ACTIVE NATIVE V2 WORK (2026-11-27)

- Released: `2.3.2` is the newest published bundle (tag `v2.3.2`, merged into `native-android` as `583151d`). Pins live in `tools/supply-chain-lock.json`; `tools/ocver.py` is the only reader, and `current`/`package_revision` drive CI, publishing and `install.sh`.
- In flight: branch `feat/2.4.2`, lock `current: 2.4.2` (commit `fc31a48`), `package_revision: 1`, OpenTUI `0.9.9`, Zig `0.17.1`, `bun_version 1.4.4` (CI bundling only; the deb depends on `bun (>= 1.4.4)` and never pins it).
- `2.4.1` never shipped: its build (Actions run 45446416586) failed at the OpenTUI step because 0.9.4 added a `bundle-libcxx` step that is not wired to the `--libc` file (`zig build-lib`: `unable to provide libc for target "aarch64-linux.5.10...7.2-android.28"`). The lock therefore skips it, and `.release/v2.4.2.md` covers `2.3.2 → 2.4.2` in one range.
- Open build gap: OpenTUI `0.9.9` still runs `bundle-libcxx`, so `tools/patch-opentui-android.py` must hand that step the same bionic `--libc` file before the build goes green. Zig stays `0.17.1`; 0.9.9's `build.zig.zon` requires exactly that.
- The bundle is `$PREFIX/lib/opencode/` plus a `$PREFIX/bin/opencode` launcher that execs `bun`; `bun`, `libc++` and `ripgrep` are dependencies instead of embedded. Build with `scripts/ci/build-opencode-bundle.sh`, package with `scripts/ci/package-release-bundle.sh`. CI never calls `make`; the `Makefile` is a local mirror (`bundle`, `deb`, `status`, `selfcheck`, `test`).
- Release policy: pushing the tag is the only way to publish, and `publish-native-android.yml` runs the build workflow as its first job (`uses: ./.github/workflows/build-native-android.yml`), so the released files are built by that run. There is no candidate lookup and no provenance step: test the published release, and if it is broken bump `package_revision`, tag `v<version>-<revision>` (`v2.2.7-2`) and let the Debian version rise with it. `--target` must be `$GITHUB_SHA`; a release created for another commit is refused with `HTTP 403`.
- Android bionic tags heap pointers in the top byte; OpenTUI's `toSafeNumberPointer()` rejects them, so `tools/patch-opentui-ffi.py` passes the tagged BigInt straight to Bun's FFI (masking the tag makes Scudo abort at `free()` with "Pointer tag … was truncated"). It must run before `Bun.build` (`bytecode:true` makes binary-level JS edits dead); CI greps the built ELF for the `BigInt.asUintN` marker.
- Zig `0.17.1` needs every field in the `--libc` file (`cc_dir` is mandatory for linux/Android) and its `translate-c` also searches the host `/usr/include`, which bionic's `#include_next <limits.h>` then follows into glibc. `tools/patch-opentui-android.py` injects an empty `src/bionic-include-next/limits.h` to stop that inside the sysroot.
- Build guide: `docs/guides/native-v2-build.md`; transplant details: `docs/reference/transplant.md`. Release builds run in GitHub Actions for reproducibility. On-device local builds are allowed; Termux already is Bionic so no NDK. Needs Termux `python3`, `npm`, `clang`, `make` (`zig` only to rebuild OpenTUI) and network.
- Scope: pacman packaging, `docs/history/`, and the v1 wrapper/compressed/standalone Makefile surface were removed in the 2026-11 cleanup; `opencode-wrapper` scripts remain on disk as appendix only. `README.{es,ja,zh,zht}.md` are still v1-era text with only their build block updated.
- Pin current native workflow actions to immutable commit SHAs, with the version in a comment. Use v6 where available.

**Generated:** 2026-11-27 **Branch:** feat/2.4.2

## OVERVIEW
Termux-first OpenCode build/packaging workspace. Since 2.2.7 the mainline is a runtime bundle under `$PREFIX/lib/opencode/` executed by Termux's `bun`, built by `scripts/ci/build-opencode-bundle.sh` and shipped as one `opencode` deb. The older single-ELF line (transplant revival, `opencode-wrapper`, `opencode-wrapper-standalone`) stays on disk for comparison builds only. Releases are built and published by GitHub Actions on tag push; see `docs/guides/native-v2-build.md`.

## STRUCTURE
```text
opencode-termux/
├── Makefile                    # top-level orchestration (bundle/deb/status/selfcheck)
├── scripts/                    # staging, packaging, hook runners, CI helper scripts
├── tools/                      # operator-facing CLIs (plugin lifecycle, patches, matrix)
├── packing/                  # package templates + manifests (mixed with generated outputs)
├── docs/                       # guides/ (how-to), reference/ (internals), ops/ (runbooks)
├── artifacts/                  # generated runtime/staging outputs (disposable)
└── .github/workflows/          # CI handoff workflows
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build orchestration | `Makefile`, `tools/make-opencode` | `make` is source of truth; wrapper maps CLI flags to make vars |
| Runtime bundle (2.2.7+) | `scripts/ci/build-opencode-bundle.sh`, `tools/patch-opencode-bundle.py`, `tools/patch-opentui-loader.py` | lock-driven bundle + bionic natives; build.ts gets an `android` bundle target |
| Bundle installer bits | `packing/launcher/opencode`, `scripts/materialize-bundle.sh`, `install.sh` | launcher template, `@TERMUX_PREFIX@` substitution, curl install path |
| Release notes | `.release/v<version>.md`, `.release/v<version>-highlights.md` | body notes and the embedded TUI banner; publish reads them by lock version |
| Prepare runtime artifact | `tools/produce-local.sh` | resolves version, wraps runtime, cleans stale generated dirs |
| Stage install tree | `scripts/build.sh`, `scripts/common.sh` | writes staged prefix + build metadata |
| Build DEB package (wrapper appendix) | `scripts/package/package_deb.sh`, `packing/deb/DEBIAN/control` | builds the `opencode-wrapper` deb; postinst hook calls system-skill runner |
| Legacy single-ELF deb | `scripts/package/package_deb_native.sh` | pre-2.2.7 `opencode-native` provider; the bundle deb supersedes it |
| Release packaging | `scripts/ci/package-release-bundle.sh`, `.github/workflows/build-native-android.yml` | packages the runtime bundle in CI; takes `REVISION` from the lock |
| Signed APT source | `scripts/ci/write-flat-apt-release.py`, `scripts/ci/sign-apt-index.sh`, `setup-apt.sh`, `apt/opencode-termux.gpg` | CI indexes and signs Release; setup installs the scoped public key and source |
| Standalone rollback packaging | `scripts/package/package_deb_standalone.sh`, `packing/deb-standalone` | `opencode-wrapper-standalone` frozen rollback package (coexists with `opencode`); stage via `STANDALONE=1 ./scripts/build.sh` |
| System-skill hook behavior | `scripts/hooks/run-system-skills.sh`, `packing/manifests/system-skills/*.json` | strict/network flags default to safe mode |
| Plugin lifecycle | `tools/plugin-manager.sh`, `tools/plugin-selfcheck.sh`, `docs/guides/plugin-management.md` | local file plugin path + snapshot rollback model |
| Upgrade/downgrade simulation | `tools/upgrade-matrix.sh`, `docs/ops/execution-checklist.md` | machine2 lifecycle validation with cached deb artifacts |
| Transplant 管线 | `tools/transplant/transplant.py` | 原生 android Bun 拼接 + ELF 复活手术（C1 已复活，见 `docs/reference/transplant.md`） |
| Pinned versions | `tools/supply-chain-lock.json`, `tools/ocver.py` | single source of truth; `current` drives CI/publish/install |
| Bundle source patches | `tools/patch-opencode-source.py`, `tools/patch-opentui-ffi.py`, `tools/patch-fff-android.py` | edits applied to the pinned source and installed packages before the host Bun bundles the graph |
| OpenTUI Android build | `tools/patch-opentui-android.py`, `patches/opentui/tlsdesc-shim.c`, `tools/transplant/build-libopentui.sh` | version-agnostic bionic hooks + guard verify |

## CODE MAP
| Symbol | Type | Location | Refs | Role |
|---|---|---|---:|---|
| `bundle`, `deb`, `status`, `selfcheck`, `test` | Make targets | `Makefile` | high | local mirror of the CI steps |
| `build_plugin` | shell function | `tools/plugin-manager.sh` | medium | plugin build pipeline (bun/npm + fallback) |
| `cmd_install` / `cmd_update` / `cmd_rollback` | shell functions | `tools/plugin-manager.sh` | high | plugin lifecycle commands |
| `run-system-skills.sh` entry flow | hook runner | `scripts/hooks/run-system-skills.sh` | high | post-install/post-upgrade hook orchestration |
| `produce-local.sh` main flow | script entrypoint | `tools/produce-local.sh` | medium | runtime acquisition + wrapper + cleanup |
| `upgrade-matrix.sh` main flow | script entrypoint | `tools/upgrade-matrix.sh` | medium | remote install/upgrade/downgrade simulation |

## CONVENTIONS
- Shell scripts use strict mode (`set -euo pipefail`) and fail-fast checks for required binaries/files.
- Runtime/package scripts rely on uppercase env knobs (`VER`, `VERS`, `PKG`, `ODIR`, `MIX`, `STAGED_PREFIX`, `PACKAGER_NAME`).
- Hook execution is explicit and safe-by-default (`OPENCODE_HOOK_STRICT=0`, `OPENCODE_HOOK_ENABLE_NETWORK=0`) in package lifecycle paths.
- Packaging sources live under `packing/*` templates; versioned package files are generated artifacts.

## ANTI-PATTERNS (THIS PROJECT)
- Do not use musl/proot as official Termux final runtime path.
- Do not add a 32-bit (armv7/arm32) target: 32-bit Bun builds fail and were removed.
- Do not edit generated outputs (`artifacts/`, `packing/dpkg/work/`, versioned `.deb` / `.tar.gz`).
- Do not run staging/packaging scripts against shared or wrong prefixes: several flows use destructive `rm -rf` cleanup.

## UNIQUE STYLES
- Packaging and hook flows are manifest-driven (`packing/manifests/system-skills/*.json`) with idempotency + registry updates.
- Plugin management is Termux-biased toward local `file://.../index.js` registration instead of bare plugin name mode.

## COMMANDS
```bash
# Runtime bundle, then the release artefacts (NDK + llvm-strip)
make bundle
make deb

# Validation
make selfcheck
make test

# What the lock says is current
make status

# Publish: push the tag from the lock; CI builds and publishes in one run
git push origin "$(python3 tools/ocver.py tag)"
```

## NOTES
- `packing/` (default outputs) and `packing/` (templates/manifests) are different; keep them conceptually separate.
- When adding new workflow-critical scripts, update both `docs/README.md` navigation and this root map.
