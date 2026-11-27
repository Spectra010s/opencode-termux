# Build and maintenance notes

These are internal notes: how this project builds, packages and publishes
OpenCode for Termux, and what broke on the way. They are not user
documentation. Users install from the [root README](../README.md), and OpenCode
itself is documented upstream at [opencode.ai/docs](https://opencode.ai/docs).

## Pipeline

- [`guides/native-v2-build.md`](guides/native-v2-build.md) — pinned inputs, the bundle build and the OpenTUI step.
- [`ops/apt-repository.md`](ops/apt-repository.md) — what a release publishes, how the index is signed, and how to debug a broken source.

## Packaging and runtime

- [`guides/plugin-management.md`](guides/plugin-management.md) — plugin install, self-update, snapshot rollback.
- [`reference/plugin-packaging-design.md`](reference/plugin-packaging-design.md) — package-manager-driven plugin model.

## Operations

- [`ops/execution-checklist.md`](ops/execution-checklist.md) — end-to-end install/test validation before a tag.

## Ground rules

- The release artifact is a bundle plus a launcher on Termux's `bun`; nothing glibc, nothing proot, nothing musl.
- Build against the versions in `supply-chain-lock.json`. `scripts/ocver.py` is the only reader; do not repeat version literals.
- Verify the FFI guard on the unstripped OpenTUI library, then check the marker survives in the bundle: `bytecode: true` makes binary-level JS edits dead.
- aarch64 only. No 32-bit target exists, and `TERMUX_PKG_EXCLUDED_ARCHES` style arch games are out of scope.
- Publish from CI only: the tag run builds, signs and releases in one go. A locally built artifact is never a release.

## Maintaining these docs

- When behaviour and docs diverge, fix the doc in the same change as the code.
- Replace stale sections instead of appending contradictory notes.
- If you move or add a workflow-critical document, update this index and the root `AGENTS.md` map.
