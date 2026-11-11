#!/usr/bin/env bats
# Unit tests for scripts/materialize-bundle.sh: the bundle is built against
# @TERMUX_PREFIX@ so one artefact fits every Termux prefix, and this step is
# what makes it concrete.

load '../lib/helper'

setup() {
	make_tmpdir
	MATERIALIZE="$(script_path scripts/materialize-bundle.sh)"
	STAGED="$TEST_TMPDIR/staged"
	DEST="$TEST_TMPDIR/dest"
	mkdir -p "$STAGED/lib/nested"
	printf 'const p = "@TERMUX_PREFIX@/lib/opencode/app-1.bin";\n' > "$STAGED/lib/index.js"
	printf 'export {}\n' > "$STAGED/lib/nested/chunk.js"
	printf 'asset\n' > "$STAGED/lib/app-1.bin"
}

teardown() {
	clean_tmpdir
}

@test "installs the tree and rewrites the prefix placeholder" {
	run bash "$MATERIALIZE" /data/data/com.termux/files/usr "$STAGED" "$DEST" 2.2.7
	[ "$status" -eq 0 ]
	[ -f "$DEST/lib/opencode/index.js" ]
	[ -f "$DEST/lib/opencode/app-1.bin" ]
	[ -f "$DEST/lib/opencode/nested/chunk.js" ]
	run grep -F '/data/data/com.termux/files/usr/lib/opencode/app-1.bin' "$DEST/lib/opencode/index.js"
	[ "$status" -eq 0 ]
	run grep -rF '@TERMUX_PREFIX@' "$DEST/lib/opencode"
	[ "$status" -ne 0 ]
}

@test "installs the launcher with the release version" {
	run bash "$MATERIALIZE" /data/data/com.termux/files/usr "$STAGED" "$DEST" 2.2.7
	[ "$status" -eq 0 ]
	[ -x "$DEST/bin/opencode" ]
	run grep -F 'version=2.2.7' "$DEST/bin/opencode"
	[ "$status" -eq 0 ]
	run grep -F '__OPENCODE_VERSION__' "$DEST/bin/opencode"
	[ "$status" -ne 0 ]
}

@test "replaces a previous install instead of merging into it" {
	mkdir -p "$DEST/lib/opencode"
	printf 'stale\n' > "$DEST/lib/opencode/stale.js"
	run bash "$MATERIALIZE" /prefix "$STAGED" "$DEST" 2.2.7
	[ "$status" -eq 0 ]
	[ ! -e "$DEST/lib/opencode/stale.js" ]
}

@test "rejects an impossible version" {
	run bash "$MATERIALIZE" /prefix "$STAGED" "$DEST" '../../../etc/passwd'
	[ "$status" -eq 2 ]
	[[ "$output" == *"Invalid version"* ]]
}

@test "fails when a placeholder survives outside javascript" {
	printf 'leftover @TERMUX_PREFIX@\n' > "$STAGED/lib/notes.txt"
	run bash "$MATERIALIZE" /prefix "$STAGED" "$DEST" 2.2.7
	[ "$status" -ne 0 ]
	[[ "$output" == *"Unsubstituted @TERMUX_PREFIX@"* ]]
}
