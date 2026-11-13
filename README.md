# OpenCode 2 native for Termux

[OpenCode](https://opencode.ai) is an AI-powered terminal coding assistant. This project ships it for [Termux](https://termux.dev) as a JavaScript bundle running on Termux's `bun`, with Bionic builds of every native library it loads: no PRoot, no glibc. Wider device testing is welcome.

## Requirements

- Termux on an Android/aarch64 device running Android 9 (API 28) or newer. 32-bit ARM and x86 are not built.
- `bun`, `ripgrep` and `libc++` from Termux. The installer adds the first two with `pkg` when they are missing and the package declares all three as dependencies.
- About 200 MiB free during installation or upgrade: a 16 MB download, a 68 MiB installed bundle, and the previous install until it is replaced.
- `curl` and `sha256sum` in Termux. No Node.js, npm, root, or PRoot is needed to run it.

## Install

```sh
curl -fsSL https://github.com/Spectra010s/opencode-termux/raw/native-android/install.sh | sh
opencode
```

The installer downloads the [GitHub release](https://github.com/Spectra010s/opencode-termux/releases) bundle, checks its SHA-256 against the release checksum file, and installs the launcher as `$PREFIX/bin/opencode` with the module graph in `$PREFIX/lib/opencode`. Chats, sign-ins, and configuration are untouched. An install from the 2.2.6-era installer at `~/.local/bin/opencode` is removed when the new one is in place.

## Install with APT

Termux's `pkg` can track the release for you instead:

```sh
curl -fsSL https://raw.githubusercontent.com/Spectra010s/opencode-termux/native-android/setup-apt.sh | sh
pkg install opencode
```

The setup script adds this project's signed source and its public key; it does not install OpenCode. This source is independent of the official Termux repository and of the `opencode` package proposed there.

## Upgrade

`opencode upgrade` (or its `opencode update` alias, or `/update` in the TUI) runs this project's installer for the requested version. Under APT, use `apt update && apt install --only-upgrade opencode` instead: the launcher refuses to replace a package-owned file.

## Uninstall

`opencode uninstall` stops its background services, removes its cache, the launcher and the bundle, but keeps chats, sign-ins, and configuration. Preview it first:

```sh
opencode uninstall --dry-run
opencode uninstall
```

If the command cannot start, remove the install by hand:

```sh
rm -f "$PREFIX/bin/opencode"
rm -rf "$PREFIX/lib/opencode"
```

## Troubleshooting

**`opencode: command not found` after installing.** `$PREFIX/bin` is on `PATH` in every fresh Termux session; run `hash -r` in the session you installed from.

**`bun: command not found`.** The bundle runs on Termux's `bun`, and the installer only adds it when `pkg` is present. Install it with `pkg install bun ripgrep`, then rerun `opencode`.

**The installer reported a checksum mismatch.** The download was altered or truncated; nothing was installed. Rerun it. If it repeats, the release asset is wrong — open an issue with the version and the two hashes.

**Two `opencode` commands.** A 2.2.6-era standalone binary may still be at `~/.local/bin/opencode`. `command -v opencode` shows which one wins; remove the old file.

**Which install do I have?** `dpkg -S "$PREFIX/bin/opencode"` prints the package name for an APT install and "no path found matching pattern" for the curl installer.

**It starts but the TUI is blank or garbled.** Check `echo $TERM`; OpenCode needs a truecolor-capable terminal, and Termux's default is fine. Report the version from `opencode --version`, the device, and the Android version.

## Migrating from v1

The installer replaces the launcher and the bundle directory; it does not delete your chats, sign-ins, or configuration. OpenCode v2 can migrate the existing SQLite database at `~/.local/share/opencode/opencode.db` in place. Back up your OpenCode data before switching if you might need to return to v1. The command remains `opencode`, not `opencode2`.

## Build from source

Releases are built from pinned source in GitHub Actions, not uploaded from a maintainer's phone. The pinned OpenCode, Bun and OpenTUI versions live in [`tools/supply-chain-lock.json`](tools/supply-chain-lock.json) (`current` plus a hash per version); `tools/ocver.py` supplies them to CI. Follow the [native build guide](docs/guides/native-v2-build.md) to reproduce a build.

## Releases and provenance

The [build workflow](.github/workflows/build-native-android.yml) produces an unsigned artifact you can install to test. Pushing the release tag makes the [release workflow](.github/workflows/publish-native-android.yml) call that same build, verify its checksums, sign the APT index and publish it with the notes in [`.release/`](.release). A broken release is fixed and republished under a bumped revision (`v2.2.7-2`); releases are manual, not weekly automatic updates.

This independent repository was derived from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux); OpenCode source comes from [anomalyco/opencode](https://github.com/anomalyco/opencode). See [LICENSE](LICENSE) for this repository; dependencies retain their own licenses.

## Maintainer

Adeloye Adetayo ([Spectra010s](https://spectra010s.com/?utm_source=github))
