# OpenCode APT source for Termux

The native Android release workflow publishes `opencode_<version>-1_aarch64.deb`,
`Packages.gz`, and `Release` alongside the verified binary archive. These
assets form a flat APT source hosted by this project's latest GitHub release.
It is independent of the official Termux package repository and of other
OpenCode Termux projects.

After the first release containing those assets is published, add the source
in Termux:

```sh
mkdir -p "$PREFIX/etc/apt/sources.list.d"
printf '%s\n' 'deb [trusted=yes arch=aarch64] https://github.com/Spectra010s/opencode-termux/releases/latest/download/ ./' > "$PREFIX/etc/apt/sources.list.d/opencode-termux.list"
apt update
apt-cache policy opencode
apt install opencode
```

The source uses `trusted=yes` because it has no APT signing key yet. APT will
trust packages listed by this URL; only add it if you trust this project's
GitHub releases. The release also carries SHA-256 checksums for the `.deb` and
index files.

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
this source. To remove only the source, delete
`$PREFIX/etc/apt/sources.list.d/opencode-termux.list` and run `apt update`.
