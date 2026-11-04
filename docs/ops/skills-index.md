# Termux skills index (concise)

Use this index in prompts to recall the right doc and known fixes quickly.

## Plugin + hook
- `../guides/plugin-management.md` — install/update/rollback commands; prefer `file://` plugin paths on Termux for stability.
- `../reference/plugin-packaging-design.md` — package-manager plugin model; avoid `dist` as plugin name by pointing file-plugin to root `index.js`.
- `../reference/system-skills-hook-architecture.md` — hook events, safe defaults (`network=0`, `strict=0`), registry + blocklist paths.

## Runtime + troubleshooting
- `execution-checklist.md` — install/test runbook; if runtime missing, verify `glibc` + `openssl-glibc` and `opencode --version`.
- `../history/13-opencode-runtime-build.md` — runtime build flow (official arm64 + loader); use this if `opencode` fails to start.
- `../history/22-termux-services-opencode-web.md` — service behavior; for runit issues, check `$PREFIX/var/service/opencode-web`.
- `../history/incidents/2026-02-23-opencode-web-termux-so-avalanche.md` — `.so` restart storm RCA and mitigation.

## Build / packaging (URL only)
- DEB packaging: https://github.com/Hope2333/opencode-termux/blob/main/docs/history/20-packaging-deb.md
- Pacman packaging: https://github.com/Hope2333/opencode-termux/blob/main/docs/history/21-packaging-pkg-tar-xz.md
- Local production policy: https://github.com/Hope2333/opencode-termux/blob/main/docs/history/local-production.md
