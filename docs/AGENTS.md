# DOCS KNOWLEDGE BASE

## OVERVIEW
`docs/` is organised by role, not by lifecycle number: `guides/` (how to), `reference/` (how it works), `ops/` (runbooks), `history/` (superseded material). The wrapper-era numbered series lives in `history/`.

## NAVIGATION ANCHORS
- Start at `README.md` — it is the index and the language map (several documents are Chinese).
- Mainline work is the native bionic line; anything under `history/` describes what came before it.

## WHERE TO LOOK
| Question | Document | Notes |
|---|---|---|
| How do I build the Android binary? | `guides/native-v2-build.md` | pinned inputs, CI path, local build |
| How is the build physically produced? | `reference/transplant.md` | 中文: revive/splice + TUI lib swap |
| Which package am I installing? | `guides/dual-track-install.md` | native mainline vs wrapper appendix |
| Validation runbook? | `ops/execution-checklist.md` | install/test, apt then pacman |
| Hook/system-skill model? | `reference/system-skills-hook-architecture.md` | policy defaults, lifecycle, registry/blocklist |
| Plugin operations? | `guides/plugin-management.md`, `reference/plugin-packaging-design.md` | file-plugin mode + rollback model |
| Maintainer operations? | `guides/make-maintainer.md` | Make surface, upload, cache |
| Incident context? | `history/incidents/` | RCA + follow-up actions |
| Old wrapper/glibc build path? | `history/11-opencode-build-plan.md`, `history/13-opencode-runtime-build.md` | 中文 in part; superseded |

## CONVENTIONS
- Keep docs aligned with current command surfaces (`Makefile`, `scripts/*`, `tools/*`).
- If adding a workflow-critical document, update `docs/README.md` and the root `AGENTS.md` map.
- Keep target scope explicit: aarch64 only.
- Label Chinese documents in the index rather than translating them piecemeal.

## ANTI-PATTERNS (DOCS)
- Do not propose 32-bit (armv7/arm32) targets; 32-bit Bun builds fail.
- Do not present `history/` material as current instructions.
- Do not duplicate long command sequences across many files; link to canonical runbook sections.
- Do not leave numbering/index references stale after moving or adding docs.

## QUICK CHECK
```bash
# verify docs entrypoints still resolve
ls docs/README.md docs/guides/native-v2-build.md docs/ops/execution-checklist.md docs/reference/transplant.md
```
