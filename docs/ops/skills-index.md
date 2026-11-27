# Termux skills index (concise)

Use this index in prompts to recall the right doc and known fixes quickly.

## Plugin + hook
- `../guides/plugin-management.md` — install/update/rollback commands; prefer `file://` plugin paths on Termux for stability.
- `../reference/plugin-packaging-design.md` — package-manager plugin model; avoid `dist` as plugin name by pointing file-plugin to root `index.js`.
- `../reference/system-skills-hook-architecture.md` — hook events, safe defaults (`network=0`, `strict=0`), registry + blocklist paths.

## Runtime + troubleshooting
- `execution-checklist.md` — install/test runbook; if runtime missing, verify `glibc` + `openssl-glibc` and `opencode --version`.

