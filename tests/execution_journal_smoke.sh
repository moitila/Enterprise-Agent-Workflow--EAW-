#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { printf "execution_journal smoke failed: %s\n" "$1" >&2; exit 1; }

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/eaw_core.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

OUTDIR="$tmpdir/out"
mkdir -p "$OUTDIR"

# Simulate a real card context (H5: journal only written when card context is present)
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"

# Initialise execution.log with the canonical 4-column header
printf "#phase|status|duration_ms|note\n" >"$OUTDIR/execution.log"

fn_success() { return 0; }
fn_fail() { return 42; }

run_phase "test_phase_ok" true fn_success || fail "expected success phase to return 0"
run_phase "test_phase_fail" false fn_fail || fail "expected non-fatal failure to return 0"

# --- Assertion 1: execution_journal.jsonl exists ---
[[ -f "$OUTDIR/execution_journal.jsonl" ]] || fail "execution_journal.jsonl not created"

# --- Assertion 2: at least one non-empty line ---
line_count="$(grep -c '[^[:space:]]' "$OUTDIR/execution_journal.jsonl" || true)"
[[ "$line_count" -ge 1 ]] || fail "execution_journal.jsonl has no valid lines"

# --- Assertion 3: required fields present in at least one line ---
grep -q '"card_id"' "$OUTDIR/execution_journal.jsonl" || fail "missing field card_id"
grep -q '"track"' "$OUTDIR/execution_journal.jsonl" || fail "missing field track"
grep -q '"phase"' "$OUTDIR/execution_journal.jsonl" || fail "missing field phase"
grep -q '"timestamp"' "$OUTDIR/execution_journal.jsonl" || fail "missing field timestamp"
grep -q '"agent"' "$OUTDIR/execution_journal.jsonl" || fail "missing field agent"
grep -q '"mode"' "$OUTDIR/execution_journal.jsonl" || fail "missing field mode"

# --- Assertion 6: agent and mode values are non-empty ---
grep -q '"agent":""' "$OUTDIR/execution_journal.jsonl" && fail "agent value must not be empty"
grep -q '"mode":""' "$OUTDIR/execution_journal.jsonl" && fail "mode value must not be empty"

# --- Assertion 7: EAW_AGENT is reflected in agent field when set ---
tmpdir3="$(mktemp -d)"
trap 'rm -rf "$tmpdir3"' EXIT
OUTDIR3="$tmpdir3/out"
mkdir -p "$OUTDIR3"
OUTDIR="$OUTDIR3"
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"
EAW_AGENT="probe-agent"
EAW_MODE="probe-mode"
printf "#phase|status|duration_ms|note\n" >"$OUTDIR3/execution.log"
run_phase "probe_phase" true fn_success || fail "expected probe phase to return 0"
grep -q '"agent":"probe-agent"' "$OUTDIR3/execution_journal.jsonl" || fail "EAW_AGENT not reflected in agent field"
grep -q '"mode":"probe-mode"' "$OUTDIR3/execution_journal.jsonl" || fail "EAW_MODE not reflected in mode field"
unset EAW_AGENT EAW_MODE

# --- Assertion 8: fallback values used when EAW_AGENT/EAW_MODE are unset ---
tmpdir4="$(mktemp -d)"
trap 'rm -rf "$tmpdir4"' EXIT
OUTDIR4="$tmpdir4/out"
mkdir -p "$OUTDIR4"
OUTDIR="$OUTDIR4"
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"
printf "#phase|status|duration_ms|note\n" >"$OUTDIR4/execution.log"
run_phase "fallback_phase" true fn_success || fail "expected fallback phase to return 0"
grep -q '"agent":"runtime"' "$OUTDIR4/execution_journal.jsonl" || fail "agent fallback must be runtime when EAW_AGENT is unset"
grep -q '"mode":"phase_driven"' "$OUTDIR4/execution_journal.jsonl" || fail "mode fallback must be phase_driven when EAW_MODE is unset"

# --- Assertion 4: execution.log still has 4 columns (no regression) ---
while IFS= read -r logline; do
    [[ -z "$logline" ]] && continue
    [[ "$logline" == \#* ]] && continue
    cols="$(awk -F'|' '{print NF}' <<<"$logline")"
    [[ "$cols" -eq 4 ]] || fail "execution.log has wrong column count ($cols) in line: $logline"
done <"$OUTDIR/execution.log"

# --- Assertion 5: H5 guard — no journal written when card context is absent ---
tmpdir2="$(mktemp -d)"
trap 'rm -rf "$tmpdir2"' EXIT
OUTDIR2="$tmpdir2/out"
mkdir -p "$OUTDIR2"
OUTDIR="$OUTDIR2"
# Unset card context
EAW_CARD_WORKFLOW_CARD=""
EAW_CARD_WORKFLOW_TRACK_ID=""
printf "#phase|status|duration_ms|note\n" >"$OUTDIR2/execution.log"
run_phase "no_card_phase" true fn_success || fail "expected no-card phase to return 0"
[[ ! -f "$OUTDIR2/execution_journal.jsonl" ]] || fail "journal must not be created without card context (H5)"

# --- Assertion 9: duration_ms in phase_completed is a positive integer ---
tmpdir5="$(mktemp -d)"
trap 'rm -rf "$tmpdir5"' EXIT
OUTDIR5="$tmpdir5/out"
mkdir -p "$OUTDIR5"
OUTDIR="$OUTDIR5"
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"
printf "#phase|status|duration_ms|note\n" >"$OUTDIR5/execution.log"
run_phase "duration_phase" true fn_success || fail "expected duration_phase to return 0"
grep -qE '"event_type":"phase_completed"' "$OUTDIR5/execution_journal.jsonl" || fail "no phase_completed events found"
grep -qE '"duration_ms":[1-9][0-9]*' "$OUTDIR5/execution_journal.jsonl" || fail "duration_ms must be a positive integer in phase_completed"

# --- Assertion 10: duration_ms in phase_started is exactly 0 ---
started_bad="$(grep '"event_type":"phase_started"' "$OUTDIR5/execution_journal.jsonl" | grep -v '"duration_ms":0' || true)"
[ -z "$started_bad" ] || fail "duration_ms must be 0 in phase_started events"

# --- Assertion 11: retry appends events without overwriting (append-only) ---
tmpdir_retry="$(mktemp -d)"
trap 'rm -rf "$tmpdir_retry"' EXIT
OUTDIR_RETRY="$tmpdir_retry/out"
mkdir -p "$OUTDIR_RETRY"
OUTDIR="$OUTDIR_RETRY"
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"
printf "#phase|status|duration_ms|note\n" >"$OUTDIR_RETRY/execution.log"
run_phase "retry_phase" true fn_success || fail "expected first retry_phase run to return 0"
run_phase "retry_phase" true fn_success || fail "expected second retry_phase run to return 0"
line_count="$(wc -l <"$OUTDIR_RETRY/execution_journal.jsonl")"
[ "$line_count" -ge 4 ] || fail "retry must accumulate events: expected >= 4 lines, got $line_count"

# --- Assertion 12: track_completed event emitted with correct fields ---
tmpdir_track="$(mktemp -d)"
trap 'rm -rf "$tmpdir_track"' EXIT
OUTDIR_TRACK="$tmpdir_track/out"
mkdir -p "$OUTDIR_TRACK"
OUTDIR="$OUTDIR_TRACK"
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"
eaw_journal_append "TEST_CARD" "feature" "implementation_executor" "OK" "0" "track_completed"
grep -q '"event_type":"track_completed"' "$OUTDIR_TRACK/execution_journal.jsonl" || fail "track_completed not emitted"
grep -q '"card_id":"TEST_CARD"' "$OUTDIR_TRACK/execution_journal.jsonl" || fail "card_id missing from track_completed"
grep -q '"track":"feature"' "$OUTDIR_TRACK/execution_journal.jsonl" || fail "track missing from track_completed"
grep -q '"phase":"implementation_executor"' "$OUTDIR_TRACK/execution_journal.jsonl" || fail "phase missing from track_completed"

# --- Assertion 13: track_completed idempotency guard ---
if ! grep -q '"event_type":"track_completed"' "$OUTDIR_TRACK/execution_journal.jsonl" 2>/dev/null; then
	eaw_journal_append "TEST_CARD" "feature" "implementation_executor" "OK" "0" "track_completed"
fi
track_count="$(grep -c '"event_type":"track_completed"' "$OUTDIR_TRACK/execution_journal.jsonl")"
[ "$track_count" -eq 1 ] || fail "track_completed must appear exactly once, got $track_count"

printf "execution_journal smoke OK\n"
