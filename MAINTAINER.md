# Maintainer

OpenCode Termux is maintained by **Adeloye Adetayo** (GitHub:
[Spectra010s](https://github.com/Spectra010s)) as the Termux / Android arm64
packaging maintainer.

This is not a fork of OpenCode. The source comes from
[anomalyco/opencode](https://github.com/anomalyco/opencode) at the commit pinned
in `tools/supply-chain-lock.json`, and this repository carries only the Android
compatibility delta needed to run it on Termux: the bionic native builds, the
package target, the launcher, and the release pipeline. The repository was
derived from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux).

## Scope

In scope:

- bionic builds of every native library the CLI loads (OpenTUI, `bun-pty`,
  `@parcel/watcher`)
- the `$PREFIX/lib/opencode` bundle plus its `$PREFIX/bin/opencode` launcher
- packaging and release: the tarball, the `.deb`, the signed APT source, the
  installer, and the CI workflows that produce them
- keeping the pins in `tools/supply-chain-lock.json` current

Out of scope:

- changes that belong upstream — file those on
  [anomalyco/opencode](https://github.com/anomalyco/opencode/issues)
- 32-bit ARM and x86 targets

## Reporting

| Channel | Where |
|---|---|
| Termux/Android bugs, packaging, PRs | [Spectra010s/opencode-termux](https://github.com/Spectra010s/opencode-termux/issues) |
| Generic OpenCode bugs | [anomalyco/opencode](https://github.com/anomalyco/opencode/issues) |
| Security disclosures | [`SECURITY.md`](SECURITY.md) — private advisory |
| Contact | [spectra010s.com](https://spectra010s.com) |
