# OpenCode 2 native for Termux

[OpenCode](https://opencode.ai) is an AI-powered terminal coding assistant. This project ships it as a native Android/aarch64 Bionic binary for [Termux](https://termux.dev): no PRoot, no glibc. Wider device testing is welcome.

## Requirements

- Termux on an Android/aarch64 device running Android 9 (API 28) or newer.
- About 700 MiB free during installation or upgrade. The installer temporarily holds the compressed download, an extracted binary, and a replacement copy before it switches binaries.
- `curl` and `sha256sum` in Termux. No Node.js, npm, root, or PRoot is needed to run it.

## Install

In Termux:

```sh
curl -fsSL https://github.com/Spectra010s/opencode-termux/raw/native-android/install.sh | sh
opencode
```

The installer downloads the [GitHub release](https://github.com/Spectra010s/opencode-termux/releases) binary, checks its SHA-256 against the release checksum file, and installs it as `~/.local/bin/opencode`. If `~/.local/bin` is not on `PATH`, it prints the direct command and the exact PATH line to add; it does not silently edit your shell startup files.

Once installed this way, `opencode upgrade`, its `opencode update` alias, and the TUI's `/update` use this repository's latest published release and verified installer. Existing binaries need a new release containing this update support before these commands work. To update an APT installation, use `apt update && apt install --only-upgrade opencode`.

OpenCode is also available from this project's APT source. Follow the
[APT setup and install instructions](docs/guides/apt-repository.md).

## Migrating from v1

The installer replaces only `~/.local/bin/opencode`; it does not delete your chats, sign-ins, or configuration. OpenCode v2 can migrate the existing SQLite database at `~/.local/share/opencode/opencode.db` in place. Back up your OpenCode data before switching if you might need to return to v1. The command remains `opencode`, not `opencode2`.

## Uninstall

`opencode uninstall` stops its background services, removes its cache and this project's installed binary, but keeps chats, sign-ins, and configuration. Preview it first:

```sh
opencode uninstall --dry-run
opencode uninstall
```

If the command cannot start, remove only the installed binary manually:

```sh
rm -f ~/.local/bin/opencode
```

## Build from source

Releases are built from pinned source in GitHub Actions, not uploaded from a maintainer's phone. The pinned OpenCode, Bun and OpenTUI versions live in [`tools/supply-chain-lock.json`](tools/supply-chain-lock.json) (`current` plus a hash per version); `tools/ocver.py` supplies them to CI. The installer pins its release tag so a tagged copy continues to install the same version. Follow the [native build guide](docs/guides/native-v2-build.md) to reproduce a build or to use the separate on-device build path; the [transplant guide](docs/reference/transplant.md) explains the Bionic runtime and native renderer.

## Releases and provenance

The [build workflow](.github/workflows/build-native-android.yml) produces a candidate. After testing, the [release workflow](.github/workflows/publish-native-android.yml) downloads that CI artifact, verifies its hash, and publishes it. [Build inputs](tools/supply-chain-lock.json) are pinned to specific versions, hashes, or commits. Releases are currently manual, not weekly automatic updates.

This independent repository was derived from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux); OpenCode source comes from [anomalyco/opencode](https://github.com/anomalyco/opencode). Older docs here describe historical package lines and may not apply to this release. See [LICENSE](LICENSE) for this repository; dependencies retain their own licenses.

## Maintainer

Adeloye Adetayo ([Spectra010s](https://spectra010s.com/?utm_source=github))
