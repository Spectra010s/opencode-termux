# APT source: how it is set up

User-facing install steps are in the [root README](../../README.md#install-with-apt).
This document explains what the repository is and how CI produces it.

## Shape of the repository

There is no `dists/` tree and no `pool/`. The APT source is the GitHub Releases
asset directory for the latest release:

```
https://github.com/Spectra010s/opencode-termux/releases/latest/download/
```

`setup-apt.sh` writes one source line:

```
deb [signed-by=$PREFIX/etc/apt/keyrings/opencode-termux.gpg arch=aarch64] \
  https://github.com/Spectra010s/opencode-termux/releases/latest/download/ ./
```

The key is scoped to this one source, so it cannot validate any other repo. The
index names each deb by basename only, which matches the flat URL layout.

## What a release carries

`publish-native-android.yml` uploads these assets per tag:

| Asset | Produced by |
|---|---|
| `opencode_<version>-<revision>_aarch64.deb` | `scripts/ci/package-release-bundle.sh` |
| `opencode-<version>-android-aarch64-bundle.tar.gz` | same |
| `Packages`, `Packages.gz` | `scripts/gen-packages-index.py`, `scripts/ci/write-flat-apt-release.py` |
| `Release`, `Release.gpg`, `InRelease` | `scripts/ci/write-flat-apt-release.py`, `scripts/ci/sign-apt-index.sh` |
| `SHA256SUMS` | build workflow, extended with the signed files at publish |
| `supply-chain-lock.json`, `report.json` | build workflow |

## How the index is built

1. `gen-packages-index.py dist/Packages.gz dist` scans the staged `.deb` files.
   It reads each package's `control` metadata directly from `control.tar.*`
   (Termux dpkg has no `dpkg-scanpackages`), and writes RFC822 stanzas with
   `Package`, `Version`, dependency fields, `Filename` (basename only), `Size`
   and `SHA256`.
2. `write-flat-apt-release.py dist` decompresses `Packages.gz` to plain
   `Packages` and writes `Release` with `Origin`, `Label`, `Suite`,
   `Architectures: aarch64` and SHA-256/size entries for both index forms.
3. `sign-apt-index.sh dist/Release apt/opencode-termux.gpg dist` imports the
   private key from the `APT_GPG_PRIVATE_KEY` secret into a throwaway
   `GNUPGHOME`, re-exports the public half and aborts unless it matches the
   committed key. It then writes `InRelease` (clearsigned) and `Release.gpg`
   (detached), and verifies both with `gpgv`.
4. The publish job verifies the candidate, appends the signed files to
   `SHA256SUMS`, and creates the release with `--target $GITHUB_SHA`. It
   refuses to overwrite an existing tag.

Only the newest release is indexed. A rebuild of the same upstream version
bumps `package_revision` in `supply-chain-lock.json` and is tagged
`v<version>-<revision>`; the Debian version rises with it.

## Signing key

`apt/opencode-termux.gpg` is the committed public key, fingerprint:

```
0E5A71B65EFC2AFFC6096154A2378F99E71DE07E
```

The private key exists only in the `APT_GPG_PRIVATE_KEY` GitHub secret. A key
rotation ships a new `apt/opencode-termux.gpg` in a release and requires users
to rerun `setup-apt.sh`; APT rejects `InRelease` signed by an unknown key until
they do. `setup-apt.sh` pins a SHA-256 digest for the downloaded key, so that
digest and the key file must change in the same commit.

## Device setup

`setup-apt.sh` runs only inside Termux on aarch64. It:

1. checks `PREFIX`, `apt-get`, `curl`, `dpkg`, `install`, `mktemp`, `sha256sum`
   and the device architecture;
2. downloads `apt/opencode-termux.gpg` from the `native-android` branch and
   verifies it against the digest pinned in the script;
3. installs it to `$PREFIX/etc/apt/keyrings/opencode-termux.gpg`;
4. writes `$PREFIX/etc/apt/sources.list.d/opencode-termux.list` with the
   `signed-by` source line above, refusing to overwrite a different entry;
5. runs `apt-get update` scoped to that one source file.

Then `pkg install opencode` works like any other Termux package.

## Verify a release by hand

```sh
cd "$(mktemp -d)"
gh release download <tag> -R Spectra010s/opencode-termux
sha256sum -c SHA256SUMS
gpg --show-keys --with-fingerprint apt/opencode-termux.gpg
gpg --verify Release.gpg Release
gzip -dc Packages.gz | grep -A4 '^Package: opencode$'
dpkg-deb --field opencode_<version>-<revision>_aarch64.deb Depends
```

The publish job runs the same checks before creating the release, so a failure
here means the release is already suspect.

## When APT fails on a device

`NO_PUBKEY <fingerprint>` — the key is missing or was rotated. Rerun `setup-apt.sh`.

`Hash Sum mismatch` — `Packages` and the deb disagree, usually because a release
was replaced. `apt clean && pkg update`.

`404` on the deb — `Packages` names a basename the release does not have.
Compare `Filename:` in the index with `gh release view`.

A second deploy of the same version, or a version published before its
`Packages` entry was regenerated, shows up as those two errors. The build
workflow asserts the index names `opencode`, and the publish job asserts
`Version: <version>-<revision>`, so check the build artifact first.

## Removing the source from a device

```sh
rm -f "$PREFIX/etc/apt/sources.list.d/opencode-termux.list"
rm -f "$PREFIX/etc/apt/keyrings/opencode-termux.gpg"
pkg update
```
