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

# Scenario H2: symlinked script path must still resolve the real repo root for implement
invalid_implement_root="$tmpdir/invalid_implement_root"
mkdir -p "$invalid_implement_root"
ln -s "$REPO_ROOT/scripts" "$invalid_implement_root/scripts"

set +e
h2_output="$(EAW_WORKDIR="" "$invalid_implement_root/scripts/eaw" implement 528 2>&1)"
h2_rc=$?
set -e
[[ $h2_rc -ne 0 ]] || fail "H2 expected non-zero exit code"
grep -Fq "ERROR:" <<<"$h2_output" || fail "H2 missing ERROR prefix"
grep -Fq "card output directory not found:" <<<"$h2_output" || fail "H2 missing card output error context"
grep -Fq "$REPO_ROOT/out/528" <<<"$h2_output" || fail "H2 missing real repo root path"
if grep -Fq "$invalid_implement_root/out/528" <<<"$h2_output"; then
	fail "H2 should not resolve implement output against symlink wrapper root"
fi
[[ ! -e "$REPO_ROOT/out/528/implementation" ]] || fail "H2 unexpected implement residue in repo out dir"

printf "OK\n"
