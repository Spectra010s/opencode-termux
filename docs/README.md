# Build and maintenance notes

These are internal notes: how this project builds, packages and publishes
OpenCode for Termux, and what broke on the way. They are not user
documentation. Users install from the [root README](../README.md), and OpenCode
itself is documented upstream at [opencode.ai/docs](https://opencode.ai/docs).

`history/` is archaeology. Anything there describes a superseded line; do not
follow it.

## Pipeline

- [`guides/native-v2-build.md`](guides/native-v2-build.md) — pinned inputs, the bundle build, the `source` fallback, and the on-device path.
- [`ops/apt-repository.md`](ops/apt-repository.md) — what a release publishes, how the index is signed, and how to debug a broken source.
- [`reference/transplant.md`](reference/transplant.md) — 中文: the revive/splice surgery the older compiled line used.
- [`reference/tui-common-fix.md`](reference/tui-common-fix.md) — 中文: TUI crash analysis (pointer tags, FFI shim, renderer startup).
- [`reference/tui-reachability.md`](reference/tui-reachability.md) — 中文: TUI reachability matrix for the rc6-b2 build.
- [`reference/patch-coverage-audit.md`](reference/patch-coverage-audit.md) — 中文: patch coverage across eight layers and thirteen versions.

## Packaging and runtime

- [`guides/dual-track-install.md`](guides/dual-track-install.md) — package names and which family a device has installed.
- [`guides/make-maintainer.md`](guides/make-maintainer.md) — the Make surface: build, upload, cache, fleet push.
- [`guides/plugin-management.md`](guides/plugin-management.md) — plugin install, self-update, snapshot rollback.
- [`reference/system-skills-hook-architecture.md`](reference/system-skills-hook-architecture.md) — package-mode system skills and the hook framework.
- [`reference/plugin-packaging-design.md`](reference/plugin-packaging-design.md) — package-manager-driven plugin model.
- [`reference/arch-reference-mapping.md`](reference/arch-reference-mapping.md) — reusable pieces from the Arch plugin packaging approach.
- [`reference/compressed-line.md`](reference/compressed-line.md) — 中文: UPX launcher contract (wrapper appendix).
- [`reference/upx-v2-fix.md`](reference/upx-v2-fix.md) — 中文: UPX hypotheses and the verification sequence.
- [`reference/hook-design-proposal.md`](reference/hook-design-proposal.md) — 中文: install-time hook ownership.
- [`reference/performance-optimization.md`](reference/performance-optimization.md) — 中文: performance roadmap.
- [`reference/bundle-list.txt`](reference/bundle-list.txt) — Bun module bundle inventory.
- [`reference/measurements/native-baseline-1.3.13.json`](reference/measurements/native-baseline-1.3.13.json) — recorded baseline measurements.

## Operations

- [`ops/execution-checklist.md`](ops/execution-checklist.md) — end-to-end install/test validation before a tag.
- [`ops/skills-index.md`](ops/skills-index.md) — index of Termux skills and quick fixes.

## History

- [`history/00-scope-and-target.md`](history/00-scope-and-target.md), [`history/01-env-baseline-termux.md`](history/01-env-baseline-termux.md) — original scope and Termux baseline.
- [`history/11-opencode-build-plan.md`](history/11-opencode-build-plan.md), [`history/12-bun-executable-structure.md`](history/12-bun-executable-structure.md), [`history/13-opencode-runtime-build.md`](history/13-opencode-runtime-build.md) — 中文 in part: the wrapper-era build path (glibc binary + loader).
- [`history/20-packaging-deb.md`](history/20-packaging-deb.md), [`history/21-packaging-pkg-tar-xz.md`](history/21-packaging-pkg-tar-xz.md), [`history/22-termux-services-opencode-web.md`](history/22-termux-services-opencode-web.md) — 中文 in part: `.deb` / pacman layout and the `opencode web` service.
- [`history/30-ci-local-build-matrix.md`](history/30-ci-local-build-matrix.md) — local/CI verification matrix of that era.
- [`history/99-open-issues-and-upstream-sync.md`](history/99-open-issues-and-upstream-sync.md) — 中文: open issues and upstream sync snapshot.
- [`history/local-production.md`](history/local-production.md) — local-only production blueprint.
- [`history/comparison-runtime-lines.md`](history/comparison-runtime-lines.md) — 中文: three-line runtime comparison.
- [`history/native-line-evolution.md`](history/native-line-evolution.md) — 中文: ELF splice → real bionic compile, RC3/RC4 institutionalisation.
- [`history/native-android-research.md`](history/native-android-research.md) — native Android Bun research notes.
- [`history/ops-lessons-rc3.md`](history/ops-lessons-rc3.md) — 中文: RC3 release lessons (PKGREL matrix, network, shim open item).
- [`history/glibc-min-deps-test-report.md`](history/glibc-min-deps-test-report.md) — glibc dependency reduction test report.
- [`history/OCTPLUGIN-PREBRANCH-RESEARCH.md`](history/OCTPLUGIN-PREBRANCH-RESEARCH.md) — single-file pre-split plugin research baseline.
- [`history/upstream-notification-package-rename.md`](history/upstream-notification-package-rename.md) — package rename transition notice.
- [`history/quick-build.sh`](history/quick-build.sh) — old convenience build script.
- [`history/handover/`](history/handover/) — 中文: 2026-09-30 handover snapshot (machine env, release runbook, community state, open items, recall pack).
- [`history/incidents/`](history/incidents/) — incident records, e.g. the `.so` restart-storm RCA.
- [`guides/migration-v1-to-v2.md`](guides/migration-v1-to-v2.md) — 中文: v1 → v2 upgrade and rollback for devices still on the old line.

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
