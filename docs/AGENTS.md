# DOCS KNOWLEDGE BASE

## OVERVIEW
`docs/` holds the index, two guides and the APT repository runbook.

## NAVIGATION ANCHORS
- Start at `README.md` — it is the index.

## WHERE TO LOOK
| Question | Document | Notes |
|---|---|---|
| How do I build the Android bundle? | `guides/native-v2-build.md` | pinned inputs, CI path, OpenTUI step |
| What does a release publish? | `apt-repository.md` | flat APT repo setup, signed index, failure modes |
| Plugin operations? | `guides/plugin-management.md` | file-plugin mode + rollback model |

## CONVENTIONS
- Keep docs aligned with current command surfaces (`scripts/ci/*`, `scripts/*`).
- If adding a workflow-critical document, update `docs/README.md` and the root `AGENTS.md` map.
- Keep target scope explicit: aarch64 only.

## ANTI-PATTERNS (DOCS)
- Do not propose 32-bit (armv7/arm32) targets; 32-bit Bun builds fail.
- Do not duplicate long command sequences across many files; link to canonical runbook sections.
- Do not leave numbering/index references stale after moving or adding docs.

## QUICK CHECK
```bash
# verify docs entrypoints still resolve
ls docs/README.md docs/guides/native-v2-build.md docs/apt-repository.md
```
