#!/usr/bin/env bats
# Unit tests for tools/patch-opentui-ffi.py: the shim must keep Bionic's
# top-byte pointer tag intact (Scudo aborts on a truncated tag at free()).

load '../lib/helper'

setup() {
	make_tmpdir
	PATCHER="$(script_path tools/patch-opentui-ffi.py)"
	CHUNK_DIR="$TEST_TMPDIR/node_modules/@opentui/core"
	mkdir -p "$CHUNK_DIR"
	CHUNK_JS="$CHUNK_DIR/chunk-bun-test00000.js"
	cat > "$CHUNK_JS" <<'EOF'
var POINTER_NEGATIVE = "Pointer must be non-negative";
var POINTER_UNSAFE = "Pointer exceeds safe integer range";
function toPointer(value) {
  if (isBun && typeof value === "bigint") {
    return toSafeNumberPointer(value);
  }
  return value;
}
function toSafeNumberPointer(pointer) {
  if (pointer < 0n) {
    throw new Error(POINTER_NEGATIVE);
  }
  if (pointer > BigInt(Number.MAX_SAFE_INTEGER)) {
    throw new Error(POINTER_UNSAFE);
  }
  return Number(pointer);
}
function toSafeBigIntPointer(pointer) {
  if (pointer < 0) {
    throw new Error(POINTER_NEGATIVE);
  }
  if (!Number.isSafeInteger(pointer)) {
    throw new Error(POINTER_UNSAFE);
  }
  return BigInt(pointer);
}
function toBunPointer(pointer) {
  return typeof pointer === "bigint" ? toSafeNumberPointer(pointer) : pointer;
}
function toBunPointer2(pointer) {
  return typeof pointer === "bigint" ? Number(pointer) : pointer;
}
EOF
}

teardown() {
	clean_tmpdir
}

@test "keeps the tagged BigInt instead of throwing or masking it" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	grep -q 'return BigInt.asUintN(64, pointer);' "$CHUNK_JS"
	# the old tag-stripping patch must not come back: Scudo frees with the tag
	! grep -q '0x00ffffffffffffffn' "$CHUNK_JS"
	# the unsafe-range throw survives only in the node:ffi backend
	[ "$(grep -c 'throw new Error(POINTER_UNSAFE);' "$CHUNK_JS")" -eq 1 ]
	grep -q 'return Number(pointer);' "$CHUNK_JS"
}

@test "stops toBunPointer2 from truncating the pointer through Number()" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	run grep -A2 'function toBunPointer2(pointer)' "$CHUNK_JS"
	[[ "$output" == *'return pointer;'* ]]
	[[ "$output" != *'Number(pointer)'* ]]
}

@test "is idempotent" {
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	cp "$CHUNK_JS" "$TEST_TMPDIR/first.js"
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	[[ "$output" == *"already applied"* ]]
	cmp -s "$CHUNK_JS" "$TEST_TMPDIR/first.js"
}

@test "migrates a tree patched by the old tag-stripping revision" {
	python3 - "$CHUNK_JS" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace(
    "  if (pointer > BigInt(Number.MAX_SAFE_INTEGER)) {\n",
    "  if (pointer > BigInt(Number.MAX_SAFE_INTEGER)) {\n"
    "    pointer &= 0x00ffffffffffffffn;\n",
)
path.write_text(text)
PY
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -eq 0 ]
	! grep -q '0x00ffffffffffffffn' "$CHUNK_JS"
	grep -q 'return BigInt.asUintN(64, pointer);' "$CHUNK_JS"
}

@test "fails loudly when upstream moves the unsafe-integer check" {
	python3 - "$CHUNK_JS" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text().replace(
    "if (pointer > BigInt(Number.MAX_SAFE_INTEGER)) {",
    "if (pointer > 9007199254740991n) {",
)
path.write_text(text)
PY
	run python3 "$PATCHER" "$TEST_TMPDIR"
	[ "$status" -ne 0 ]
	[[ "$output" == *"upstream changed the shim"* ]]
}
