# APT source: maintainer runbook

User instructions are in the [README](../../README.md#install-with-apt). This
file is for whoever publishes the source and debugs it.

## What a release carries

`publish-native-android.yml` uploads, per release:

| Asset | Produced by |
|---|---|
| `opencode_<version>-1_aarch64.deb` | `scripts/ci/package-release-bundle.sh` |
| `opencode-<version>-android-aarch64-bundle.tar.gz` | same |
| `Packages`, `Packages.gz` | `tools/gen-packages-index.py` |
| `Release`, `Release.gpg`, `InRelease` | `scripts/ci/write-flat-apt-release.py`, `scripts/ci/sign-apt-index.sh` |
| `SHA256SUMS` | the build workflow, extended with the signed files at publish |
| `supply-chain-lock.json`, `report.json` | the build workflow |

The repository is flat: `setup-apt.sh` writes one `deb [signed-by=…]` line
pointing at `releases/latest/download`, and `Packages` names each deb by
basename only.

## Signing

`apt/opencode-termux.gpg` holds the public key, fingerprint
`0E5A71B65EFC2AFFC6096154A2378F99E71DE07E`. The private key lives in the
`APT_GPG_PRIVATE_KEY` secret. `sign-apt-index.sh` imports it into a throwaway
`GNUPGHOME`, re-exports the public half, and aborts if it does not match the
committed file — so a rotated key cannot silently invalidate existing installs.

Rotating the key means publishing a release that ships a new
`apt/opencode-termux.gpg` and telling users to rerun `setup-apt.sh`; APT will
reject `InRelease` signed by an unknown key until they do.

`setup-apt.sh` verifies the downloaded key against a pinned SHA-256 digest, so
update that digest in the same commit as the key.

## Verify a release by hand

```sh
cd "$(mktemp -d)"
gh release download v2.2.7 -R Spectra010s/opencode-termux
sha256sum -c SHA256SUMS
gpg --show-keys --with-fingerprint apt/opencode-termux.gpg   # 0E5A71B65EFC2AFFC6096154A2378F99E71DE07E
gpg --verify Release.gpg Release
gzip -dc Packages.gz | grep -A4 '^Package: opencode$'
dpkg-deb --field opencode_2.2.7-1_aarch64.deb Depends   # bun (>= 1.4.4), libc++, ripgrep
```

The publish job runs the same checks before it creates the release, so a
failure here means the release is already suspect.

## When APT fails on a device

`NO_PUBKEY <fingerprint>` — the key is missing or was rotated. Rerun
`setup-apt.sh`.

`Hash Sum mismatch` — the `Packages` file and the deb disagree, usually because
a release was replaced. `apt clean && apt update`.

`404` on the deb — `Packages` points at a basename that the release does not
have. Compare `Filename:` in the index with `gh release view`.

A second deploy of the same version, or a version published before its
`Packages` entry was regenerated, both show up as the two errors above. The
build workflow asserts the index names `opencode` and the publish job asserts
`Version: <version>-1`, so check the candidate artifact first.

## Removing the source from a device

```sh
rm -f "$PREFIX/etc/apt/sources.list.d/opencode-termux.list"
rm -f "$PREFIX/etc/apt/keyrings/opencode-termux.gpg"
apt update
```
