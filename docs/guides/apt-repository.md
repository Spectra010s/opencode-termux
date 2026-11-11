# OpenCode APT source for Termux

The native Android release workflow publishes `opencode_<version>-1_aarch64.deb`,
`Packages`, `Packages.gz`, and signed `Release` metadata alongside the verified binary archive. These
assets form a flat APT source hosted by this project's latest GitHub release.
It is independent of the official Termux package repository and of other
OpenCode Termux projects.

Add the source in Termux:

```sh
curl -fsSL https://raw.githubusercontent.com/Spectra010s/opencode-termux/native-android/setup-apt.sh | sh
apt-cache policy opencode
pkg install opencode
```

The setup script installs this project's public signing key, adds the source
to Termux, and refreshes APT's package index. It does not install OpenCode;
`pkg install opencode` does that.

APT verifies the repository's signed `InRelease` file using only the installed
key (`signed-by=`). Its fingerprint is
`0E5A71B65EFC2AFFC6096154A2378F99E71DE07E`. The setup script checks the
downloaded public key against a pinned SHA-256 digest before installing it.
The release also carries SHA-256 checksums for the `.deb` and index files.

`pkg` is a wrapper around Termux's APT, so `pkg install opencode` uses the same
package database. Since 2.2.7 both the APT package and the curl installer use
`$PREFIX/bin/opencode` and `$PREFIX/lib/opencode`, so ownership is what
separates them, not the path:

```sh
command -v opencode
dpkg -S "$PREFIX/bin/opencode"
```

If that prints `opencode: $PREFIX/bin/opencode`, APT owns the install and
`opencode upgrade` will refuse to touch it. If it fails with "no path found
matching pattern", the current launcher came from the curl installer; remove
it before switching:

```sh
rm -f "$PREFIX/bin/opencode"
rm -rf "$PREFIX/lib/opencode"
hash -r
pkg install opencode
```

A 2.2.6-era install at `~/.local/bin/opencode` is a standalone binary with no
`lib/opencode` directory; remove it too, or the `PATH` decides which one runs.

For later releases, `apt update && apt install --only-upgrade opencode` uses
this source. To remove it, delete the source file at
`$PREFIX/etc/apt/sources.list.d/opencode-termux.list` and key at
`$PREFIX/etc/apt/keyrings/opencode-termux.gpg`, then run `apt update`.
