# SCRIPTS KNOWLEDGE BASE

## OVERVIEW
`scripts/` holds the release entrypoints. Everything release-facing runs from
`scripts/ci/`; Actions call these scripts directly, with no top-level wrapper.

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build the runtime bundle | `ci/build-opencode-bundle.sh` | patches the pinned source, builds the bionic OpenTUI .so, bundles with the host Bun |
| Build bun-pty for bionic | `ci/build-rust-pty-android.sh` | cargo cross-build against the NDK |
| Package the release | `ci/package-release-bundle.sh` | deb + tarball from `artifacts/bundle/<ver>` |
| Signed APT index | `ci/write-flat-apt-release.py`, `ci/sign-apt-index.sh` | `Release`/`InRelease` for the flat repo |
| Launcher substitution | `materialize-bundle.sh` | writes `@TERMUX_PREFIX@` into `packing/launcher/opencode` |

## CONVENTIONS
- Strict shell mode (`set -euo pipefail`) and explicit `command -v` checks.
- Versions come from `supply-chain-lock.json`; never hardcode them.
- Scripts must run from the repo root, because CI calls them that way.

## ANTI-PATTERNS (SCRIPTS)
- Do not assume CI helper outputs are release artifacts; the tag run publishes.
- Do not add a build path that skips the FFI guard scan on the unstripped .so.
