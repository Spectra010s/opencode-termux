## What changed upstream (2.2.5 → 2.2.6)

- **Shared MCP connections**: `pool: true` on an MCP server shares one connection across projects with the same setup, so you run fewer processes and start faster.
- **Scripted runs in worktrees**: `opencode run -w` (or `--worktree=<name>`) starts the session in a new git worktree, and `--archived` keeps CI and scripted sessions out of the inbox, home, and session lists.
- **Session warming**: provider- and model-specific warming settings, including an `interval: "auto"` mode based on cache TTL.
- **`opencode run` waits for its background work**: background shells, subagents, and image jobs finish first (it prints `waiting for N background job(s)`) and the model answers their results before the run exits. There is no time limit, so set a timeout on CI jobs.
- **TUI fixes**: Ctrl+Z suspends while a form or dialog is open, session titles containing newlines no longer crash the TUI, focus stays on an open dialog when a question arrives, and **Scroll on send** keeps your reading position after you submit a prompt.
- **Security**: file reads and media are served as sandboxed downloads, `/api/*` refuses cross-site navigations and requests from disallowed origins, and webfetch/Code Mode URLs that contain credentials are rejected.
- **Also**: MCP servers that are still connecting get up to 2 seconds before a model call, OpenCode Console config requests time out after 5 seconds instead of hanging startup, and `opencode acp` no longer leaves empty IDE sessions behind.

Desktop-only changes in 2.2.6 (mobile composer dock, GUI plugin themes and slots, tab menu actions) do not apply to this Termux build.

## What changed in this Android build

- Built from pinned OpenCode source with Bun 1.4.4 and OpenTUI 0.8.1 (Zig 0.17.0); versions, hashes, and commits live in [`tools/supply-chain-lock.json`](https://github.com/Spectra010s/opencode-termux/blob/native-android/tools/supply-chain-lock.json).
- **Quiet shutdown**: 2.2.5 cleared the ARM top-byte tag that bionic puts on heap pointers so the renderer would start, but Scudo re-checks that tag when the memory is freed, so quitting printed a pointer-tag message. Pointers are now handed to Bun's FFI unchanged (Bun 1.4 keeps all 64 bits for `ptr` arguments), so nothing is truncated and shutdown prints nothing. Untagged platforms and small allocations still take the plain-number path upstream uses.
- **OpenTUI 0.8.1 build**: Zig 0.17.0 requires every field in the `--libc` file and its `translate-c` also searches the host include directories. The build now writes the full schema and shadows bionic `limits.h` inside the sysroot, so the Android OpenTUI library builds the same way in CI and on a Termux device.
