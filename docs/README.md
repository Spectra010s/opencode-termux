# opencode-termux documentation

The mainline is the **native bionic line**: an OpenCode bundle running on Termux's `bun` with bionic natives, no PRoot, no glibc. Everything describing the wrapper or the older glibc runtime is kept for history, not for following along.

Docs are grouped by what you need from them:

| Folder | What it answers |
|---|---|
| [`guides/`](guides/) | How do I build, install, migrate, manage plugins? |
| [`reference/`](reference/) | How does the pipeline actually work? Contracts and design notes. |
| [`ops/`](ops/) | Runbooks: validation, CI handoff, maintainer operations. |
| [`history/`](history/) | Superseded plans, research snapshots and RC-era records. Do not treat as current instructions. |

Some documents are written in Chinese (marked 中文 below); they are kept as-is because their evidence trails are still referenced.

## Start here

- [`guides/native-v2-build.md`](guides/native-v2-build.md) — current Android build: pinned inputs, CI path, local build.
- [`guides/apt-repository.md`](guides/apt-repository.md) — signed Termux APT source backed by releases, and migrating off the curl installer.
- [`guides/dual-track-install.md`](guides/dual-track-install.md) — which `opencode` package you are installing (native mainline vs wrapper appendix).
- [`guides/migration-v1-to-v2.md`](guides/migration-v1-to-v2.md) — 中文: v1 → v2 upgrade, rollback, package names, build lines.
- [`ops/execution-checklist.md`](ops/execution-checklist.md) — install/test runbook (apt first, pacman second).
- [`.release/`](../.release) — reviewed release notes and the TUI banner source, one pair per version.
- [`reference/transplant.md`](reference/transplant.md) — 中文: the native transplant/revive surgery the build depends on.

## Guides

- [`guides/native-v2-build.md`](guides/native-v2-build.md) — native v2 build pipeline: bundle build on Termux's bun, bionic natives, FFI guard checks.
- [`guides/apt-repository.md`](guides/apt-repository.md) — signed release-backed Termux APT repository.
- [`guides/dual-track-install.md`](guides/dual-track-install.md) — provider selection and the Push-tag/package-name boundary between families.
- [`guides/migration-v1-to-v2.md`](guides/migration-v1-to-v2.md) — 中文: migration guide for users on v1.
- [`guides/plugin-management.md`](guides/plugin-management.md) — plugin install, self-update, snapshot rollback.
- [`guides/make-maintainer.md`](guides/make-maintainer.md) — Make surface: build, upload, cache and fleet-push operations.

## Reference

- [`reference/transplant.md`](reference/transplant.md) — 中文: revive/splice procedure, ELF hooks, TUI lib swap.
- [`reference/compressed-line.md`](reference/compressed-line.md) — 中文: UPX/compressed launcher contract and stale-runtime isolation rules.
- [`reference/tui-common-fix.md`](reference/tui-common-fix.md) — 中文: TUI crash analysis (pointer tags, FFI shim, renderer startup).
- [`reference/tui-reachability.md`](reference/tui-reachability.md) — 中文: TUI reachability matrix for the rc6-b2 build.
- [`reference/upx-v2-fix.md`](reference/upx-v2-fix.md) — 中文: UPX hypotheses and the verification sequence.
- [`reference/system-skills-hook-architecture.md`](reference/system-skills-hook-architecture.md) — package-mode system skills and the hook framework.
- [`reference/hook-design-proposal.md`](reference/hook-design-proposal.md) — 中文: install-time hook ownership and characterisation.
- [`reference/plugin-packaging-design.md`](reference/plugin-packaging-design.md) — package-manager-driven plugin model.
- [`reference/arch-reference-mapping.md`](reference/arch-reference-mapping.md) — reusable pieces from the Arch plugin packaging approach.
- [`reference/patch-coverage-audit.md`](reference/patch-coverage-audit.md) — 中文: patch coverage across eight layers and thirteen versions.
- [`reference/performance-optimization.md`](reference/performance-optimization.md) — 中文: performance roadmap.
- [`reference/bundle-list.txt`](reference/bundle-list.txt) — Bun module bundle inventory.
- [`reference/measurements/native-baseline-1.3.13.json`](reference/measurements/native-baseline-1.3.13.json) — recorded baseline measurements.

## Operations

- [`ops/execution-checklist.md`](ops/execution-checklist.md) — end-to-end install/test validation.
- [`ops/skills-index.md`](ops/skills-index.md) — concise index of Termux skills and quick fixes.

## History

Wrapper-era and older runtime documents. Useful for archaeology; superseded by the native line.

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

## Ground rules

- Do not use musl or PRoot for the release runtime path.
- Build against the pinned Android Bun base, verify the FFI guard on the unstripped lib, then strip and swap; the legacy `transplant.py all` splice is dead on Bun 1.4.4.
- Validate `file` output and `--version` from the built binary, then again from the shipped package.
- aarch64 is the only supported target; 32-bit (armv7/arm32) is not supported and its build scripts have been removed.

## Maintaining these docs

- When behaviour and docs diverge, fix the doc in the same change as the code.
- Replace stale sections instead of appending contradictory notes.
- If you move or add a workflow-critical document, update this index and the root `AGENTS.md` map.
