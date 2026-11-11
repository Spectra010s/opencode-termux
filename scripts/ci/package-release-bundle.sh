#!/usr/bin/env bash
# Package a verified runtime bundle as the release artefacts:
#
#   opencode_<version>-1_aarch64.deb                  APT install
#   opencode-<version>-android-aarch64-bundle.tar.gz  curl installer
#
# The deb installs under the Termux prefix and declares the runtime
# dependencies; the tarball keeps the @TERMUX_PREFIX@ placeholder so the
# standalone installer can target any prefix.
#
# Usage: package-release-bundle.sh STAGED_DIR VERSION OUTPUT_DIR
#
# STAGED_DIR is the artifacts/bundle/<version> tree from
# scripts/ci/build-opencode-bundle.sh.
set -euo pipefail

[[ $# -eq 3 ]] || { echo "Usage: $0 STAGED_DIR VERSION OUTPUT_DIR" >&2; exit 2; }
staged=$1
version=$2
output_dir=$3

TERMUX_PREFIX="/data/data/com.termux/files/usr"

for tool in cp dpkg-deb install mktemp stat tar gzip sed; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing command: $tool" >&2; exit 1; }
done
[[ -d "$staged/lib" ]] || { echo "Missing staged bundle: $staged/lib" >&2; exit 1; }
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid version: $version" >&2; exit 1; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$output_dir"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

# ---- APT package -----------------------------------------------------------
deb_tree="$work/deb"
bash "$root/scripts/materialize-bundle.sh" "$TERMUX_PREFIX" "$staged" "$deb_tree$TERMUX_PREFIX" "$version"
mkdir -p "$deb_tree/DEBIAN"
installed_kib=$(du -sk "$deb_tree$TERMUX_PREFIX" | awk '{print $1}')
cat > "$deb_tree/DEBIAN/control" <<EOF
Package: opencode
Version: $version-1
Architecture: aarch64
Maintainer: Spectra010s <Spectra010s@users.noreply.github.com>
Homepage: https://github.com/Spectra010s/opencode-termux
Section: utils
Priority: optional
Installed-Size: $installed_kib
Depends: bun (>= 1.4.4), libc++, ripgrep
Recommends: git
Conflicts: opencode-wrapper, opencode-native, opencode-compressed
Description: OpenCode for Termux on Android aarch64
 The OpenCode coding agent packaged for Termux. Runs on the Termux \`bun\`
 runtime and requires Android API 28 or newer.
EOF

package="$output_dir/opencode_${version}-1_aarch64.deb"
dpkg-deb --build --root-owner-group -Zxz "$deb_tree" "$package"
test "$(dpkg-deb --field "$package" Package)" = opencode
test "$(dpkg-deb --field "$package" Version)" = "$version-1"
dpkg-deb --field "$package" Depends | grep -q 'bun'
rm -rf "$work/verify"
dpkg-deb --extract "$package" "$work/verify"
test -x "$work/verify$TERMUX_PREFIX/bin/opencode"
test -f "$work/verify$TERMUX_PREFIX/lib/opencode/index.js"
cmp -s "$staged/lib/index.js" "$work/verify$TERMUX_PREFIX/lib/opencode/index.js" && {
  echo "install-path substitution did not run" >&2
  exit 1
}
diff -rq "$staged/lib" "$work/verify$TERMUX_PREFIX/lib/opencode" >/dev/null || true
echo "Created $package"

# ---- curl installer tarball ------------------------------------------------
# Layout mirrors the prefix: bin/opencode + lib/opencode/. The launcher keeps
# the placeholder version filled in; asset paths keep @TERMUX_PREFIX@.
tarball="$output_dir/opencode-$version-android-aarch64-bundle.tar.gz"
stage="$work/tar"
mkdir -p "$stage/bin" "$stage/lib/opencode"
cp -a "$staged/lib/." "$stage/lib/opencode/"
sed "s|__OPENCODE_VERSION__|$version|g" "$root/packing/launcher/opencode" > "$stage/bin/opencode"
chmod 0755 "$stage/bin/opencode"
tar -C "$stage" --owner=0 --group=0 --numeric-owner -czf "$tarball" bin lib
echo "Created $tarball"
