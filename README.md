# OpenCode 2 native for Termux

[OpenCode](https://opencode.ai) is an AI-powered terminal coding assistant. This project ships it as a native Android/aarch64 Bionic binary for [Termux](https://termux.dev): no PRoot, no glibc. It has been tested on one Android 14 phone; wider device testing is welcome.

## Requirements

- Termux on an Android/aarch64 device running Android 9 (API 28) or newer.
- About 300 MiB free for the installed binary, plus space for the download during installation.
- `curl` and `sha256sum` in Termux. No Node.js, npm, root, or PRoot is needed to run it.

## Install

In Termux:

```sh
curl -fsSL https://github.com/Spectra010s/opencode-termux/releases/download/v2.0.26-termux.1/install.sh | sh
opencode
```

The installer downloads the [GitHub release](https://github.com/Spectra010s/opencode-termux/releases) binary, checks its SHA-256 against the release checksum file, and installs it as `~/.local/bin/opencode`. If `~/.local/bin` is not on `PATH`, it prints the direct command and the exact PATH line to add; it does not silently edit your shell startup files.

No apt/pacman package for this build has been published by this project.

## Migrating from v1

The installer replaces only `~/.local/bin/opencode`; it does not delete your chats, sign-ins, or configuration. OpenCode v2 can migrate the existing SQLite database at `~/.local/share/opencode/opencode.db` in place. Back up your OpenCode data before switching if you might need to return to v1. The command remains `opencode`, not `opencode2`.

## Uninstall

```sh
rm -f ~/.local/bin/opencode
```

Optional (deletes chats, auth, config — skip if unsure):

```sh
rm -rf ~/.local/share/opencode ~/.config/opencode
```

## Build from source

You can build a native binary yourself in Termux or GitHub Actions. Follow the [native build guide](docs/native-v2-build.md); the [transplant guide](docs/transplant.md) explains the Bionic runtime and native renderer. The released binary is built in GitHub Actions from pinned sources, not uploaded from a maintainer's phone.

## Releases and provenance

The [build workflow](.github/workflows/build-native-android.yml) produces a candidate. After testing, the [release workflow](.github/workflows/publish-native-android.yml) downloads that CI artifact, verifies its hash, and publishes it. [Build inputs](tools/supply-chain-lock.json) are pinned to specific versions, hashes, or commits. Releases are currently manual, not weekly automatic updates.

This project is derived from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux); OpenCode itself is [upstream](https://github.com/anomalyco/opencode). Older docs in this repository describe upstream package lines and may not apply to this release. See [LICENSE](LICENSE) for this repository; dependencies retain their own licenses.

## Maintainer

Adeloye Adetayo ([Spectra010s](https://spectra010s.com/?utm_source=github))
