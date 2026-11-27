# Build and maintenance notes

These are internal notes: how this project builds, packages and publishes
OpenCode for Termux, and what broke on the way. They are not user
documentation. Users install from the [root README](../README.md), and OpenCode
itself is documented upstream at [opencode.ai/docs](https://opencode.ai/docs).

## Pipeline

- [`guides/native-v2-build.md`](guides/native-v2-build.md) — pinned inputs, the bundle build, the `source` fallback, and the on-device path.
- [`ops/apt-repository.md`](ops/apt-repository.md) — what a release publishes, how the index is signed, and how to debug a broken source.
- [`reference/transplant.md`](reference/transplant.md) — 中文: the revive/splice surgery the older compiled line used.
- [`reference/tui-common-fix.md`](reference/tui-common-fix.md) — 中文: TUI crash analysis (pointer tags, FFI shim, renderer startup).

## Packaging and runtime

- [`guides/plugin-management.md`](guides/plugin-management.md) — plugin install, self-update, snapshot rollback.
- [`reference/system-skills-hook-architecture.md`](reference/system-skills-hook-architecture.md) — package-mode system skills and the hook framework.
- [`reference/plugin-packaging-design.md`](reference/plugin-packaging-design.md) — package-manager-driven plugin model.
- [`reference/performance-optimization.md`](reference/performance-optimization.md) — 中文: performance roadmap.
- [`reference/bundle-list.txt`](reference/bundle-list.txt) — Bun module bundle inventory.
- [`reference/measurements/native-baseline-1.3.13.json`](reference/measurements/native-baseline-1.3.13.json) — recorded baseline measurements.

## Operations

- [`ops/execution-checklist.md`](ops/execution-checklist.md) — end-to-end install/test validation before a tag.
- [`ops/skills-index.md`](ops/skills-index.md) — index of Termux skills and quick fixes.

## Ground rules

- The release artifact is a bundle plus a launcher on Termux's `bun`; nothing glibc, nothing proot, nothing musl.
- Build against the versions in `tools/supply-chain-lock.json`. `tools/ocver.py` is the only reader; do not repeat version literals.
- Verify the FFI guard on the unstripped OpenTUI library, then check the marker survives in the bundle: `bytecode: true` makes binary-level JS edits dead.
- aarch64 only. No 32-bit target exists, and `TERMUX_PKG_EXCLUDED_ARCHES` style arch games are out of scope.
- Publish from CI only: the tag run builds, signs and releases in one go. A locally built artifact is never a release.

## Maintaining these docs

- When behaviour and docs diverge, fix the doc in the same change as the code.
- Replace stale sections instead of appending contradictory notes.
- If you move or add a workflow-critical document, update this index and the root `AGENTS.md` map.
