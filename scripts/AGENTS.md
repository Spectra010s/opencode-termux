# SCRIPTS KNOWLEDGE BASE

## OVERVIEW
`scripts/` holds the release entrypoints, source transforms, the lock reader,
native helpers and the guard gate. Actions call these scripts directly; there
is no top-level wrapper.

## STRUCTURE
```text
scripts/
├── ci/                     # release entrypoints
├── opentui/                # tlsdesc shim + FFI guard check
├── patch-*.py              # source and native transforms
├── ocver.py                # only reader of supply-chain-lock.json
├── gen-packages-index.py   # writes Packages.gz
├── remap-binary-prefix.py  # rewrites build path in the .so
└── materialize-bundle.sh   # launcher substitution
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build the runtime bundle | `ci/build-opencode-bundle.sh` | patches source, installs bionic natives, bundles with host Bun |
| Build bun-pty | `ci/build-rust-pty-android.sh` | cargo cross-build against the NDK |
| Package the release | `ci/package-release-bundle.sh` | deb + tarball from `artifacts/bundle/<ver>` |
| APT index | `ci/write-flat-apt-release.py`, `ci/sign-apt-index.sh`, `gen-packages-index.py` | `Packages`, `Release`, `InRelease` |
| Launcher substitution | `materialize-bundle.sh` | `__OPENCODE_VERSION__` in the launcher |
| Pinned versions | `ocver.py` | reads the root `supply-chain-lock.json` |
| Source patches | `patch-opencode-source.py`, `patch-opencode-bundle.py` | Android bundle target, bun dependency, watcher/PTY |
| Native patches | `patch-opentui-android.py`, `patch-opentui-ffi.py`, `patch-opentui-loader.py`, `patch-fff-android.py` | bionic hooks, pointer tags, asset slots |
| Path remap | `remap-binary-prefix.py` | replaces workspace path without changing file size |
| Guard gate | `opentui/check-ffi-guard.py` | scans unstripped `.so` before strip |

## CONVENTIONS
- Strict shell mode; explicit `command -v` checks.
- Versions come from the lock; never hardcode them.
- Scripts run from the repo root, because CI calls them that way.
- Patch transforms must be idempotent and run before `Bun.build`.

## ANTI-PATTERNS
- Do not assume CI helper outputs are published artifacts; the tag run publishes.
- Do not add a build path that skips the guard scan on the unstripped `.so`.
- Do not mask bionic pointer tags before they reach Bun's FFI.
