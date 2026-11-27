# DOCS KNOWLEDGE BASE

## OVERVIEW
`docs/` is organised by role: `guides/` (how to), `reference/` (how it works), `ops/` (runbooks).

## NAVIGATION ANCHORS
- Start at `README.md` — it is the index.

## WHERE TO LOOK
| Question | Document | Notes |
|---|---|---|
| How do I build the Android bundle? | `guides/native-v2-build.md` | pinned inputs, CI path, OpenTUI step |
| What does a release publish? | `ops/apt-repository.md` | signed flat APT repo, failure modes |
| Validation runbook? | `ops/execution-checklist.md` | tag run, install paths, on-device checks |
| Plugin operations? | `guides/plugin-management.md`, `reference/plugin-packaging-design.md` | file-plugin mode + rollback model |

## CONVENTIONS
- Keep docs aligned with current command surfaces (`scripts/ci/*`, `tools/*`).
- If adding a workflow-critical document, update `docs/README.md` and the root `AGENTS.md` map.
- Keep target scope explicit: aarch64 only.

## ANTI-PATTERNS (DOCS)
- Do not propose 32-bit (armv7/arm32) targets; 32-bit Bun builds fail.
- Do not duplicate long command sequences across many files; link to canonical runbook sections.
- Do not leave numbering/index references stale after moving or adding docs.

## QUICK CHECK
```bash
# verify docs entrypoints still resolve
ls docs/README.md docs/guides/native-v2-build.md docs/ops/execution-checklist.md docs/ops/apt-repository.md
```
