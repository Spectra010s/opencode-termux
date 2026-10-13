# OpenCode 2.0.28 for Termux

Run OpenCode v2 directly in Termux on Android ARM64, without PRoot or glibc. This release updates the app to 2.0.28 while keeping the single `opencode` command.

Install in Termux:

```sh
curl -fsSL https://github.com/Spectra010s/opencode-termux/raw/v2.0.28/install.sh | sh
```

Then run `opencode`. The installer checks both the compressed download and executable against release checksums before replacing `~/.local/bin/opencode`. It keeps your chats, sign-ins, and configuration. Back up your OpenCode data first if you might need to return to v1, because v2 may migrate the session database.

`opencode upgrade` points to this verified installer rather than downloading an incompatible upstream build. `opencode uninstall --dry-run` previews removal; `opencode uninstall` removes this binary and the shared cache after confirmation, but retains user data.

The build comes from pinned OpenCode source and Android/Bionic components in [GitHub Actions](https://github.com/Spectra010s/opencode-termux/actions/workflows/build-native-android.yml). Checksums and build inputs are attached to the release; the [source-build guide](https://github.com/Spectra010s/opencode-termux/blob/native-android/docs/native-v2-build.md) shows how to reproduce it.

CI built and checked this exact candidate. An earlier 2.0.28 candidate passed `--version` and an Android 14 TUI smoke test; the final candidate changed installer-path handling and was not downloaded to the phone for a second smoke test. Wider device testing is welcome.
