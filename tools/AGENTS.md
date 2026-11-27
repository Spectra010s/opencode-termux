# TOOLS KNOWLEDGE BASE

## OVERVIEW
`tools/` holds the patch scripts the bundle build applies, the lock reader, and
the plugin lifecycle CLIs.

## WHERE TO LOOK
| Task | Location | Notes |
|---|---|---|
| Pinned versions | `ocver.py` | the only reader of `supply-chain-lock.json` |
| Source patching | `patch-opencode-source.py`, `patch-opencode-bundle.py` | edits applied to the pinned upstream tree before `Bun.build` |
| Native patching | `patch-opentui-ffi.py`, `patch-opentui-loader.py`, `patch-fff-android.py` | tagged-pointer passthrough, loader, FFI fixes |
| OpenTUI Android hooks | `patch-opentui-android.py` | build.zig bionic hooks, `--libc` fields, `limits.h` shadow |
| Guard gate | `transplant/swap_tui.py` | `has_ffi_guard()`; CI imports it directly |
| Bun base pin | `transplant/config/bun-bind.json` | cross-checked against the lock by the workflow |
| Plugin install/update/rollback | `plugin-manager.sh` | snapshot-first mutation model + state file |
| Environment diagnostics | `plugin-selfcheck.sh` | read-only JSON checks for config and plugins |
| APT index entries | `gen-packages-index.py` | writes `Packages.gz` for the flat repo |

## CONVENTIONS
- Keep patch scripts idempotent: CI applies them to a fresh checkout, but a
  local rerun must not double-apply.
- Patch the source before `Bun.build`; `bytecode: true` makes binary-level JS
  edits dead.
- Keep `plugin-selfcheck.sh` output machine-readable (JSON lines).

## ANTI-PATTERNS (TOOLS)
- Do not hardcode a version; read the lock.
- Do not mask bionic pointer tags before they reach Bun's FFI.
- Do not run the plugin manager against an unintended `$CFG_DIR`; it cleans up
  before rebuilding.

## COMMANDS
```bash
# plugin lifecycle
./tools/plugin-manager.sh install
./tools/plugin-manager.sh update
./tools/plugin-manager.sh rollback

# diagnostics
./tools/plugin-selfcheck.sh
```
