#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_implement_negative failed: %s\n" "$1" >&2
	exit 1
}

# shellcheck source=scripts/lib.sh
source "$REPO_ROOT/scripts/lib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

allowed="$tmpdir/allowed"
mkdir -p "$allowed"

assert_violation() {
	local label="$1"
	local target="$2"
	set +e
	local output
	output="$(assert_write_scope "implement" "$label" "$target" "$allowed" 2>&1)"
	local rc=$?
	set -e
	[[ $rc -eq 97 ]] || fail "$label expected rc 97 got $rc"
	grep -Fq "WRITE_SCOPE_VIOLATION: phase=implement command=$label" <<<"$output" || fail "$label missing violation header"
	grep -Fq "blocked_path=" <<<"$output" || fail "$label missing blocked_path"
}

assert_violation "absolute-path" "/tmp/eaw_abs_violation"
(
	cd "$allowed"
	assert_violation "relative-path" "../outside.txt"
)
(
	cd "$allowed"
	mkdir -p nested
	assert_violation "traversal-path" "nested/../../outside.txt"
)

printf "OK\n"
