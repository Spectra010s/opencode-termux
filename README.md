# OpenCode 2 native for Termux

[OpenCode](https://opencode.ai) is an AI-powered terminal coding assistant. This fork ships it as a native Android/aarch64 Bionic binary for [Termux](https://termux.dev): no PRoot, no glibc. This is a prerelease tested on one Android 14 phone; wider device testing is welcome.

## Install

In Termux:

```sh
curl -fsSLO https://github.com/Spectra010s/opencode-termux/releases/download/v2.0.26-termux.1/install.sh
sh install.sh
opencode
```

The installer downloads the [GitHub release](https://github.com/Spectra010s/opencode-termux/releases) binary, checks its SHA-256 against the release checksum file, and installs it as `~/.local/bin/opencode`. If `~/.local/bin` is not on `PATH`, it prints the direct command and the exact PATH line to add; it does not silently edit your shell startup files.

Requires Android/aarch64, Android API 28+, Termux, `curl`, and `sha256sum`. The installed binary itself does not require Node.js or npm. It is about 299 MiB installed. No apt/pacman package for this build has been published by this fork.

OpenCode v2 updates its normal SQLite database in place at `~/.local/share/opencode/opencode.db`. Back up your data before switching from v1 if you may need to downgrade.

## Uninstall

```sh
rm -f ~/.local/bin/opencode
```

Optional (deletes chats, auth, config — skip if unsure):

```sh
rm -rf ~/.local/share/opencode ~/.config/opencode
```

## Build and provenance

Releases come from the pinned [native Android Actions workflow](.github/workflows/build-native-android.yml) for reproducibility. On-device builds are also supported, see [the native build guide](docs/native-v2-build.md). The [release workflow](.github/workflows/publish-native-android.yml) downloads a successful CI artifact, verifies its hash, and publishes the release from GitHub Actions. [Build inputs](tools/supply-chain-lock.json) are locked by hash.

This fork is derived from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux); OpenCode itself is [upstream](https://github.com/anomalyco/opencode). Older docs in this repository describe upstream package lines and may not apply to this release. See [LICENSE](LICENSE) for this repository; dependencies retain their own licenses.

## Maintainer

Adeloye Adetayo ([Spectra010s](https://spectra010s.com/?utm_source=github))
