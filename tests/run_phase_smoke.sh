#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EAW_FILE="$REPO_ROOT/scripts/eaw"

fail() { printf "run_phase smoke failed: %s\n" "$1" >&2; exit 1; }

extract_function() {
  local fn_name="$1"
  awk -v fn="${fn_name}" '
    $0 ~ "^" fn "\\(\\)[[:space:]]*\\{" {in_fn=1; depth=0}
    in_fn {
      print
      # crude brace depth tracking; works for typical bash style
      for (i=1; i<=length($0); i++) {
        c=substr($0,i,1)
        if (c=="{") depth++
        else if (c=="}") depth--
      }
      if (in_fn && depth==0) exit
    }
  ' "$EAW_FILE"
}

RUN_PHASE_DEF="$(extract_function "run_phase")"
[[ -n "$RUN_PHASE_DEF" ]] || fail "could not extract run_phase() from scripts/eaw"

# shellcheck disable=SC1090
source "$REPO_ROOT/scripts/lib.sh"
eval "$RUN_PHASE_DEF"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

OUTDIR="$tmpdir/out"
mkdir -p "$OUTDIR"

# include header so format is stable and visible
printf "#phase|status|duration_ms|note\n" >"$OUTDIR/execution.log"

fn_success() { return 0; }
fn_fail() { return 42; }

run_phase "phase_success" true fn_success || fail "expected success phase to return 0"
run_phase "phase_fail_nonfatal" false fn_fail || fail "expected non-fatal failure phase to return 0"

set +e
run_phase "phase_fail_fatal" true fn_fail
fatal_rc=$?
set -e
[[ "$fatal_rc" -eq 42 ]] || fail "expected fatal failure rc=42, got rc=${fatal_rc}"

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
