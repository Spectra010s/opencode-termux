#!/bin/sh
set -eu

prefix=${PREFIX:-/data/data/com.termux/files/usr}
if [ "$prefix" != /data/data/com.termux/files/usr ] || ! command -v apt-get >/dev/null 2>&1; then
  echo 'Run this script inside Termux.' >&2
  exit 1
fi
for tool in curl dpkg install mktemp sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Missing command: $tool" >&2; exit 1; }
done
if [ "$(dpkg --print-architecture)" != aarch64 ]; then
  echo 'The OpenCode APT package currently supports only Termux aarch64.' >&2
  exit 1
fi

source_dir="$prefix/etc/apt/sources.list.d"
source_file="$source_dir/opencode-termux.list"
key_dir="$prefix/etc/apt/keyrings"
key_file="$key_dir/opencode-termux.gpg"
key_url='https://raw.githubusercontent.com/Spectra010s/opencode-termux/native-android/apt/opencode-termux.gpg'
key_sha256='77eaf966ce2310e402201e5aa217dc34652ab4622b4476886ad5306305bb6687'
source_line="deb [signed-by=$key_file arch=aarch64] https://github.com/Spectra010s/opencode-termux/releases/latest/download/ ./"

mkdir -p "$source_dir" "$key_dir"
if [ -e "$source_file" ]; then
  existing=$(cat "$source_file")
  if [ "$existing" != "$source_line" ]; then
    echo "Existing APT source differs: $source_file" >&2
    exit 1
  fi
fi

key_tmp=$(mktemp "$key_dir/.opencode-termux.gpg.XXXXXX")
trap 'rm -f -- "$key_tmp"' EXIT HUP INT TERM
curl -fsSL "$key_url" -o "$key_tmp"
actual_sha256=$(sha256sum "$key_tmp")
actual_sha256=${actual_sha256%% *}
if [ "$actual_sha256" != "$key_sha256" ]; then
  echo 'APT signing key checksum mismatch' >&2
  exit 1
fi
install -m 644 "$key_tmp" "$key_file"
printf '%s\n' "$source_line" > "$source_file"

apt-get update
echo 'OpenCode APT source is ready. Install with: pkg install opencode'
