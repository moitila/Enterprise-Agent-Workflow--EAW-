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
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "wrapper compatibility" >/dev/null
state_file="$workdir/out/$card/intake/state_card_feature.yaml"

intake_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" intake "$card" 2>&1)" || fail "intake wrapper failed"
grep -Fq "deprecated compatibility wrapper" <<<"$intake_output" || fail "intake wrapper deprecation warning missing"
grep -Fq "compatibility wrapper" <<<"$intake_output" || fail "intake wrapper warning missing"
grep -Fq "current_phase: intake" "$state_file" || fail "intake wrapper should preserve intake as current phase"
test -f "$workdir/out/$card/investigations/00_intake.md" || fail "intake wrapper missing 00_intake"
test -f "$workdir/out/$card/investigations/_intake_provenance.md" || fail "intake wrapper missing provenance"
test -f "$workdir/out/$card/investigations/intake_agent_prompt.round_1.md" || fail "intake wrapper missing round 1 prompt"

round2_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" intake "$card" --round=2 2>&1)" || fail "intake wrapper round 2 failed"
grep -Fq "deprecated compatibility wrapper" <<<"$round2_output" || fail "intake wrapper round 2 deprecation warning missing"
grep -Fq "compatibility wrapper" <<<"$round2_output" || fail "intake wrapper round 2 warning missing"
test -f "$workdir/out/$card/investigations/intake_agent_prompt.round_2.md" || fail "intake wrapper missing round 2 prompt"

analyze_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" 2>&1)" || fail "analyze wrapper failed"
grep -Fq "deprecated compatibility wrapper" <<<"$analyze_output" || fail "analyze wrapper deprecation warning missing"
grep -Fq "compatibility wrapper" <<<"$analyze_output" || fail "analyze wrapper warning missing"
grep -Fq "current_phase: planning" "$state_file" || fail "analyze wrapper should advance card to planning"
grep -Fq "phase_status: RUN" "$state_file" || fail "analyze wrapper should leave planning in RUN"
grep -Fq "    - intake" "$state_file" || fail "analyze wrapper missing completed intake"
grep -Fq "    - findings" "$state_file" || fail "analyze wrapper missing completed findings"
grep -Fq "    - hypotheses" "$state_file" || fail "analyze wrapper missing completed hypotheses"
test -f "$workdir/out/$card/investigations/findings_agent_prompt.md" || fail "analyze wrapper missing findings prompt"
test -f "$workdir/out/$card/investigations/hypotheses_agent_prompt.md" || fail "analyze wrapper missing hypotheses prompt"
test -f "$workdir/out/$card/investigations/planning_agent_prompt.md" || fail "analyze wrapper missing planning prompt"
test -f "$workdir/out/$card/TEST_PLAN_${card}.md" || fail "analyze wrapper missing test plan"

implement_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" implement "$card" 2>&1)" || fail "implement wrapper failed"
grep -Fq "deprecated compatibility wrapper" <<<"$implement_output" || fail "implement wrapper deprecation warning missing"
grep -Fq "compatibility wrapper" <<<"$implement_output" || fail "implement wrapper warning missing"
grep -Fq "current_phase: implementation_executor" "$state_file" || fail "implement wrapper should advance card to implementation_executor"
grep -Fq "phase_status: RUN" "$state_file" || fail "implement wrapper should leave implementation_executor in RUN"
grep -Fq "    - planning" "$state_file" || fail "implement wrapper missing completed planning"
grep -Fq "    - implementation_planning" "$state_file" || fail "implement wrapper missing completed implementation_planning"
test -f "$workdir/out/$card/implementation/00_scope.lock.md" || fail "implement wrapper missing scope lock"
test -f "$workdir/out/$card/implementation/10_change_plan.md" || fail "implement wrapper missing change plan"
test -f "$workdir/out/$card/implementation/20_patch_notes.md" || fail "implement wrapper missing patch notes"
test -f "$workdir/out/$card/investigations/implementation_planning_agent_prompt.md" || fail "implement wrapper missing planning prompt"
test -f "$workdir/out/$card/investigations/implementation_executor_agent_prompt.md" || fail "implement wrapper missing executor prompt"

printf "workflow_wrapper_compatibility OK\n"
