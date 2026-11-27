# DOCS KNOWLEDGE BASE

## OVERVIEW
`docs/` is flat: an index, a build/patch guide and an APT runbook. No subdirectories.

## WHERE TO LOOK
| Question | Document | Notes |
|---|---|---|
| What is patched for Android and why? | `native-v2-build.md` | source/native patches, build shape |
| How is the APT source set up? | `apt-repository.md` | flat repo, signing, device setup |
| What are the ground rules? | `README.md` | index and constraints |

## CONVENTIONS
- Keep docs aligned with the current command surface (`scripts/ci/*`, `scripts/*`).
- Do not repeat version literals; refer to `supply-chain-lock.json` and `scripts/ocver.py`.
- Update `docs/README.md` and the root `AGENTS.md` when a document moves.

## ANTI-PATTERNS
- Do not propose 32-bit targets.
- Do not duplicate long command sequences across files; link to the canonical document.

## QUICK CHECK
```bash
ls docs/README.md docs/native-v2-build.md docs/apt-repository.md
```
