#!/usr/bin/env bash
set -euo pipefail

# Read the private key from stdin; publish only the signed Release files.
[[ $# -eq 3 ]] || { echo 'Usage: sign-apt-index.sh RELEASE PUBLIC_KEY OUTPUT_DIR' >&2; exit 2; }
release=$1
public_key=$2
output_dir=$3
[[ -s "$release" && -s "$public_key" ]] || { echo 'Missing Release or public key' >&2; exit 1; }
mkdir -p "$output_dir"

gnupg_home=$(mktemp -d)
trap 'rm -rf -- "$gnupg_home"' EXIT
chmod 700 "$gnupg_home"
gpg --homedir "$gnupg_home" --batch --import >/dev/null 2>&1
gpg --homedir "$gnupg_home" --batch --export > "$gnupg_home/public.gpg"
cmp -s "$gnupg_home/public.gpg" "$public_key" || {
  echo 'Signing key does not match the committed APT public key' >&2
  exit 1
}

gpg --homedir "$gnupg_home" --batch --yes --pinentry-mode loopback \
  --clearsign --output "$output_dir/InRelease" "$release"
gpg --homedir "$gnupg_home" --batch --yes --pinentry-mode loopback \
  --detach-sign --output "$output_dir/Release.gpg" "$release"
gpgv --keyring "$public_key" "$output_dir/InRelease" >/dev/null
gpgv --keyring "$public_key" "$output_dir/Release.gpg" "$release" >/dev/null
