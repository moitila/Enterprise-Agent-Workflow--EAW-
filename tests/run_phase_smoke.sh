#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { printf "run_phase smoke failed: %s\n" "$1" >&2; exit 1; }

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/eaw_core.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

OUTDIR="$tmpdir/out"
mkdir -p "$OUTDIR"
EAW_TRACKS_DIR="${EAW_TRACKS_DIR:-$REPO_ROOT/tracks}"
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"

fn_success() { return 0; }
fn_fail() { return 42; }

run_phase "phase_success" true fn_success || fail "expected success phase to return 0"
run_phase "phase_fail_nonfatal" false fn_fail || fail "expected non-fatal failure phase to return 0"

set +e
run_phase "phase_fail_fatal" true fn_fail
fatal_rc=$?
set -e
[[ "$fatal_rc" -eq 42 ]] || fail "expected fatal failure rc=42, got rc=${fatal_rc}"
[[ -f "$OUTDIR/execution.log" ]] || fail "execution.log was not derived"
[[ -f "$OUTDIR/execution_journal.jsonl" ]] || fail "execution_journal.jsonl was not created"
header="$(sed -n '1p' "$OUTDIR/execution.log")"
[[ "$header" == "phase|status|duration_ms|note" ]] || fail "unexpected execution.log header: $header"

# Validate 4 columns, allow any note content
assert_line() {
  local name="$1" status="$2"
  local line
  line="$(grep -E "^${name}\|" "$OUTDIR/execution.log" | tail -n 1 || true)"
  [[ -n "$line" ]] || fail "missing execution.log entry for ${name}"
  [[ "$(awk -F'|' '{print NF}' <<<"$line")" -eq 4 ]] || fail "expected 4 columns for ${name}: $line"
  grep -Eq "^${name}\|${status}\|[0-9]+\|" <<<"$line" || fail "invalid status/duration for ${name}: $line"
}

assert_line "phase_success" "OK"
assert_line "phase_fail_nonfatal" "FAIL"
assert_line "phase_fail_fatal" "FAIL"

count="$(grep -cE '^(phase_success|phase_fail_nonfatal|phase_fail_fatal)\|' "$OUTDIR/execution.log" || true)"
[[ "$count" -eq 3 ]] || fail "expected 3 phase entries, got $count"

printf "run_phase smoke OK\n"
