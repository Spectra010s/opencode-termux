#!/usr/bin/env bats
# tools/ocver.py is the only reader of the lock version.

setup() {
  repo="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  tmp="$(mktemp -d)"
  python3 - "$repo/tools/supply-chain-lock.json" "$tmp/lock.json" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
lock["current"] = "9.9.9"
lock["package_revision"] = 1
json.dump(lock, open(sys.argv[2], "w"))
PY
  export OCVER_LOCK="$tmp/lock.json"
  ocver="$repo/tools/ocver.py"
}

teardown() {
  rm -rf "$tmp"
}

set_revision() {
  python3 - "$OCVER_LOCK" "$1" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
lock["package_revision"] = int(sys.argv[2])
json.dump(lock, open(sys.argv[1], "w"))
PY
}

@test "current reads the lock's current version" {
  run python3 "$ocver" current
  [ "$status" -eq 0 ]
  [ "$output" = "9.9.9" ]
}

@test "the first build of a version is v<version> and <version>-1" {
  run python3 "$ocver" revision
  [ "$output" = "1" ]
  run python3 "$ocver" tag
  [ "$output" = "v9.9.9" ]
  run python3 "$ocver" debversion
  [ "$output" = "9.9.9-1" ]
}

@test "a rebuild raises the tag and the debian version together" {
  set_revision 2
  run python3 "$ocver" tag
  [ "$output" = "v9.9.9-2" ]
  run python3 "$ocver" debversion
  [ "$output" = "9.9.9-2" ]
}

@test "an explicit version argument overrides the lock version" {
  set_revision 3
  run python3 "$ocver" tag 9.9.8
  [ "$output" = "v9.9.8-3" ]
}
