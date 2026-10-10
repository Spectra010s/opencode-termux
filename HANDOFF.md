# OpenCode v2 native Android handoff

Status date: 2026-10-10

## Goal and current truth

Build OpenCode `2.0.26` as a native Android/aarch64 Termux candidate without proot or glibc. The repository has been statically audited and its supply chain hardened. No malware indicators were found, but this is **not yet a finished or stable release**. GitHub Actions must pass, then the resulting binary must be tested on the user's Android device.

Fork: <https://github.com/Spectra010s/opencode-termux>

Working branch: `harden-v2.0.26`

Actions branch: `native-android`

## Security/audit result

- No credential-stealing logic, suspicious network endpoint, or unexplained socket/connect import was found in the reviewed repository code and committed binaries.
- Inputs are pinned by version, commit, and SHA-256 in `tools/supply-chain-lock.json`.
- OpenTUI patches are exact and fail closed if the pinned source differs.
- The SIGSYS compatibility handler only permits the audited aarch64 syscall numbers 434, 436, 437, and 452; unexpected traps exit.
- The OpenCode `openat2` shim is still a security relaxation in the source-build route. The current Actions transplant route does not invoke that local source build/shim.
- Passing CI alone is insufficient because the Ubuntu x86_64 runner cannot execute the Android/aarch64 result.

## Locked inputs

- OpenCode `2.0.26` commit: `9b4ec5714d481559990db0a816d5dec19541a814`
- OpenCode source tar SHA-256: `3c8373973985b7691843faf7d5603cb11d8eb1b9c66b73d5f92e999b93236d35`
- `@opencode/cli-linux-arm64@2.0.26` tar SHA-256: `1d7117dbb31968456f89537b562fb5e20e48d9e9ef0325fc8845abdda6ef4842`
- Bun Android `1.4.0` zip SHA-256: `42544d7438bb92c7e7df7d30b9a5858cb7a834636608e5b850f59138283567fc`
- Bun extracted ELF SHA-256: `44a83a9b716a2df09c7c62cfee94f99b4d0b389f9326c6318c4831d888e2a250`
- OpenTUI `0.5.17` commit: `6f0efd3330978d696b42db3d7d95d2042008312b`
- Zig `0.16.0` archive SHA-256: `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00`
- `actions/upload-artifact` v6 commit: `b7c566a772e6b6bfb58ed0dc250532a479d7789f`

## CI history and present fix

Earlier runs exposed and fixed: broken upstream submodule checkout, Zig 0.16 API drift, missing NDK headers, unversioned Android targets, and missing Android API macros.

Run `38052473347` reached OpenTUI linking and failed because Zig was given no NDK library search path for `dl`, `pthread`, and `m`. The next patch passes `BIONIC_LIB_DIR` into the pinned OpenTUI build, adds that path to the Zig module, and omits `-lpthread` for Android because Bionic supplies pthread symbols through libc.

Latest known failed run: <https://github.com/Spectra010s/opencode-termux/actions/runs/38052473347>

## Continue

```sh
cd /data/data/com.termux/files/home/opencode-termux
git status --short --branch
git push fork harden-v2.0.26
git push fork harden-v2.0.26:native-android
gh workflow run build-native-android.yml --repo Spectra010s/opencode-termux --ref native-android
gh run list --repo Spectra010s/opencode-termux --workflow build-native-android.yml --limit 1
gh run watch RUN_ID --repo Spectra010s/opencode-termux --exit-status
```

If linking fails again, inspect it with:

```sh
gh run view RUN_ID --repo Spectra010s/opencode-termux --log-failed
```

Do not publish a GitHub release yet. Once CI is green, download the artifact on Termux, verify `SHA256SUMS`, run `file` and `readelf -d`, then test `opencode --version`, startup, TUI input/rendering, provider authentication, a harmless prompt, and clean exit. Record those results before describing the build as stable.

## Local side effects already disclosed

Static inspection used `npm pack`; it did not install the package globally or execute its contents. Audit downloads remain under `/data/data/com.termux/files/usr/tmp/opencode-audit-2.0.26`, and the sparse OpenTUI checkout remains under `/data/data/com.termux/files/usr/tmp/opentui-audit-0.5.17`. Do not delete them without telling the user.
