#!/usr/bin/env bash
# Build a module graph from pinned OpenCode source, then graft it onto the
# pinned Android/Bionic Bun base.
#
# Nothing here pins a version: the OpenCode version comes from
# tools/supply-chain-lock.json ("current" or $OPENCODE_VERSION), its Bun version
# from the same entry, and the Android base from tools/transplant/config/
# bun-bind.json.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

: "${OPENCODE_VERSION:=$(python3 tools/ocver.py current)}"
BUN_VERSION="$(python3 tools/ocver.py field bun_version "$OPENCODE_VERSION")"
BIND_TARGET="$(python3 -c 'import json;print(json.load(open("tools/transplant/config/bun-bind.json"))["target"])')"
test "$BIND_TARGET" = "$BUN_VERSION" || {
  echo "bun-bind.json targets $BIND_TARGET but opencode $OPENCODE_VERSION needs $BUN_VERSION" >&2
  exit 1
}

readarray -t locked < <(python3 - "$OPENCODE_VERSION" "$BUN_VERSION" <<'PY'
import json
import sys

version, bun_version = sys.argv[1], sys.argv[2]
lock = json.load(open("tools/supply-chain-lock.json", encoding="utf-8"))
opencode = lock["opencode"][version]
host = lock["source_build_bun_" + bun_version.replace(".", "_")]
android = lock["android_bun"][bun_version]
for value in (opencode["commit"], host["linux_x64_archive_sha256"], android["archive_sha256"]):
    print(value)
PY
)
test "${#locked[@]}" -eq 3
commit="${locked[0]}"

work="work/source-bun/$BUN_VERSION"
mkdir -p "$work" artifacts/transplant/android-bun

host_zip="$work/bun-linux-x64.zip"
curl -fsSLo "$host_zip" "https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-x64.zip"
echo "${locked[1]}  $host_zip" | sha256sum -c -
unzip -oq "$host_zip" -d "$work/host"
host_bun="$work/host/bun-linux-x64/bun"
test -x "$host_bun"
test "$("$host_bun" --version)" = "$BUN_VERSION"

target_bun="$work/bun-linux-aarch64-android/bun"
if [ ! -x "$target_bun" ]; then
  android_zip="artifacts/transplant/android-bun/bun-$BUN_VERSION.zip"
  curl -fsSLo "$android_zip" "https://github.com/oven-sh/bun/releases/download/bun-v$BUN_VERSION/bun-linux-aarch64-android.zip"
  echo "${locked[2]}  $android_zip" | sha256sum -c -
  unzip -oq "$android_zip" -d "$work"
fi
test -x "$target_bun"

src="$work/opencode"
if [ ! -d "$src/.git" ]; then
  mkdir -p "$src"
  git -C "$src" init .
  git -C "$src" remote add origin https://github.com/anomalyco/opencode.git
  git -C "$src" fetch --depth=1 origin "$commit"
  git -C "$src" checkout --detach FETCH_HEAD
fi
test "$(git -C "$src" rev-parse HEAD)" = "$commit"
OPENCODE_BUN_VERSION="$BUN_VERSION" python3 tools/patch-opencode-source.py "$src"

cd "$src"
"$host_bun" install --frozen-lockfile --ignore-scripts --os=linux --cpu='*'
cd "$src/packages/cli"
OPENCODE_CHANNEL=latest OPENCODE_VERSION="$OPENCODE_VERSION" \
BUN_SOURCE_TARGET_ELF="$target_bun" \
  "$host_bun" script/build.ts --target=opencode-linux-arm64 --skip-install
compiled="$src/packages/cli/dist/cli-linux-arm64/bin/opencode"
test -s "$compiled"
cd "$ROOT"

mkdir -p "$work/package/bin"
cp "$compiled" "$work/package/bin/opencode"
tgz="$ROOT/$work/opencode-$OPENCODE_VERSION-source.tgz"
tar -C "$work" -czf "$tgz" package

python3 tools/transplant/transplant.py all \
  --ver "$OPENCODE_VERSION" \
  --tgz "$tgz" \
  --no-execve
python3 - "$OPENCODE_VERSION" <<'PY'
import json
import sys
from pathlib import Path

out = Path("artifacts/transplant") / sys.argv[1]
report = json.loads((out / "report.json").read_text(encoding="utf-8"))
assert report["steps"]["swap"]["status"] == "ok", report["steps"].get("swap")
product = out / "opencode-native-tui"
assert product.is_file() and product.stat().st_size > 50_000_000
PY
