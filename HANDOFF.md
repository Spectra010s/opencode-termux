# OpenCode v2 native Android handoff

Status date: 2026-10-10

## Goal and current truth

Build OpenCode `2.0.26` as a native Android/aarch64 Termux candidate without proot or glibc. The repository has been statically audited and its supply chain hardened. No malware indicators were found. GitHub Actions now passes, but this is **not yet a stable release** until the resulting binary passes tests on the user's Android device.

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

Run `38052473347` reached OpenTUI linking and failed because Zig was given no NDK library search path for `dl`, `pthread`, and `m`. Commit `14e1929` fixed that by passing `BIONIC_LIB_DIR`, adding the NDK path to the Zig module, and omitting `-lpthread` for Android because Bionic supplies pthread symbols through libc.

Run `38053424120` then compiled the Bionic OpenTUI library successfully and passed its FFI guard, but rejected an embedded absolute Actions workspace path. The next patch uses `tools/remap-binary-prefix.py` to replace only that exact prefix with a same-length `/usr/src////...` prefix before debug stripping. It preserves the ELF size and offsets and fails closed if the expected prefix is absent or remains.

Run `38054582952` passed the build-path check, Bionic verification, FFI guard, and locked OpenCode package verification. Transplant then selected Ubuntu's host `/usr/bin/strip`, which cannot process the Android/aarch64 library. The next patch exports the NDK `llvm-strip` path as `LLVM_STRIP`, and transplant validates and honors that explicit tool.

Run `38054798108` used NDK `llvm-strip` successfully. The debug-stripped library was `6,307,000` bytes, larger than the pinned package's `5,908,024`-byte embedded slot. The next patch uses `--strip-unneeded` and lets the mandatory FFI guard verifier fall back from the removed full symbol table to retained dynamic export symbols.

Run `38055045432` passed every CI step and uploaded the unsigned runtime-test candidate:

- Run: <https://github.com/Spectra010s/opencode-termux/actions/runs/38055045432>
- Artifact: <https://github.com/Spectra010s/opencode-termux/actions/runs/38055045432/artifacts/11671000530>
- Artifact name: `opencode-2.0.26-android-aarch64-candidate`
- Artifact ZIP size: `97,242,278` bytes; retained for 14 days
- Artifact ZIP SHA-256 reported by GitHub: `27254fc8441b0283fc7daf45272b3c9b2f2c6c53971bd0327dbbddccda58636d`
- Candidate ELF SHA-256 from `SHA256SUMS`: `eeeedf75fb74b1630f30a5723f4249f308aab29ec5dddb321865d3e399f236d0`
- ELF: ARM aarch64 PIE, interpreter `/system/bin/linker64`
- CI runtime probe: `skipped(no-aarch64)` as expected on the x86_64 runner

On-device Termux verification completed after downloading the artifact:

- `sha256sum -c SHA256SUMS`: all three artifact files passed
- Candidate SHA-256: `eeeedf75fb74b1630f30a5723f4249f308aab29ec5dddb321865d3e399f236d0`
- ELF interpreter: `/system/bin/linker64`; Android API 28; direct dependencies are `libc.so`, `libm.so`, and `libdl.so`
- `--version`: `opencode v2.0.26`
- PTY smoke: rendered successfully, no panic or crash, embedded OpenTUI guard passed (`clamp=2`, `csel_vs=4`)
- Preserved at `$HOME/.opencode/bin/opencode-v2.0.26-native`; the existing `opencode`, `opencode-v2-test`, and `opencode.bak` files were not changed
- Remaining release gate: interactive testing with the user's normal provider authentication and a harmless real prompt

Latest known failed run (historical): <https://github.com/Spectra010s/opencode-termux/actions/runs/38054798108>

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

Do not publish a GitHub release yet. Integrity, native execution, TUI rendering, and the embedded guard have passed on-device. Test provider authentication, a harmless real prompt, normal interactive input, and clean exit using the versioned candidate before describing the build as stable or replacing the active binary.

## Local side effects already disclosed

Static inspection used `npm pack`; it did not install the package globally or execute its contents. Audit downloads remain under `/data/data/com.termux/files/usr/tmp/opencode-audit-2.0.26`, and the sparse OpenTUI checkout remains under `/data/data/com.termux/files/usr/tmp/opentui-audit-0.5.17`. Do not delete them without telling the user.
