#!/usr/bin/env bash
# Build a Bun-1.4.0-compatible graph from pinned OpenCode 2.0.26 source on CI,
# then transplant that graph onto the verified Android/Bionic Bun 1.4.0 base.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
: "${OPENCODE_VERSION:?OPENCODE_VERSION must be set}"
test "$OPENCODE_VERSION" = 2.0.26

readarray -t locked < <(python3 - <<'PY'
import json
lock = json.load(open("tools/supply-chain-lock.json", encoding="utf-8"))
oc = lock["opencode"]["2.0.26"]
host = lock["source_build_bun_1_4_0"]
android = lock["android_bun"]["1.4.0"]
for value in (oc["commit"], oc["source_sha256"], host["linux_x64_archive_sha256"],
              host["linux_aarch64_archive_sha256"], android["archive_sha256"]):
    print(value)
PY
)
test "${#locked[@]}" -eq 5
commit="${locked[0]}"

mkdir -p work/source-bun140 artifacts/transplant/android-bun
for arch in x64 aarch64; do
  case "$arch" in
    x64) expected="${locked[2]}" ;;
    aarch64) expected="${locked[3]}" ;;
  esac
  archive="work/source-bun140/bun-linux-$arch.zip"
  curl -fsSLo "$archive" "https://github.com/oven-sh/bun/releases/download/bun-v1.4.0/bun-linux-$arch.zip"
  echo "$expected  $archive" | sha256sum -c -
  unzip -oq "$archive" -d "work/source-bun140/$arch"
done
host_bun="$ROOT/work/source-bun140/x64/bun-linux-x64/bun"
target_bun="$ROOT/work/source-bun140/aarch64/bun-linux-aarch64/bun"
test -x "$host_bun"
test -x "$target_bun"
test "$("$host_bun" --version)" = 1.4.0

android_zip="artifacts/transplant/android-bun/bun-1.4.0.zip"
curl -fsSLo "$android_zip" https://github.com/oven-sh/bun/releases/download/bun-v1.4.0/bun-linux-aarch64-android.zip
echo "${locked[4]}  $android_zip" | sha256sum -c -
cp tools/transplant/config/bun-bind-source-1.4.0.json tools/transplant/config/bun-bind.json

source_tar="work/source-bun140/opencode-$OPENCODE_VERSION-source.tar.gz"
curl -fsSLo "$source_tar" "https://codeload.github.com/anomalyco/opencode/tar.gz/$commit"
echo "${locked[1]}  $source_tar" | sha256sum -c -
src="$ROOT/work/source-bun140/opencode"
mkdir -p "$src"
tar -xzf "$source_tar" -C "$src" --strip-components=1
python3 tools/patch-opencode-source-bun140.py "$src"

cd "$src"
"$host_bun" install --frozen-lockfile --ignore-scripts --os=linux --cpu='*'
cd "$src/packages/cli"
BUN_SOURCE_TARGET_ELF="$target_bun" "$host_bun" script/build.ts --target=opencode-linux-arm64 --skip-install
compiled="$src/packages/cli/dist/cli-linux-arm64/bin/opencode"
test -s "$compiled"
mkdir -p "$ROOT/work/source-bun140/package/bin"
cp "$compiled" "$ROOT/work/source-bun140/package/bin/opencode"
cd "$ROOT/work/source-bun140"
tar -czf "opencode-$OPENCODE_VERSION-source-bun140.tgz" package
cd "$ROOT"

python3 tools/transplant/transplant.py all \
  --ver "$OPENCODE_VERSION" \
  --tgz "work/source-bun140/opencode-$OPENCODE_VERSION-source-bun140.tgz" \
  --no-execve
python3 - <<'PY'
import json
from pathlib import Path
out = Path("artifacts/transplant/2.0.26")
report = json.loads((out / "report.json").read_text(encoding="utf-8"))
assert report["steps"]["swap"]["status"] == "ok", report["steps"].get("swap")
product = out / "opencode-native-tui"
assert product.is_file() and product.stat().st_size > 50_000_000
PY
