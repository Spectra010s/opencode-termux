#!/usr/bin/env bats
# Unit tests for tools/patch-fff-android.py: fff ships an aarch64-linux-android
# build, but its embedded-library resolver only names darwin, win32 and linux,
# so on Termux file search silently degrades to the ripgrep layer.

load '../lib/helper'

setup() {
	make_tmpdir
	PATCHER="$(script_path tools/patch-fff-android.py)"
	SRC_DIR="$TEST_TMPDIR/node_modules/@ff-labs/fff-bun/src"
	mkdir -p "$SRC_DIR"
	SRC="$SRC_DIR/embedded.ts"
	cat > "$SRC" <<'EOF'
async function resolveEmbeddedLibPath(): Promise<string | null> {
  if (process.platform === "darwin") {
    return importFile(
      import(`@ff-labs/fff-bin-darwin-${process.arch}/libfff_c.dylib`, {
        with: { type: "file" },
      }),
    );
  }

  if (process.platform === "win32") {
    return importFile(
      import(`@ff-labs/fff-bin-win32-${process.arch}/fff_c.dll`, {
        with: { type: "file" },
      }),
    );
  }

  return null;
}
EOF
}

teardown() {
	clean_tmpdir
}

@test "adds the android branch" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	run grep -F 'if (process.platform === "android") {' "$SRC"
	[ "$status" -eq 0 ]
	run grep -F '@ff-labs/fff-bin-android-arm64/libfff_c.so' "$SRC"
	[ "$status" -eq 0 ]
}

@test "is idempotent" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	before="$(sha256sum "$SRC")"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	[ "$(sha256sum "$SRC")" = "$before" ]
	[[ "$output" == *"already applied"* ]]
}

@test "fails when bun install has not run" {
	rm -rf "$TEST_TMPDIR/node_modules"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *"expected one @ff-labs/fff-bun/embedded.ts"* ]]
}

@test "fails when the win32 branch changed upstream" {
	sed -i 's/process.platform === "win32"/process.platform === "windows"/' "$SRC"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *"win32 branch changed upstream"* ]]
}
