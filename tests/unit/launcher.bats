#!/usr/bin/env bats
# Unit tests for packing/launcher/opencode: the wrapper owns the install, so it
# must find the bundle next to itself, refuse to run without bun, and exec the
# runtime with the flags the compiled line used to carry.

load '../lib/helper'

setup() {
	make_tmpdir
	LAUNCHER="$(script_path packing/launcher/opencode)"
	PREFIX="$TEST_TMPDIR/prefix"
	BASE="$PREFIX"
	ROOT="$BASE/lib/opencode"
	mkdir -p "$BASE/bin" "$ROOT" "$TEST_TMPDIR/stub"
	cp "$LAUNCHER" "$BASE/bin/opencode"
	chmod 0755 "$BASE/bin/opencode"
	printf 'console.log("bundle")\n' > "$ROOT/index.js"
	: > "$ROOT/bunfig.toml"
	printf 'so\n' > "$ROOT/librust_pty_arm64.so"
	printf 'node\n' > "$ROOT/watcher.node"

	# Stub runtime records argv and the environment the launcher exported.
	cat > "$TEST_TMPDIR/stub/bun" <<EOF
#!/bin/sh
printf '%s\n' "\$@" > "$TEST_TMPDIR/args"
printf '%s\n' "\$OPENCODE_LAUNCHER" > "$TEST_TMPDIR/launcher-env"
printf '%s\n' "\$OPENCODE_ROOT" > "$TEST_TMPDIR/root-env"
printf '%s\n' "\$BUN_PTY_LIB" > "$TEST_TMPDIR/pty-env"
printf '%s\n' "\$OPENCODE_PARCEL_WATCHER_PATH" > "$TEST_TMPDIR/watcher-env"
printf '%s\n' "\$OPENCODE_DISABLE_AUTOUPDATE" > "$TEST_TMPDIR/autoupdate-env"
exit 0
EOF
	chmod 0755 "$TEST_TMPDIR/stub/bun"
	# readlink is the only external tool the launcher needs before exec.
	ln -sf "$(command -v readlink)" "$TEST_TMPDIR/stub/readlink"
	export PREFIX
}

teardown() {
	clean_tmpdir
}

@test "execs bun with the bundle and forwards arguments" {
	run env PATH="$TEST_TMPDIR/stub:/usr/bin:/bin" /bin/sh "$BASE/bin/opencode" run --model test
	[ "$status" -eq 0 ]
	run cat "$TEST_TMPDIR/args"
	[ "$status" -eq 0 ]
	[[ "$output" == *"--smol"* ]]
	[[ "$output" == *"--no-install"* ]]
	[[ "$output" == *"--config=$ROOT/bunfig.toml"* ]]
	[[ "$output" == *"--user-agent=opencode/latest/__OPENCODE_VERSION__/cli"* ]]
	[[ "$output" == *"$ROOT/index.js"* ]]
	[[ "$output" == *"run"* ]]
	[[ "$output" == *"--model"* ]]
}

@test "exports the paths the runtime discovers through env" {
	run env PATH="$TEST_TMPDIR/stub:/usr/bin:/bin" /bin/sh "$BASE/bin/opencode"
	[ "$status" -eq 0 ]
	[ "$(cat "$TEST_TMPDIR/launcher-env")" = "$BASE/bin/opencode" ]
	[ "$(cat "$TEST_TMPDIR/pty-env")" = "$ROOT/librust_pty_arm64.so" ]
	[ "$(cat "$TEST_TMPDIR/watcher-env")" = "$ROOT/watcher.node" ]
	[ "$(cat "$TEST_TMPDIR/root-env")" = "$ROOT" ]
	[ "$(cat "$TEST_TMPDIR/autoupdate-env")" = "1" ]
}

@test "follows a symlinked launcher back to its bundle" {
	mkdir -p "$TEST_TMPDIR/elsewhere"
	ln -sf "$BASE/bin/opencode" "$TEST_TMPDIR/elsewhere/opencode"
	run env PATH="$TEST_TMPDIR/stub:/usr/bin:/bin" /bin/sh "$TEST_TMPDIR/elsewhere/opencode"
	[ "$status" -eq 0 ]
	[ "$(cat "$TEST_TMPDIR/launcher-env")" = "$BASE/bin/opencode" ]
}

@test "fails clearly when the bundle is missing" {
	rm -f "$ROOT/index.js"
	run env PATH="$TEST_TMPDIR/stub:/usr/bin:/bin" /bin/sh "$BASE/bin/opencode"
	[ "$status" -eq 1 ]
	[[ "$output" == *"bundle missing"* ]]
}

@test "fails clearly when bun is not installed" {
	mkdir -p "$TEST_TMPDIR/nobun"
	ln -sf "$(command -v readlink)" "$TEST_TMPDIR/nobun/readlink"
	run env PATH="$TEST_TMPDIR/nobun" PREFIX="$TEST_TMPDIR/nowhere" /bin/sh "$BASE/bin/opencode"
	[ "$status" -eq 1 ]
	[[ "$output" == *"bun is not installed"* ]]
}
