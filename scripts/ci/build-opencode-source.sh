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

work="$ROOT/work/source-bun/$BUN_VERSION"
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
# bionic tags heap pointers in the top byte; OpenTUI's FFI shim treats
# them as "Pointer exceeds safe integer range" and the TUI refuses to start.
# Patch the installed shim before Bun builds, because build.ts sets
# bytecode:true -- editing the JS inside the compiled ELF afterwards does
# nothing.
python3 "$ROOT/tools/patch-opentui-ffi.py" "$src"
cd "$src/packages/cli"
# Upstream 2.2.x selects the compile target from OPENCODE_TARGET (env), not
# from a --target flag: build.ts compares `targetName(item)` against
# `${binary}-${requestedTarget}`. Without it `targets` is allTargets (12
# entries) and the pinned-ELF guard in tools/patch-opencode-source.py trips on
# the second entry (`unexpected source-build target`). "linux-arm64" resolves
# to `opencode-linux-arm64`, the only target this pipeline ships.
OPENCODE_CHANNEL=latest OPENCODE_VERSION="$OPENCODE_VERSION" \
OPENCODE_TARGET=linux-arm64 \
BUN_SOURCE_TARGET_ELF="$target_bun" \
  "$host_bun" script/build.ts --skip-install
compiled="$src/packages/cli/dist/cli-linux-arm64/bin/opencode"
test -s "$compiled"
# source maps keep the bundled JS readable in the ELF, so this proves the
# pointer mask survived into the build (bytecode:true makes it unpatched at
# runtime otherwise).
grep -aq '0x00ffffffffffffffn' "$compiled" || {
  echo "opentui top-byte pointer mask missing from the compiled ELF" >&2
  exit 1
}
cd "$ROOT"

# Keep the pre-transplant ELF: it separates "the Bun graph is broken" from
# "the assembly onto the Android base is broken" without a rebuild.
cp "$compiled" "$work/pre-transplant-opencode"

# The compiled product already carries the Android Bun 1.4.4 base
# (BUN_SOURCE_TARGET_ELF), so re-splicing it through transplant.py only
# rewrites the same graph onto a second copy of that base — and on 1.4.4 bases
# that round-trip yields an ELF that SIGILLs on the first instruction
# (6784-byte records/argv gap, plain-offset splice). Assemble the candidate
# straight from the compiled ELF and graft the bionic libopentui over the
# glibc asset Bun embedded.
out="$ROOT/artifacts/transplant/$OPENCODE_VERSION"
tui="$ROOT/artifacts/transplant/opentui-bionic/libopentui.so"
mkdir -p "$out"
test -f "$tui" || { echo "missing bionic libopentui: $tui" >&2; exit 1; }
# The embedded asset slot in the compiled binary holds the stripped glibc
# libopentui (~4.8 MB). The zig build carries debug info (~23.8 MB), so apply
# the same strip the transplant swap used: --strip-unneeded keeps the dynamic
# exports swap_tui's FFI guard check scans for.
strip_bin="${LLVM_STRIP:-}"
if [ -z "$strip_bin" ]; then
  strip_bin="$(command -v llvm-strip || command -v strip || true)"
fi
test -n "$strip_bin" || { echo "no llvm-strip/strip available" >&2; exit 1; }
# The guard gate must run on the unstripped build: --strip-unneeded removes the
# local guard-owner symbols has_ffi_guard() scans for, so the swap is told the
# check already happened (same contract transplant.py uses).
python3 - "$tui" <<'PY'
import sys

sys.path.insert(0, "tools/transplant")
from swap_tui import has_ffi_guard

with open(sys.argv[1], "rb") as f:
    lib = f.read()
if not has_ffi_guard(lib):
    raise SystemExit(
        "libopentui lacks the FFI negative-coordinate guard; refusing to strip"
    )
print("libopentui: FFI guard verified on the unstripped build")
PY
tui_stripped="$work/libopentui-stripped.so"
"$strip_bin" --strip-unneeded "$tui" -o "$tui_stripped"
echo "libopentui: $(stat -c%s "$tui") -> $(stat -c%s "$tui_stripped") bytes after strip"
python3 tools/transplant/swap_tui.py \
  --guard-preverified \
  --binary "$compiled" \
  --tui-lib "$tui_stripped" \
  --out "$out/opencode-native-tui"
python3 - "$OPENCODE_VERSION" "$compiled" "$out/opencode-native-tui" "$out/report.json" <<'PY'
import hashlib
import json
import os
import sys

ver, src, prod, report_path = sys.argv[1:5]


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


report = {
    "ver": ver,
    "pipeline": "source-compile + swap_tui",
    "transplant": "skipped",
    "transplant_skip_reason": (
        "the compiled product already targets the android bun ELF; the 1.4.4 "
        "splice round-trip produces a binary that SIGILLs on device"
    ),
    "steps": {
        "compile": {"status": "ok"},
        "swap": {"status": "ok"},
        "transplant": {"status": "skipped"},
    },
    "source": {
        "file": os.path.basename(src),
        "size": os.path.getsize(src),
        "sha256": digest(src),
    },
    "product": {
        "file": os.path.basename(prod),
        "size": os.path.getsize(prod),
        "sha256": digest(prod),
    },
    "tui_probe": "skipped(no-aarch64)",
}
with open(report_path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2)
print(f"report: {report_path} (swap ok, transplant skipped)")
PY

