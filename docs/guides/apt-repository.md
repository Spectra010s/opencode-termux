# OpenCode APT source for Termux

The native Android release workflow publishes `opencode_<version>-1_aarch64.deb`,
`Packages.gz`, and `Release` alongside the verified binary archive. These
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
package database. The APT package installs to `$PREFIX/bin/opencode`.
The curl installer installs to `~/.local/bin/opencode` instead. Check which
one your shell starts:

```sh
command -v opencode
dpkg -S "$PREFIX/bin/opencode"
```

If the command path is `~/.local/bin/opencode` and you want to use the APT
package, move that earlier manual installation out of the way:

```sh
mv "$HOME/.local/bin/opencode" "$HOME/.local/bin/opencode.manual-backup"
hash -r
command -v opencode
```

For later releases, `apt update && apt install --only-upgrade opencode` uses
this source. To remove it, delete the source file at
`$PREFIX/etc/apt/sources.list.d/opencode-termux.list` and key at
`$PREFIX/etc/apt/keyrings/opencode-termux.gpg`, then run `apt update`.
