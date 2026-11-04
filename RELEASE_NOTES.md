# OpenCode 2.2.5 for Termux

OpenCode v2 as a native Android/aarch64 Bionic binary for Termux: no PRoot, no glibc. This release moves the Android build from 2.0.28 to 2.2.5, and fixes the reason the previous 2.2.x candidates died before drawing a single frame.

## Install

```sh
curl -fsSL https://github.com/Spectra010s/opencode-termux/raw/v2.2.5/install.sh | sh
```

Then run `opencode`. The installer checks the compressed download and the executable against the release checksums before replacing `~/.local/bin/opencode`, and keeps your chats, sign-ins, and configuration.

Already on 2.0.28? Run `opencode upgrade`. It points at this verified installer.

Requires Android 9 (API 28) or newer, aarch64, and about 700 MiB free.

## What changed upstream (2.2.0 → 2.2.5)

- **`/goal`**: keep a session working toward an objective until a reviewer confirms it is met (`/goal pause`, `/goal resume`, `/goal clear`).
- **Image generation**: agents can create or edit images through `experimental_image_generate`, enabled automatically when a connected provider has image models.
- **Claude Agent**: sign in with Claude Code (`claude auth login`) and select it in `/connect` to use those models.
- **OpenTUI 0.8**: TUI plugins now require `@opentui/core` and `@opentui/solid` 0.8 or newer; scroll and render-context APIs changed accordingly.
- **Compaction buffer as a percentage**: `"compaction": { "buffer": "20%" }` keeps part of any model's context window free.
- **Fixes**: MCP servers sending messages over 10 MiB no longer get disconnected, calls to a tool named `bash` run as `shell` instead of failing, and `read`/`edit` errors now point at the missing folder or the closest matching lines.

Desktop-only changes in these versions (persistent desktop terminals, artifacts, the desktop model picker) do not apply to this Termux build.

## What changed in this Android build

- Built from pinned OpenCode source with Bun 1.4.4 and OpenTUI 0.8.0 (Zig 0.16.0); versions, hashes, and commits live in [`tools/supply-chain-lock.json`](https://github.com/Spectra010s/opencode-termux/blob/native-android/tools/supply-chain-lock.json).
- The candidate now compiles directly against the pinned Android Bun base and grafts the bionic OpenTUI library onto it. Re-running the old post-compile transplant on a 1.4.4 base produced a binary that died with SIGILL on the first instruction.
- **TUI fix**: Android bionic tags heap pointers in the top byte, and OpenTUI's FFI shim rejected those as unsafe (`Pointer exceeds safe integer range`) before the first frame. The build now masks that tag before the check, so the renderer starts normally.
- `opencode upgrade` still points at this verified installer instead of an incompatible upstream download. `opencode uninstall --dry-run` previews removal; `opencode uninstall` removes the binary and shared cache but keeps user data.

## Verified build

The candidate came from [Actions run 41906034445](https://github.com/Spectra010s/opencode-termux/actions/runs/41906034445), built and checked by CI, with `sha256 24e9600d80752a31c052135a75677495fcb0ee694580216aa9dc37a89a75d657`. It was tested: `--version` passed, providers and models listed through the server, and the TUI started. Wider device testing is welcome; report problems at [issues](https://github.com/Spectra010s/opencode-termux/issues).

Checksums and build inputs are attached to this release. The [source-build guide](https://github.com/Spectra010s/opencode-termux/blob/native-android/docs/guides/native-v2-build.md) shows how to reproduce the build.
