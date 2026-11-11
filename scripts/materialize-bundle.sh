#!/bin/sh
# Materialize a built runtime bundle for one install prefix.
#
# The bundle is built with `@TERMUX_PREFIX@` as its asset root so one artefact
# serves Termux and any fork with a different $PREFIX. This rewrites that
# placeholder and installs the launcher.
#
# Usage: materialize-bundle.sh PREFIX STAGED_DIR DEST_DIR VERSION
#
#   STAGED_DIR   directory containing lib/ from build-opencode-bundle.sh
#   DEST_DIR     receives bin/opencode and lib/opencode/
set -eu

[ "$#" -eq 4 ] || { echo "Usage: $0 PREFIX STAGED_DIR DEST_DIR VERSION" >&2; exit 2; }
prefix=$1
staged=$2
dest=$3
version=$4

case $version in
  *[!0-9.]*|.*|*..*|*.) echo "Invalid version: $version" >&2; exit 2 ;;
esac
[ -d "$staged/lib" ] || { echo "Missing staged bundle: $staged/lib" >&2; exit 1; }

here=$(cd "$(dirname "$0")" && pwd)
launcher="$here/../packing/launcher/opencode"
[ -f "$launcher" ] || { echo "Missing launcher template: $launcher" >&2; exit 1; }

rm -rf "$dest/lib/opencode"
mkdir -p "$dest/lib/opencode" "$dest/bin"
cp -a "$staged/lib/." "$dest/lib/opencode/"

find "$dest/lib/opencode" -type f -name '*.js' -exec \
  sed -i "s|@TERMUX_PREFIX@/lib/opencode|$prefix/lib/opencode|g" {} +

if grep -rlq '@TERMUX_PREFIX@' "$dest/lib/opencode"; then
  echo "Unsubstituted @TERMUX_PREFIX@ left in the bundle" >&2
  exit 1
fi

sed "s|__OPENCODE_VERSION__|$version|g" "$launcher" > "$dest/bin/opencode"
chmod 0755 "$dest/bin/opencode"
