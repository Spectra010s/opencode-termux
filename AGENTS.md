# PROJECT KNOWLEDGE BASE

## STATE (2026-11-27)

- Published: `2.3.2` (tag `v2.3.2`) on `native-android`. Pins live in `supply-chain-lock.json`; `scripts/ocver.py` is the only reader.
- In flight: `feat/2.4.2`, lock `current: 2.4.2`, `package_revision: 1`, OpenTUI `0.9.9`, Zig `0.17.1`. The lock's Bun is the host build tool; the deb declares `Depends: bun` and never pins a runtime version.
- `2.4.1` never shipped: Actions run `45446416586` failed at OpenTUI's `bundle-libcxx`. Release notes for `2.4.2` cover `2.3.2 -> 2.4.2` in one range.
- CI: build run `45929219858` on `86ca387` finished green. No release tag has been pushed. Check `git status -sb` before pushing; local commits may be ahead of the remote branch.
- The product is `$PREFIX/lib/opencode/` plus a `$PREFIX/bin/opencode` launcher that execs Termux's `bun`. Actions call `scripts/ci/*` directly; there is no Makefile or top-level wrapper.
- Publishing is tag-driven. `publish-native-android.yml` runs the build workflow as its first job, verifies the candidate, signs the APT index and creates the release with `--target $GITHUB_SHA`. A broken release is fixed by bumping `package_revision` and tagging `v<version>-<revision>`.
- Critical patches: tagged-pointer FFI passthrough, bionic OpenTUI hooks, static-archive skip, Android loader slot, PTY/watcher/fff natives, and the guard scan before strip. The reasoning is in `docs/native-v2-build.md`.
- Pin workflow actions to immutable commit SHAs with the version in a comment; use v6 where available.

## OVERVIEW
Termux-first OpenCode build and packaging workspace. The pinned upstream source is patched, the native libraries are cross-built for bionic aarch64, and the result is bundled as JavaScript run by Termux's `bun`.

## STRUCTURE
```text
opencode-termux/
├── scripts/                    # CI entrypoints, transforms, lock reader, guard check
├── packing/                    # launcher template
├── docs/                       # flat: index, build guide, APT runbook
├── apt/                        # public signing key
├── assets/                     # screenshots
├── tests/                      # bats unit tests
├── install.sh, setup-apt.sh    # device install paths
├── supply-chain-lock.json      # single source of truth for pins
└── .github/workflows/          # build, publish, sign, tests
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build orchestration | `scripts/ci/*.sh`, `.github/workflows/build-native-android.yml` | Actions call scripts directly |
| Runtime bundle | `scripts/ci/build-opencode-bundle.sh`, `scripts/patch-opencode-*.py` | Android bundle target, bionic natives |
| OpenTUI build | `scripts/patch-opentui-android.py`, `scripts/opentui/` | build.zig hooks, shim, guard gate |
| Packaging | `scripts/ci/package-release-bundle.sh`, `scripts/materialize-bundle.sh` | deb + tarball, launcher substitution |
| Signed APT source | `scripts/ci/write-flat-apt-release.py`, `scripts/ci/sign-apt-index.sh`, `setup-apt.sh`, `apt/opencode-termux.gpg` | flat repo on GitHub Releases |
| Pinned versions | `supply-chain-lock.json`, `scripts/ocver.py` | no hardcoded versions |
| Release notes | `.release/v<version>.md`, `.release/v<version>-highlights.md` | first five bullets become the TUI banner |
| Build and patch rationale | `docs/native-v2-build.md` | what is patched and why |
| APT runbook | `docs/apt-repository.md` | repo setup, key, failure modes |

## CONVENTIONS
- Shell scripts use `set -euo pipefail` and fail fast on missing binaries or files.
- Build scripts read versions from `supply-chain-lock.json`; never hardcode them.
- The launcher template lives at `packing/launcher/opencode`; the deb is assembled by `scripts/ci/package-release-bundle.sh`.
- Patch scripts must be idempotent, and must replace source before `Bun.build`.

## ANTI-PATTERNS
- Do not use musl/proot as the Termux runtime path.
- Do not add 32-bit targets; 32-bit Bun builds fail.
- Do not edit generated outputs (`artifacts/`, versioned `.deb` / `.tar.gz`).
- Do not run staging scripts against shared or wrong prefixes; cleanup uses `rm -rf`.

## COMMANDS
```bash
VER="$(python3 scripts/ocver.py current)"
REV="$(python3 scripts/ocver.py revision)"
bash scripts/ci/build-opencode-bundle.sh
bash scripts/ci/package-release-bundle.sh "artifacts/bundle/$VER" "$VER" artifacts/release "$REV"

./tests/run.sh
python3 scripts/ocver.py current
git push origin "$(python3 scripts/ocver.py tag)"
```

## NOTES
- Update this map and `docs/README.md` when workflow-critical files move.
