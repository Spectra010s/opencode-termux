# Security policy

This repository is a community Termux/Android packaging project for
[OpenCode](https://github.com/anomalyco/opencode). Where to report an issue
depends on where it lives.

## Issues in this packaging

The launcher, installer, CI workflows, `.deb`/tarball contents, the APT source
and its signing key, and the Android native patches are maintained here. Report
them privately through a
[GitHub security advisory](https://github.com/Spectra010s/opencode-termux/security/advisories/new)
on this repository. Please do not open a public issue first.

## Issues in upstream OpenCode

Unmodified OpenCode code, the server API and its plugins belong upstream. Use
[anomalyco/opencode](https://github.com/anomalyco/opencode/issues) for those.

## Verifying what you installed

Every release publishes `SHA256SUMS`, and the APT source signs its index with
`0E5A71B65EFC2AFFC6096154A2378F99E71DE07E`:

```sh
dpkg -S "$PREFIX/bin/opencode"          # package-owned, or the curl installer
sha256sum -c SHA256SUMS                 # in a directory of downloaded assets
apt-key --keyring /dev/null list 2>/dev/null | grep -A1 0E5A71B6
```

A release asset that does not match its checksum means a compromised mirror or a
truncated download. Report it privately, not in the issue tracker.

## Supported versions

Only the most recent published release gets security fixes. Older releases stay
downloadable; they are not patched.
