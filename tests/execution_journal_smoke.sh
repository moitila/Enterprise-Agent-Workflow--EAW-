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

printf "execution_journal smoke OK\n"
