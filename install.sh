#!/bin/sh
set -eu

repo=Spectra010s/opencode-termux
release_tag=v2.2.7
if [ "$#" -gt 0 ]; then
  [ "$#" -eq 2 ] && [ "$1" = --version ] || { echo 'Usage: install.sh [--version X.Y.Z]' >&2; exit 2; }
  case "$2" in
    *[!0-9.]*|.*|*..*|*.) echo 'Invalid release version.' >&2; exit 2 ;;
  esac
  printf '%s\n' "$2" | awk -F. 'NF == 3 && $1 != "" && $2 != "" && $3 != "" { ok = 1 } END { exit !ok }' || { echo 'Invalid release version.' >&2; exit 2; }
  release_tag=v$2
fi
version=${release_tag#v}

prefix=${PREFIX:-/data/data/com.termux/files/usr}
lib_dir=$prefix/lib/opencode
launcher=$prefix/bin/opencode

for tool in curl sha256sum tar sed mktemp install rm uname getprop awk; do
  command -v "$tool" >/dev/null 2>&1 || { printf 'Missing command: %s\n' "$tool" >&2; exit 1; }
done

asset="opencode-$version-android-aarch64-bundle"
archive="$asset.tar.gz"
base_url="https://github.com/$repo/releases/download/$release_tag"

# 64-bit ARM Android reports aarch64 here; x86, armv7 and 32-bit userspace
# report something else.
[ "$(uname -m)" = aarch64 ] || { echo 'This release requires Android aarch64.' >&2; exit 1; }
android_api=$(getprop ro.build.version.sdk)
case "$android_api" in
  ''|*[!0-9]*) echo 'Could not detect Android API level.' >&2; exit 1 ;;
esac
[ "$android_api" -ge 28 ] || { echo 'This release requires Android API 28 or newer.' >&2; exit 1; }

# bun and ripgrep are real dependencies now (same pair as the deb `Depends`).
missing=
command -v bun >/dev/null 2>&1 || missing="$missing bun"
command -v rg >/dev/null 2>&1 || missing="$missing ripgrep"
if [ -n "$missing" ]; then
  if [ "${OPENCODE_INSTALL_DEPS:-1}" = 0 ] || ! command -v pkg >/dev/null 2>&1; then
    printf 'opencode needs:%s\n' "$missing" >&2
    printf 'Install them with: pkg install%s\n' "$missing" >&2
    exit 1
  fi
  printf 'Installing dependencies:%s\n' "$missing"
  # shellcheck disable=SC2086 # the list is word-split into pkg arguments
  pkg install -y $missing || {
    printf 'Could not install:%s\n' "$missing" >&2
    printf 'Run it yourself: pkg install%s\n' "$missing" >&2
    exit 1
  }
  # pkg can report success while the binary lands somewhere off PATH.
  for tool in bun rg; do
    command -v "$tool" >/dev/null 2>&1 || {
      printf 'Installed but not on PATH: %s\n' "$tool" >&2
      exit 1
    }
  done
fi

if command -v dpkg-query >/dev/null 2>&1 &&
  dpkg-query -S "$launcher" 2>/dev/null | grep -q '^opencode:'; then
  echo 'opencode is installed as a package; upgrade it with: pkg upgrade opencode' >&2
  exit 1
fi

temporary_dir=$(mktemp -d)
trap 'rm -rf -- "$temporary_dir"' EXIT HUP INT TERM

curl -fL --retry 3 -o "$temporary_dir/SHA256SUMS" "$base_url/SHA256SUMS"
curl -fL --retry 3 -o "$temporary_dir/$archive" "$base_url/$archive"
checksum_line=$(awk -v name="$archive" '$2 == name && length($1) == 64 { print }' "$temporary_dir/SHA256SUMS")
[ -n "$checksum_line" ] || { echo 'Release checksum for archive is missing.' >&2; exit 1; }
[ "$(printf '%s\n' "$checksum_line" | awk 'END { print NR }')" -eq 1 ] || { echo 'Release archive checksum is ambiguous.' >&2; exit 1; }
printf '%s\n' "$checksum_line" | (cd "$temporary_dir" && sha256sum -c -)

tar -xzf "$temporary_dir/$archive" -C "$temporary_dir" bin lib

# The bundle is built against @TERMUX_PREFIX@ so one artefact fits every
# Termux prefix; point it at this device's prefix before installing.
find "$temporary_dir/lib" -type f -name '*.js' -exec \
  sed -i "s|@TERMUX_PREFIX@/lib/opencode|$lib_dir|g" {} +
if grep -rlq '@TERMUX_PREFIX@' "$temporary_dir/lib"; then
  echo 'Release bundle contains an unexpected placeholder path.' >&2
  exit 1
fi

mkdir -p "$prefix/lib" "$prefix/bin"
rm -rf "$lib_dir"
mv "$temporary_dir/lib/opencode" "$lib_dir"
install -m 755 "$temporary_dir/bin/opencode" "$launcher.new.$$"
mv -f "$launcher.new.$$" "$launcher"

# 2.2.6 and earlier installed a standalone binary here; two `opencode`
# commands would resolve by PATH order.
legacy=$HOME/.local/bin/opencode
if [ -f "$legacy" ]; then
  rm -f "$legacy"
  printf 'Removed the previous install: %s\n' "$legacy"
fi

printf 'Installed: %s\n' "$launcher"
printf 'Run: opencode\n'
