#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf "workflow_wrapper_compatibility failed: %s\n" "$1" >&2
	exit 1
}

init_workdir() {
	local workdir="$1"
	"$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
	cat >"$workdir/config/repos.conf" <<CFG
local-main|$REPO_ROOT|target
CFG
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

workdir="$tmp_root/workdir"
init_workdir "$workdir"

card="554WRAP"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track standard "wrapper compatibility" >/dev/null
state_file="$workdir/out/$card/state_card_standard.yaml"

set +e
intake_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" intake "$card" 2>&1)"
intake_rc=$?
set -e
[[ "$intake_rc" -ne 0 ]] || fail "intake wrapper should be rejected"
grep -Fq "Usage: eaw init" <<<"$intake_output" || fail "intake wrapper should fall back to top-level usage"

set +e
analyze_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" 2>&1)"
analyze_rc=$?
set -e
[[ "$analyze_rc" -ne 0 ]] || fail "analyze wrapper should be rejected"
grep -Fq "Usage: eaw init" <<<"$analyze_output" || fail "analyze wrapper should fall back to top-level usage"

set +e
implement_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" implement "$card" 2>&1)"
implement_rc=$?
set -e
[[ "$implement_rc" -ne 0 ]] || fail "implement wrapper should be rejected"
grep -Fq "Usage: eaw init" <<<"$implement_output" || fail "implement wrapper should fall back to top-level usage"

grep -Fq "current_phase: intake" "$state_file" || fail "rejected wrappers should preserve intake as current phase"
grep -Fq "phase_completed: false" "$state_file" || fail "rejected wrappers should preserve phase completion state"
grep -Fq "phase_completed_at: null" "$state_file" || fail "rejected wrappers should preserve null phase_completed_at"

printf "# provenance ok\n" >"$workdir/out/$card/investigations/_intake_provenance.md"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null
test -f "$workdir/out/$card/prompts/intake.md" || fail "next should materialize intake prompt"

printf "# findings ok\n" >"$workdir/out/$card/investigations/20_findings.md"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null
printf "# hypotheses ok\n" >"$workdir/out/$card/investigations/30_hypotheses.md"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null
printf "# planning ok\n" >"$workdir/out/$card/investigations/40_next_steps.md"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null
printf "# scope lock ok\n" >"$workdir/out/$card/implementation/00_scope.lock.md"
printf "# change plan ok\n" >"$workdir/out/$card/implementation/10_change_plan.md"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

grep -Fq "current_phase: implementation_executor" "$state_file" || fail "next should advance card to implementation_executor"
test -f "$workdir/out/$card/prompts/findings.md" || fail "next missing findings prompt"
test -f "$workdir/out/$card/prompts/hypotheses.md" || fail "next missing hypotheses prompt"
test -f "$workdir/out/$card/prompts/planning.md" || fail "next missing planning prompt"
test -f "$workdir/out/$card/implementation/00_scope.lock.md" || fail "next missing scope lock"
test -f "$workdir/out/$card/implementation/10_change_plan.md" || fail "next missing change plan"
test -f "$workdir/out/$card/prompts/implementation_planning.md" || fail "next missing planning prompt"
test -f "$workdir/out/$card/prompts/implementation_executor.md" || fail "next missing executor prompt"

help_output="$("$REPO_ROOT/scripts/eaw" --help 2>&1)" || fail "help command failed"
grep -Fq "eaw next <CARD>" <<<"$help_output" || fail "help missing next command"
if grep -Fq "eaw intake <CARD>" <<<"$help_output"; then
	fail "help should not expose intake wrapper"
fi
if grep -Fq "eaw analyze <CARD>" <<<"$help_output"; then
	fail "help should not expose analyze wrapper"
fi
if grep -Fq "eaw implement <CARD>" <<<"$help_output"; then
	fail "help should not expose implement wrapper"
fi

printf "workflow_wrapper_compatibility OK\n"
