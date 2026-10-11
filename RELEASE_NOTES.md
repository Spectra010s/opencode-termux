# OpenCode 2.0.26 for Termux

OpenCode v2 now runs directly in Termux on Android ARM64—no PRoot or glibc setup needed. The terminal interface, sign-in, sessions, and a real AI conversation worked on the test phone.

Install in Termux:

```sh
curl -fsSLO https://github.com/Spectra010s/opencode-termux/releases/download/v2.0.26-termux.1/install.sh
sh install.sh
```

Then run `opencode`. The installer downloads the compressed build, checks its SHA-256, and tells you what to do if the command is not on your `PATH`.

This is an **early release** for Android ARM64 (Android 9 or newer). It has been tested on one Android 14 phone, not across many devices. If you are switching from v1, back up your OpenCode data first because v2 can update the session database. Please report any startup or session problems in this repository's issues.
