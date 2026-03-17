#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() { printf "phase_lifecycle smoke failed: %s\n" "$1" >&2; exit 1; }

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/eaw_core.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

OUTDIR="$tmpdir/out"
mkdir -p "$OUTDIR"

# Simulate a real card context
EAW_CARD_WORKFLOW_CARD="TEST_CARD"
EAW_CARD_WORKFLOW_TRACK_ID="feature"

printf "#phase|status|duration_ms|note\n" >"$OUTDIR/execution.log"

fn_success() { return 0; }

run_phase "test_lifecycle_phase" true fn_success || fail "expected success phase to return 0"

journal="$OUTDIR/execution_journal.jsonl"

# --- Assertion 1: phase_started present ---
grep -q '"event_type":"phase_started"' "$journal" || fail "missing phase_started event"

# --- Assertion 2: phase_completed present ---
grep -q '"event_type":"phase_completed"' "$journal" || fail "missing phase_completed event"

# --- Assertion 3: phase_started before phase_completed (order) ---
line_started="$(grep -n '"event_type":"phase_started"' "$journal" | head -1 | cut -d: -f1)"
line_completed="$(grep -n '"event_type":"phase_completed"' "$journal" | head -1 | cut -d: -f1)"
[[ -n "$line_started" && -n "$line_completed" ]] || fail "could not determine line numbers for ordering check"
[[ "$line_started" -lt "$line_completed" ]] || fail "phase_started (line $line_started) must precede phase_completed (line $line_completed)"

# --- Assertion 4: required fields in phase_started ---
started_line="$(grep '"event_type":"phase_started"' "$journal" | head -1)"
for field in '"card_id"' '"track"' '"phase"' '"timestamp"' '"agent"' '"mode"' '"event_type"'; do
    printf '%s\n' "$started_line" | grep -q "$field" || fail "phase_started missing field $field"
done

# --- Assertion 5: required fields in phase_completed ---
completed_line="$(grep '"event_type":"phase_completed"' "$journal" | head -1)"
for field in '"card_id"' '"track"' '"phase"' '"timestamp"' '"agent"' '"mode"' '"event_type"'; do
    printf '%s\n' "$completed_line" | grep -q "$field" || fail "phase_completed missing field $field"
done

# --- Assertion 6: execution.log still has 4 columns (no regression) ---
while IFS= read -r logline; do
    [[ -z "$logline" ]] && continue
    [[ "$logline" == \#* ]] && continue
    cols="$(awk -F'|' '{print NF}' <<<"$logline")"
    [[ "$cols" -eq 4 ]] || fail "execution.log has wrong column count ($cols) in line: $logline"
done <"$OUTDIR/execution.log"

# --- Assertion 7: H6 guard — no events without card context ---
tmpdir2="$(mktemp -d)"
trap 'rm -rf "$tmpdir2"' EXIT
OUTDIR2="$tmpdir2/out"
mkdir -p "$OUTDIR2"
OUTDIR="$OUTDIR2"
EAW_CARD_WORKFLOW_CARD=""
EAW_CARD_WORKFLOW_TRACK_ID=""
printf "#phase|status|duration_ms|note\n" >"$OUTDIR2/execution.log"
run_phase "no_card_phase" true fn_success || fail "expected no-card phase to return 0"
[[ ! -f "$OUTDIR2/execution_journal.jsonl" ]] || fail "journal must not be created without card context (H6)"

# --- Assertion 8: backward compat — execution_journal_smoke.sh still passes ---
bash "$REPO_ROOT/tests/execution_journal_smoke.sh" >/dev/null || fail "execution_journal_smoke.sh regression detected"

printf "phase_lifecycle smoke OK\n"
