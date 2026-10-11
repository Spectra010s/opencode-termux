# Native v2 build

Target: OpenCode `2.0.26` native Android/aarch64 Bionic, no proot or glibc.

Two supported paths:

- CI (reproducible releases): `.github/workflows/build-native-android.yml` on branch `native-android`. Inputs locked in `tools/supply-chain-lock.json`. Release via `.github/workflows/publish-native-android.yml`, which verifies the CI artifact hash and publishes `install.sh` + tarball. CI cross-compiles OpenTUI with NDK sysroot (`BIONIC_LIB_DIR`) + Zig.
- On-device (Termux itself is Bionic, no NDK): full guide in `docs/transplant.md`. Deps: `pkg install python3 nodejs clang make zig` (`zig` only to rebuild OpenTUI; `upx` optional), plus network for `npm pack` + Android Bun download. Example:
  ```sh
  make transplant VER=2.0.26
  ```
  Output: `artifacts/transplant/2.0.26/opencode-native-revived`. Then test: `opencode --version`, TUI smoke, auth, prompt, clean exit.
