#!/usr/bin/env bats
# Unit tests for install.sh's runtime dependency handling.
#
# 2.2.7 runs on Termux's bun package instead of shipping a compiled ELF, so bun
# and ripgrep are real dependencies: the installer must install them through
# pkg rather than handing the user a second command to run.

load '../lib/helper'

BUN_RG_TOOLS="sha256sum tar sed mktemp install rm awk readlink"

setup() {
	make_tmpdir
	INSTALLER="$(script_path install.sh)"
	BASH_BIN="$(command -v bash)"

	# A PATH with no bun and no rg in it, so "missing" is deterministic on any
	# host (GitHub runners ship ripgrep, so relying on the real PATH is not).
	TOOLS="$TEST_TMPDIR/tools"
	mkdir -p "$TOOLS"
	for tool in $BUN_RG_TOOLS; do
		ln -s "$(command -v "$tool")" "$TOOLS/$tool"
	done
	cat > "$TOOLS/uname" <<'EOF'
#!/bin/sh
echo aarch64
EOF
	cat > "$TOOLS/getprop" <<'EOF'
#!/bin/sh
echo 28
EOF
	# Curl is only reached once the dependency step has passed; fail fast so the
	# test never touches the network.
	cat > "$TOOLS/curl" <<'EOF'
#!/bin/sh
exit 1
EOF
	cat > "$TOOLS/pkg" <<EOF
#!/bin/sh
printf '%s\\n' "\$*" > "$TEST_TMPDIR/pkg-args"
exit \${PKG_STATUS:-0}
EOF
	chmod 0755 "$TOOLS/uname" "$TOOLS/getprop" "$TOOLS/curl" "$TOOLS/pkg"
	export PREFIX="$TEST_TMPDIR/prefix"
	export HOME="$TEST_TMPDIR/home"
	mkdir -p "$PREFIX/bin" "$HOME"
}

teardown() {
	clean_tmpdir
}

@test "installs missing bun and ripgrep through pkg" {
	run env PATH="$TOOLS" "$BASH_BIN" "$INSTALLER"
	[[ "$output" == *"Installing dependencies: bun ripgrep"* ]]
	[ "$(cat "$TEST_TMPDIR/pkg-args")" = "install -y bun ripgrep" ]
}

@test "skips pkg when the caller opts out" {
	run env PATH="$TOOLS" OPENCODE_INSTALL_DEPS=0 "$BASH_BIN" "$INSTALLER"
	[ "$status" -eq 1 ]
	[[ "$output" == *"opencode needs: bun ripgrep"* ]]
	[[ "$output" == *"pkg install bun ripgrep"* ]]
	[ ! -e "$TEST_TMPDIR/pkg-args" ]
}

@test "reports the manual command when pkg itself fails" {
	run env PATH="$TOOLS" PKG_STATUS=1 "$BASH_BIN" "$INSTALLER"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Run it yourself: pkg install bun ripgrep"* ]]
}

@test "does not install anything when both are already present" {
	for tool in bun rg; do
		printf '#!/bin/sh\nexit 0\n' > "$TOOLS/$tool"
		chmod 0755 "$TOOLS/$tool"
	done
	run env PATH="$TOOLS" "$BASH_BIN" "$INSTALLER"
	[[ "$output" != *"Installing dependencies"* ]]
	[ ! -e "$TEST_TMPDIR/pkg-args" ]
}
