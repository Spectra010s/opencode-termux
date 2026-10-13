#!/usr/bin/env bash
# Build a Bun-1.4.0-compatible graph from pinned OpenCode source on CI,
# then transplant that graph onto the verified Android/Bionic Bun 1.4.0 base.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
: "${OPENCODE_VERSION:?OPENCODE_VERSION must be set}"
test "$OPENCODE_VERSION" = 2.0.28

readarray -t locked < <(python3 - <<'PY'
import json
lock = json.load(open("tools/supply-chain-lock.json", encoding="utf-8"))
oc = lock["opencode"]["2.0.28"]
host = lock["source_build_bun_1_4_0"]
android = lock["android_bun"]["1.4.0"]
for value in (oc["commit"], host["linux_x64_archive_sha256"],
              host["linux_aarch64_archive_sha256"], android["archive_sha256"]):
    print(value)
PY
)
test "${#locked[@]}" -eq 4
commit="${locked[0]}"

mkdir -p work/source-bun140 artifacts/transplant/android-bun
for arch in x64 aarch64; do
  case "$arch" in
    x64) expected="${locked[1]}" ;;
    aarch64) expected="${locked[2]}" ;;
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
echo "${locked[3]}  $android_zip" | sha256sum -c -
cp tools/transplant/config/bun-bind-source-1.4.0.json tools/transplant/config/bun-bind.json

src="$ROOT/work/source-bun140/opencode"
mkdir -p "$src"
git -C "$src" init .
git -C "$src" remote add origin https://github.com/anomalyco/opencode.git
git -C "$src" fetch --depth=1 origin "$commit"
git -C "$src" checkout --detach FETCH_HEAD
test "$(git -C "$src" rev-parse HEAD)" = "$commit"
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
out = Path("artifacts/transplant/2.0.28")
report = json.loads((out / "report.json").read_text(encoding="utf-8"))
assert report["steps"]["swap"]["status"] == "ok", report["steps"].get("swap")
product = out / "opencode-native-tui"
assert product.is_file() and product.stat().st_size > 50_000_000
PY
