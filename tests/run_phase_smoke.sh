#!/usr/bin/env bash
#
# Codex: generate a smoke test for run_phase()
# It should:
# - invoke run_phase with a function that returns success
# - invoke run_phase with a function that returns failure (non-fatal)
# - invoke run_phase with a function that returns failure (fatal)
# - assert the exit code and execution.log contents
# Assume run_phase is sourced from scripts/eaw or scripts/lib.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EAW_FILE="$REPO_ROOT/scripts/eaw"

fail() {
	printf "run_phase smoke failed: %s\n" "$1" >&2
	exit 1
}

extract_function() {
	local fn_name="$1"
	awk -v fn="${fn_name}" '
		$0 ~ "^" fn "\\(\\)[[:space:]]*\\{" {in_fn=1}
		in_fn {print}
		in_fn && $0 ~ "^}" {exit}
	' "$EAW_FILE"
}

RUN_PHASE_DEF="$(extract_function "run_phase")"
if [[ -z "$RUN_PHASE_DEF" ]]; then
	fail "could not extract run_phase() from scripts/eaw"
fi

# shellcheck disable=SC1090
source "$REPO_ROOT/scripts/lib.sh"
eval "$RUN_PHASE_DEF"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
OUTDIR="$tmpdir/out"
mkdir -p "$OUTDIR"
: >"$OUTDIR/execution.log"

fn_success() { return 0; }
fn_fail() { return 42; }

run_phase "phase_success" true fn_success || fail "expected success phase to return 0"

if ! run_phase "phase_fail_nonfatal" false fn_fail; then
	fail "expected non-fatal failure phase to return 0"
fi

set +e
run_phase "phase_fail_fatal" true fn_fail
fatal_rc=$?
set -e

if [[ "$fatal_rc" -ne 42 ]]; then
	fail "expected fatal failure rc=42, got rc=${fatal_rc}"
fi

if ! grep -Eq '^phase_success\|OK\|[0-9]+\|$' "$OUTDIR/execution.log"; then
	fail "missing or invalid execution.log entry for phase_success"
fi

if ! grep -Eq '^phase_fail_nonfatal\|FAIL\|[0-9]+\|$' "$OUTDIR/execution.log"; then
	fail "missing or invalid execution.log entry for phase_fail_nonfatal"
fi

if ! grep -Eq '^phase_fail_fatal\|FAIL\|[0-9]+\|$' "$OUTDIR/execution.log"; then
	fail "missing or invalid execution.log entry for phase_fail_fatal"
fi

printf "run_phase smoke OK\n"
