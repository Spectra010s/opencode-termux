# SCRIPTS KNOWLEDGE BASE

## OVERVIEW
`scripts/` holds the release entrypoints, the transforms applied to the pinned
source trees, the lock reader, the plugin lifecycle CLIs and the guard gate.
Actions call the scripts directly; there is no top-level wrapper.

## STRUCTURE
```text
scripts/
├── ci/                     # release entrypoints (bundle, natives, package, APT index)
├── opentui/                # tlsdesc shim + the FFI guard check
├── patch-*.py              # source and native transforms
├── ocver.py                # the only reader of supply-chain-lock.json
├── gen-packages-index.py   # writes Packages.gz for the flat repo
├── plugin-*.sh             # plugin lifecycle and diagnostics
└── materialize-bundle.sh   # @TERMUX_PREFIX@ substitution in the launcher
```

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Build the runtime bundle | `ci/build-opencode-bundle.sh` | patches the pinned source, builds the bionic OpenTUI .so, bundles with the host Bun |
| Build bun-pty for bionic | `ci/build-rust-pty-android.sh` | cargo cross-build against the NDK |
| Package the release | `ci/package-release-bundle.sh` | deb + tarball from `artifacts/bundle/<ver>` |
| Signed APT index | `ci/write-flat-apt-release.py`, `ci/sign-apt-index.sh`, `gen-packages-index.py` | `Packages.gz`, `Release`/`InRelease` for the flat repo |
| Launcher substitution | `materialize-bundle.sh` | writes `@TERMUX_PREFIX@` into `packing/launcher/opencode` |
| Pinned versions | `ocver.py` | the only reader of `supply-chain-lock.json` |
| Source patching | `patch-opencode-source.py`, `patch-opencode-bundle.py` | edits applied to the pinned upstream tree before `Bun.build` |
| Native patching | `patch-opentui-ffi.py`, `patch-opentui-loader.py`, `patch-fff-android.py` | tagged-pointer passthrough, loader, FFI fixes |
| OpenTUI Android hooks | `patch-opentui-android.py`, `opentui/tlsdesc-shim.c` | build.zig bionic hooks, `--libc` fields, `limits.h` shadow |
| Guard gate | `opentui/check-ffi-guard.py` | CLI the workflow runs on the unstripped .so |
| Plugin install/update/rollback | `plugin-manager.sh` | snapshot-first mutation model + state file |
| Environment diagnostics | `plugin-selfcheck.sh` | read-only JSON checks for config and plugins |

## CONVENTIONS
- Strict shell mode (`set -euo pipefail`) and explicit `command -v` checks.
- Versions come from `supply-chain-lock.json`; never hardcode them.
- Scripts run from the repo root, because CI calls them that way.
- Keep patch transforms idempotent: CI applies them to a fresh checkout, but a
  local rerun must not double-apply.
- Patch the source before `Bun.build`; `bytecode: true` makes binary-level JS
  edits dead.
- Keep `plugin-selfcheck.sh` output machine-readable (JSON lines).

## ANTI-PATTERNS (SCRIPTS)
- Do not assume CI helper outputs are release artifacts; the tag run publishes.
- Do not add a build path that skips the FFI guard scan on the unstripped .so.
- Do not hardcode a version; read the lock.
- Do not mask bionic pointer tags before they reach Bun's FFI.
- Do not run the plugin manager against an unintended `$CFG_DIR`; it cleans up
  before rebuilding.

## COMMANDS
```bash
# plugin lifecycle
./scripts/plugin-manager.sh install
./scripts/plugin-manager.sh update
./scripts/plugin-manager.sh rollback

# diagnostics
./scripts/plugin-selfcheck.sh
```
