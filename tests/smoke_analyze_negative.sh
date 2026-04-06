#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_analyze_negative failed: %s\n" "$1" >&2
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
	output="$(assert_write_scope "analyze" "$label" "$target" "$allowed" 2>&1)"
	local rc=$?
	set -e
	[[ $rc -eq 97 ]] || fail "$label expected rc 97 got $rc"
	grep -Fq "WRITE_SCOPE_VIOLATION: phase=analyze command=$label" <<<"$output" || fail "$label missing violation header"
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

workdir="$tmpdir/workdir"
./scripts/eaw init --workdir "$workdir" --force >/dev/null

set +e
cmd_output="$(EAW_WORKDIR="$workdir" ./scripts/eaw analyze "../escape-analyze" 2>&1)"
cmd_rc=$?
set -e
[[ $cmd_rc -ne 0 ]] || fail "command scenario expected non-zero exit"
grep -Fq "Usage: eaw init" <<<"$cmd_output" || fail "command scenario missing CLI usage output"
grep -Fq "eaw next <CARD>" <<<"$cmd_output" || fail "command scenario missing next command in usage output"
[[ ! -e "$workdir/escape-analyze" ]] || fail "unexpected residue outside out dir"

# Scenario H5: missing repos.conf in workspace config (CONFIG_SOURCE precondition)
missing_config_workdir="$tmpdir/missing_config_workdir"
mkdir -p "$missing_config_workdir/config"

set +e
h5_output="$(EAW_WORKDIR="$missing_config_workdir" ./scripts/eaw analyze 528 2>&1)"
h5_rc=$?
set -e
[[ $h5_rc -ne 0 ]] || fail "H5 expected non-zero exit code"
grep -Fq "Usage: eaw init" <<<"$h5_output" || fail "H5 missing CLI usage output"
[[ ! -e "$missing_config_workdir/out/528" ]] || fail "H5 unexpected out residue for invalid workspace config"

# Scenario H1: symlinked script path must still resolve the real repo root for analyze
invalid_analyze_root="$tmpdir/invalid_analyze_root"
mkdir -p "$invalid_analyze_root"
ln -s "$REPO_ROOT/scripts" "$invalid_analyze_root/scripts"

set +e
h1_output="$(EAW_WORKDIR="" "$invalid_analyze_root/scripts/eaw" analyze 528 2>&1)"
h1_rc=$?
set -e
[[ $h1_rc -ne 0 ]] || fail "H1 expected non-zero exit code"
grep -Fq "Usage: eaw init" <<<"$h1_output" || fail "H1 missing CLI usage output"
[[ ! -e "$REPO_ROOT/out/528" ]] || fail "H1 unexpected residue in repo out dir"

printf "OK\n"
