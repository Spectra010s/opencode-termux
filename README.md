# OpenCode 2 native for Termux

[OpenCode](https://opencode.ai) is an AI-powered terminal coding assistant. This project ships it for [Termux](https://termux.dev) as a JavaScript bundle running on Termux's `bun`, with Bionic builds of every native library it loads: no PRoot, no glibc. Wider device testing is welcome.

## Requirements

- Termux on an Android/aarch64 device running Android 9 (API 28) or newer.
- `bun`, `ripgrep` and `libc++` from Termux. The installer adds the first two with `pkg` when they are missing and the package declares all three as dependencies.
- About 200 MiB free during installation or upgrade: a 16 MB download, a 68 MiB installed bundle, and the previous install until it is replaced.
- `curl` and `sha256sum` in Termux. No Node.js, npm, root, or PRoot is needed to run it.

## Install

In Termux:

```sh
curl -fsSL https://github.com/Spectra010s/opencode-termux/raw/native-android/install.sh | sh
opencode
```

The installer downloads the [GitHub release](https://github.com/Spectra010s/opencode-termux/releases) bundle, checks its SHA-256 against the release checksum file, and installs the launcher as `$PREFIX/bin/opencode` with the module graph in `$PREFIX/lib/opencode`. Chats, sign-ins, and configuration are untouched. An install from the 2.2.6-era installer at `~/.local/bin/opencode` is removed when the new one is in place.

Already on an earlier build? Run `opencode upgrade`; its `opencode update` alias and the TUI's `/update` do the same. They run this repository's installer for the requested version. To update an APT installation, use `apt update && apt install --only-upgrade opencode`.

OpenCode is also available from this project's APT source. Follow the
[APT setup and install instructions](docs/guides/apt-repository.md).

## Migrating from v1

The installer replaces the launcher and the bundle directory; it does not delete your chats, sign-ins, or configuration. OpenCode v2 can migrate the existing SQLite database at `~/.local/share/opencode/opencode.db` in place. Back up your OpenCode data before switching if you might need to return to v1. The command remains `opencode`, not `opencode2`.

## Uninstall

`opencode uninstall` stops its background services, removes its cache, the launcher and the bundle, but keeps chats, sign-ins, and configuration. Preview it first:

```sh
opencode uninstall --dry-run
opencode uninstall
```

If the command cannot start, remove only the installed binary manually:

```sh
rm -f "$PREFIX/bin/opencode"
rm -rf "$PREFIX/lib/opencode"
```

## Build from source

Releases are built from pinned source in GitHub Actions, not uploaded from a maintainer's phone. The pinned OpenCode, Bun and OpenTUI versions live in [`tools/supply-chain-lock.json`](tools/supply-chain-lock.json) (`current` plus a hash per version); `tools/ocver.py` supplies them to CI. The installer pins its release tag so a tagged copy continues to install the same version. Follow the [native build guide](docs/guides/native-v2-build.md) to reproduce a build or to use the separate on-device build path; the [transplant guide](docs/reference/transplant.md) explains the Bionic runtime and native renderer.

## Releases and provenance

The [build workflow](.github/workflows/build-native-android.yml) produces a candidate. After testing, pushing the release tag makes the [release workflow](.github/workflows/publish-native-android.yml) download that CI artifact, verify its checksums, and publish it with the notes in [`.release/`](.release). [Build inputs](tools/supply-chain-lock.json) are pinned to specific versions, hashes, or commits. Releases are currently manual, not weekly automatic updates.

This independent repository was derived from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux); OpenCode source comes from [anomalyco/opencode](https://github.com/anomalyco/opencode). Older docs here describe historical package lines and may not apply to this release. See [LICENSE](LICENSE) for this repository; dependencies retain their own licenses.

## Maintainer

Adeloye Adetayo ([Spectra010s](https://spectra010s.com/?utm_source=github))
