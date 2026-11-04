#!/usr/bin/env bash
set -euo pipefail

# Package an already verified Android candidate for the flat release APT source.
# Usage: package-release-deb.sh BINARY VERSION OUTPUT_DIR

[[ $# -eq 3 ]] || { echo "Usage: $0 BINARY VERSION OUTPUT_DIR" >&2; exit 2; }
binary=$1
version=$2
output_dir=$3

for tool in cmp dpkg-deb install mktemp stat; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing command: $tool" >&2; exit 1; }
done
[[ -f "$binary" ]] || { echo "Missing candidate binary: $binary" >&2; exit 1; }
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid version: $version" >&2; exit 1; }

mkdir -p "$output_dir"
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT

target="$stage/data/data/com.termux/files/usr/bin/opencode"
install -D -m 0755 "$binary" "$target"
mkdir -p "$stage/DEBIAN"
installed_kib=$(( ($(stat -c %s "$target") + 1023) / 1024 ))
cat > "$stage/DEBIAN/control" <<EOF
Package: opencode
Version: $version-1
Architecture: aarch64
Maintainer: Spectra010s <Spectra010s@users.noreply.github.com>
Homepage: https://github.com/Spectra010s/opencode-termux
Section: utils
Priority: optional
Installed-Size: $installed_kib
Conflicts: opencode-wrapper, opencode-compressed
Description: Native OpenCode for Termux on Android aarch64
 OpenCode compiled for Android Bionic, requiring Android API 28 or newer.
EOF

package="$output_dir/opencode_${version}-1_aarch64.deb"
dpkg-deb --build --root-owner-group -Zxz "$stage" "$package"
test "$(dpkg-deb --field "$package" Package)" = opencode
test "$(dpkg-deb --field "$package" Version)" = "$version-1"
test "$(dpkg-deb --field "$package" Architecture)" = aarch64
dpkg-deb --extract "$package" "$stage/verify"
cmp -s "$binary" "$stage/verify/data/data/com.termux/files/usr/bin/opencode"
echo "Created $package"
