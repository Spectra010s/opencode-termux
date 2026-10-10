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
- Bun Android `1.4.2` zip SHA-256: `a1c7e2983f1bb65146beb256a4d72449f23042412bc2cf278aa6397ba27e0274`
- Bun extracted ELF SHA-256: `f2970336bfccf36e4e8a408b25c627122f210e941672f184198c31f4dbd377a0`
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

On-device Termux verification of the first artifact found a runtime failure:

- `sha256sum -c SHA256SUMS`: all three artifact files passed
- Candidate SHA-256: `eeeedf75fb74b1630f30a5723f4249f308aab29ec5dddb321865d3e399f236d0`
- ELF interpreter: `/system/bin/linker64`; Android API 28; direct dependencies are `libc.so`, `libm.so`, and `libdl.so`
- `--version`: `opencode v2.0.26`
- PTY initially rendered and the embedded OpenTUI guard passed (`clamp=2`, `csel_vs=4`), but the old smoke gate incorrectly ignored the early nonzero exit
- Normal startup failed with `SyntaxError: Unexpected identifier 'are'` while Bun 1.4.0 tried to parse `/$bunfs/root/system-cvb7jtx8.txt` as JavaScript
- OpenCode 2.0.26's pinned source and official publish workflow specify Bun 1.4.2; the first candidate incorrectly used Android Bun 1.4.0
- The replacement build must use the verified Bun 1.4.2 Android archive (`a1c7e298...`) and ELF (`f2970336...`), and the strengthened smoke gate must reject server exits, syntax errors, and early nonzero exits
- The failed first candidate was moved back to its artifact staging directory; the existing `opencode`, `opencode-v2-test`, and `opencode.bak` files were not changed

Run `38067446529` rebuilt the candidate with the source-matched Bun 1.4.2 runtime and passed CI. Its artifact ID is `11676125245`, artifact ZIP SHA-256 is `3f4da01633e8ad9c6ab15b416c8908ea8f1ac0d14afa03245cfe5953e70ca951`, and candidate SHA-256 is `f72432616c5ec54efdba9ee27f3852b8eb8ecadc16fab9fea8608c9e9772c0e6`.

On-device testing of that second candidate fixed the embedded-text parse error, but the TUI crashed reproducibly with Bun `panic: Segmentation fault at address 0x40`. Extracting the exact embedded OpenTUI library established the cause: it had an undefined `pthread_tryjoin_np` import, and Bionic rejected `dlopen` because Android does not provide that glibc extension. The candidate remains at `$HOME/.opencode/bin/opencode-v2.0.26-native` only for debugging and must not be promoted.

The current fix patches pinned OpenTUI 0.5.17 so Android uses `std.Thread.join()` after OpenTUI's existing worker-completion flag clears, while other Linux ABIs retain `pthread_tryjoin_np`. CI now rejects any Bionic OpenTUI library that still imports `pthread_tryjoin_np`. The PTY smoke helper also isolates all XDG paths, preventing collisions with the user's real managed service.

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

Do not publish a GitHub release yet. The latest on-device candidate crashes while loading OpenTUI. Rebuild with the Android clipboard-thread patch, verify that the embedded library has no undefined `pthread_tryjoin_np`, then repeat native TUI startup, provider authentication, a harmless real prompt, normal interactive input, and clean exit before describing the build as stable or replacing the active binary.

## Local side effects already disclosed

Static inspection used `npm pack`; it did not install the package globally or execute its contents. Audit downloads remain under `/data/data/com.termux/files/usr/tmp/opencode-audit-2.0.26`, and the sparse OpenTUI checkout remains under `/data/data/com.termux/files/usr/tmp/opentui-audit-0.5.17`. Do not delete them without telling the user.
