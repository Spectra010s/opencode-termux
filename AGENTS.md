# PROJECT KNOWLEDGE BASE

## ACTIVE NATIVE V2 WORK (2026-10-31)

- Release candidate: OpenCode `2.2.6` on Android/Bionic Bun `1.4.4` with OpenTUI `0.8.1` (Zig `0.17.0`). Pins live in `tools/supply-chain-lock.json`; `tools/ocver.py` is the only reader, and `current` drives CI, publishing and `install.sh`.
- `2.2.5` is published and runs on-device (version, server, TUI). `2.2.6` is the current candidate and is not yet released.
- Publish only from a CI candidate artifact via `publish-native-android.yml` (it re-checks provenance and checksums); never upload a binary built on a device.
- Android bionic tags heap pointers in the top byte; OpenTUI's `toSafeNumberPointer()` rejects them, so `tools/patch-opentui-ffi.py` must run before `Bun.build` (`bytecode:true` makes binary-level JS edits dead).
- Build guide: `docs/guides/native-v2-build.md`; transplant details: `docs/reference/transplant.md`. Release builds run in GitHub Actions for reproducibility. On-device local builds are allowed; Termux already is Bionic so no NDK. Needs Termux `python3`, `npm`, `clang`, `make` (`zig` only to rebuild OpenTUI) and network.
- History: native v2 `2.0.26`/`2.0.28` on Bun `1.4.0`/`1.4.2` were the previous user-facing line. The Bun 1.4.0 candidate from Actions run 38142306988 passed on-device TUI, API, session and real-prompt checks.
- Pin current native workflow actions to immutable commit SHAs, with the version in a comment. Use v6 where available.

**Generated:** 2026-11-11 **Branch:** native-android

## OVERVIEW
Termux-first OpenCode build/packaging workspace. Stable mainline since 27/28 is the native bionic line: a single zero-glibc Android ELF produced by the transplant revive pipeline (`tools/transplant/`, `make transplant`; see `docs/reference/transplant.md`). The wrapper line is renamed `opencode-wrapper` and demoted to appendix maintenance (local build path `tools/produce-local.sh` + `scripts/*`); `opencode-wrapper-standalone` is the frozen single-version rollback package that can coexist with `opencode`. `opencode` and `opencode-wrapper` remain mutually exclusive. GitHub Actions workflows are diagnostic/handoff, not final runtime release.

## STRUCTURE
```text
opencode-termux/
├── Makefile                    # top-level orchestration (all/batch/selfcheck/matrix)
├── scripts/                    # staging, packaging, hook runners, CI helper scripts
├── tools/                      # operator-facing CLIs (make wrapper, plugin lifecycle, matrix)
├── packing/                  # package templates + manifests (mixed with generated outputs)
├── docs/                       # guides/ (how-to), reference/ (internals), ops/ (runbooks), history/ (superseded)
├── artifacts/                  # generated runtime/staging outputs (disposable)
└── .github/workflows/          # CI handoff workflows
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build orchestration | `Makefile`, `tools/make-opencode` | `make` is source of truth; wrapper maps CLI flags to make vars |
| Prepare runtime artifact | `tools/produce-local.sh` | resolves version, wraps runtime, cleans stale generated dirs |
| Stage install tree | `scripts/build.sh`, `scripts/common.sh` | writes staged prefix + build metadata |
| Build DEB package (wrapper appendix) | `scripts/package/package_deb.sh`, `packing/deb/DEBIAN/control` | builds the `opencode-wrapper` deb; postinst hook calls system-skill runner |
| Build pacman package (wrapper appendix) | `scripts/package/package_pacman.sh`, `packing/pacman/PKGBUILD*` | builds the `opencode-wrapper` pacman package; dynamic pkgver/pkgrel rewrite + makepkg flow |
| Native provider packaging | `scripts/package/package_deb_native.sh`, `scripts/package/package_pacman_native.sh`, `packing/pacman/PKGBUILD.native` | `opencode-native` deb/pacman providers for the native bionic mainline (stable since 27/28; see docs/guides/dual-track-install.md) |
| Release APT candidate | `scripts/ci/package-release-deb.sh`, `.github/workflows/build-native-android.yml` | packages the Android binary in CI; publish workflow reuses the verified candidate |
| Signed APT source | `scripts/ci/write-flat-apt-release.py`, `scripts/ci/sign-apt-index.sh`, `setup-apt.sh`, `apt/opencode-termux.gpg` | CI indexes and signs Release; setup installs the scoped public key and source |
| Standalone rollback packaging | `scripts/package/package_deb_standalone.sh`, `scripts/package/package_pacman_standalone.sh`, `packing/pacman/PKGBUILD.standalone` | `opencode-wrapper-standalone` frozen rollback package (coexists with `opencode`); stage via `STANDALONE=1 ./scripts/build.sh` |
| System-skill hook behavior | `scripts/hooks/run-system-skills.sh`, `packing/manifests/system-skills/*.json` | strict/network flags default to safe mode |
| Plugin lifecycle | `tools/plugin-manager.sh`, `tools/plugin-selfcheck.sh`, `docs/guides/plugin-management.md` | local file plugin path + snapshot rollback model |
| Upgrade/downgrade simulation | `tools/upgrade-matrix.sh`, `docs/ops/execution-checklist.md` | machine2 lifecycle validation with cached deb artifacts |
| Transplant 管线 | `tools/transplant/transplant.py` | 原生 android Bun 拼接 + ELF 复活手术（C1 已复活，见 `docs/reference/transplant.md`） |
| Pinned versions | `tools/supply-chain-lock.json`, `tools/ocver.py` | single source of truth; `current` drives CI/publish/install |
| Source-build candidate | `scripts/ci/build-opencode-source.sh`, `tools/patch-opencode-source.py` | lock-driven host Bun compile onto the pinned Android Bun base |
| OpenTUI Android build | `tools/patch-opentui-android.py`, `patches/opentui/tlsdesc-shim.c`, `tools/transplant/build-libopentui.sh` | version-agnostic bionic hooks + guard verify |

## CODE MAP
| Symbol | Type | Location | Refs | Role |
|---|---|---|---:|---|
| `all`, `batch`, `selfcheck`, `matrix` | Make targets | `Makefile` | high | primary workflow control surface |
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
- Do not use musl/proot as official Termux final runtime path (`README.md`, `docs/history/local-production.md`).
- Do not add a 32-bit (armv7/arm32) target: 32-bit Bun builds fail and were removed.
- Do not edit generated outputs (`artifacts/`, `packing/dpkg/work/`, `packing/pacman/pkg/`, versioned `.deb` / `.pkg.tar.xz`).
- Do not run staging/packaging scripts against shared or wrong prefixes: several flows use destructive `rm -rf` cleanup.

## UNIQUE STYLES
- Packaging and hook flows are manifest-driven (`packing/manifests/system-skills/*.json`) with idempotency + registry updates.
- Plugin management is Termux-biased toward local `file://.../index.js` registration instead of bare plugin name mode.

## COMMANDS
```bash
# Runtime preparation (mainline local flow)
./tools/produce-local.sh 1.2.10

# Build/package via make
make all VER=1.2.10 PKG=both
make batch VERS='1.2.10 1.2.11' PKG=deb

# Validation
make selfcheck
make matrix VERS='1.2.9 1.2.10' TARGET_HOST=192.168.1.22 TARGET_USER=u0_a258

# Direct package scripts
./scripts/package/package_deb.sh
./scripts/package/package_pacman.sh
```

## NOTES
- `packing/` (default outputs) and `packing/` (templates/manifests) are different; keep them conceptually separate.
- When adding new workflow-critical scripts, update both `docs/README.md` navigation and this root map.
