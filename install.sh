#!/bin/sh
set -eu

release_tag=v2.0.28
asset=opencode-2.0.28-android-aarch64-source-bun140
archive="$asset.tar.gz"
base_url="https://github.com/Spectra010s/opencode-termux/releases/download/$release_tag"
destination="$HOME/.local/bin/opencode"

for tool in curl sha256sum tar mktemp install mv uname getprop awk; do
  command -v "$tool" >/dev/null 2>&1 || { printf 'Missing command: %s\n' "$tool" >&2; exit 1; }
done

[ "$(uname -m)" = aarch64 ] || { echo 'This release requires Android aarch64.' >&2; exit 1; }
android_api=$(getprop ro.build.version.sdk)
case "$android_api" in
  ''|*[!0-9]*) echo 'Could not detect Android API level.' >&2; exit 1 ;;
esac
[ "$android_api" -ge 28 ] || { echo 'This release requires Android API 28 or newer.' >&2; exit 1; }

temporary_dir=$(mktemp -d)
trap 'rm -rf -- "$temporary_dir"' EXIT HUP INT TERM

curl -fL --retry 3 -o "$temporary_dir/SHA256SUMS" "$base_url/SHA256SUMS"
curl -fL --retry 3 -o "$temporary_dir/$archive" "$base_url/$archive"
checksum_line=$(awk -v name="$archive" '$2 == name && length($1) == 64 { print }' "$temporary_dir/SHA256SUMS")
[ -n "$checksum_line" ] || { echo 'Release checksum for archive is missing.' >&2; exit 1; }
[ "$(printf '%s\n' "$checksum_line" | awk 'END { print NR }')" -eq 1 ] || { echo 'Release archive checksum is ambiguous.' >&2; exit 1; }
printf '%s\n' "$checksum_line" | (cd "$temporary_dir" && sha256sum -c -)

tar -xzf "$temporary_dir/$archive" -C "$temporary_dir" "$asset"
checksum_line=$(awk -v name="$asset" '$2 == name && length($1) == 64 { print }' "$temporary_dir/SHA256SUMS")
[ -n "$checksum_line" ] || { echo 'Release checksum for binary is missing.' >&2; exit 1; }
[ "$(printf '%s\n' "$checksum_line" | awk 'END { print NR }')" -eq 1 ] || { echo 'Release binary checksum is ambiguous.' >&2; exit 1; }
printf '%s\n' "$checksum_line" | (cd "$temporary_dir" && sha256sum -c -)

mkdir -p "$HOME/.local/bin"
install -m 755 "$temporary_dir/$asset" "$destination.new.$$"
mv -f "$destination.new.$$" "$destination"
printf 'Installed: %s\n' "$destination"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) printf 'Run: opencode\n' ;;
  *)
    printf 'Run now: %s\n' "$destination"
    printf 'To add it to PATH in your shell, add this line to ~/.bashrc (or your shell startup file):\n'
    printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    ;;
esac
