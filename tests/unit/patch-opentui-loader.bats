#!/usr/bin/env bats
# Unit tests for tools/patch-opentui-loader.py: OpenTUI must treat Termux's
# process.platform "android" as the linux-arm64 asset, or the TUI dies with
# "Unsupported OpenTUI Node asset target" before the first frame.

load '../lib/helper'

setup() {
	make_tmpdir
	PATCHER="$(script_path tools/patch-opentui-loader.py)"
	CHUNK_DIR="$TEST_TMPDIR/node_modules/@opentui/core"
	mkdir -p "$CHUNK_DIR"
	CHUNK_JS="$CHUNK_DIR/chunk-bun-test00000.js"
	cat > "$CHUNK_JS" <<'EOF'
function getNativeAssetDescriptor(target) {
  return { packageName: `@opentui/core-${target.platform}-${target.arch}`, fileName: "libopentui.so" };
}
function getCurrentNodeAssetTarget() {
  const libc = process.env.OPENTUI_LIBC;
  return {
    platform: process.platform,
    arch: process.arch,
  };
}
async function resolveNativeLibraryPath() {
  const asset = getNativeAssetDescriptor(getCurrentNodeAssetTarget());
  if (process.platform === "linux") {
    if (process.arch === "arm64") {
      return (await import("@opentui/core-linux-arm64-musl")).default;
    }
  }
}
EOF
}

teardown() {
	clean_tmpdir
}

@test "maps android to the linux-arm64 asset" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	run grep -F 'if (process.platform === "android") return { platform: "linux", arch: process.arch, libc: "musl" };' "$CHUNK_JS"
	[ "$status" -eq 0 ]
	run grep -F 'if (process.platform === "linux" || process.platform === "android") {' "$CHUNK_JS"
	[ "$status" -eq 0 ]
}

@test "is idempotent" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	before="$(sha256sum "$CHUNK_JS")"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	[ "$(sha256sum "$CHUNK_JS")" = "$before" ]
	[[ "$output" == *"already applied"* ]]
}

@test "fails when bun install has not run" {
	rm -rf "$TEST_TMPDIR/node_modules"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *"run bun install first"* ]]
}

@test "fails when the loader shape changed upstream" {
	sed -i 's/function getCurrentNodeAssetTarget() {/function getCurrentNodeAssetTargetV2() {/' "$CHUNK_JS"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *"no toSafeNumberPointer"* || "$output" == *"no getCurrentNodeAssetTarget"* ]]
}

@test "fails when the linux branch is duplicated" {
	sed -i 's/if (process.platform === "linux") {/if (process.platform === "linux") {\n  }\n  if (process.platform === "linux") {/' "$CHUNK_JS"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *"expected one linux branch"* ]]
}
