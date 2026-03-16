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
state_file="$workdir/out/$card/state_card_feature.yaml"

intake_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" intake "$card" 2>&1)" || fail "intake wrapper failed"
grep -Fq "WARNING: 'intake' is deprecated and planned for removal in v1.0. Prefer 'eaw next'." <<<"$intake_output" || fail "intake wrapper deprecation warning missing"
grep -Fq "current_phase: intake" "$state_file" || fail "intake wrapper should preserve intake as current phase"
grep -Eq '^  phase_started_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$state_file" || fail "intake wrapper should preserve phase_started_at"
grep -Fq "phase_completed: false" "$state_file" || fail "intake wrapper should keep phase_completed false"
grep -Fq "phase_completed_at: null" "$state_file" || fail "intake wrapper should keep null phase_completed_at"
# 00_intake.md is created by the intake phase execution, not by eaw card scaffold
test -f "$workdir/out/$card/investigations/00_intake.md" || fail "intake wrapper missing 00_intake"
test -f "$workdir/out/$card/investigations/_intake_provenance.md" || fail "intake wrapper missing provenance"
test -f "$workdir/out/$card/investigations/intake_agent_prompt.round_1.md" || fail "intake wrapper missing round 1 prompt"

round2_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" intake "$card" --round=2 2>&1)" || fail "intake wrapper round 2 failed"
grep -Fq "WARNING: 'intake' is deprecated and planned for removal in v1.0. Prefer 'eaw next'." <<<"$round2_output" || fail "intake wrapper round 2 deprecation warning missing"
test -f "$workdir/out/$card/investigations/intake_agent_prompt.round_2.md" || fail "intake wrapper missing round 2 prompt"

analyze_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" 2>&1)" || fail "analyze wrapper failed"
grep -Fq "WARNING: 'analyze' is deprecated and planned for removal in v1.0. Prefer 'eaw next'." <<<"$analyze_output" || fail "analyze wrapper deprecation warning missing"
grep -Fq "current_phase: planning" "$state_file" || fail "analyze wrapper should advance card to planning"
grep -Eq '^  phase_started_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$state_file" || fail "analyze wrapper should stamp planning phase_started_at"
grep -Fq "phase_completed: false" "$state_file" || fail "analyze wrapper should leave planning phase_completed false"
grep -Fq "phase_completed_at: null" "$state_file" || fail "analyze wrapper should reset planning phase_completed_at"
grep -Fq "phase_status: RUN" "$state_file" || fail "analyze wrapper should leave planning in RUN"
grep -Fq "    - intake" "$state_file" || fail "analyze wrapper missing completed intake"
grep -Fq "    - findings" "$state_file" || fail "analyze wrapper missing completed findings"
grep -Fq "    - hypotheses" "$state_file" || fail "analyze wrapper missing completed hypotheses"
test -f "$workdir/out/$card/investigations/findings_agent_prompt.md" || fail "analyze wrapper missing findings prompt"
test -f "$workdir/out/$card/investigations/hypotheses_agent_prompt.md" || fail "analyze wrapper missing hypotheses prompt"
test -f "$workdir/out/$card/investigations/planning_agent_prompt.md" || fail "analyze wrapper missing planning prompt"
test -f "$workdir/out/$card/TEST_PLAN_${card}.md" || fail "analyze wrapper missing test plan"

implement_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" implement "$card" 2>&1)" || fail "implement wrapper failed"
grep -Fq "WARNING: 'implement' is deprecated and planned for removal in v1.0. Prefer 'eaw next'." <<<"$implement_output" || fail "implement wrapper deprecation warning missing"
grep -Fq "current_phase: implementation_executor" "$state_file" || fail "implement wrapper should advance card to implementation_executor"
grep -Eq '^  phase_started_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$state_file" || fail "implement wrapper should stamp implementation_executor phase_started_at"
grep -Fq "phase_completed: false" "$state_file" || fail "implement wrapper should leave implementation_executor phase_completed false"
grep -Fq "phase_completed_at: null" "$state_file" || fail "implement wrapper should reset implementation_executor phase_completed_at"
grep -Fq "phase_status: RUN" "$state_file" || fail "implement wrapper should leave implementation_executor in RUN"
grep -Fq "    - planning" "$state_file" || fail "implement wrapper missing completed planning"
grep -Fq "    - implementation_planning" "$state_file" || fail "implement wrapper missing completed implementation_planning"
test -f "$workdir/out/$card/implementation/00_scope.lock.md" || fail "implement wrapper missing scope lock"
test -f "$workdir/out/$card/implementation/10_change_plan.md" || fail "implement wrapper missing change plan"
test -f "$workdir/out/$card/implementation/20_patch_notes.md" || fail "implement wrapper missing patch notes"
test -f "$workdir/out/$card/investigations/implementation_planning_agent_prompt.md" || fail "implement wrapper missing planning prompt"
test -f "$workdir/out/$card/investigations/implementation_executor_agent_prompt.md" || fail "implement wrapper missing executor prompt"

help_output="$("$REPO_ROOT/scripts/eaw" --help 2>&1)" || fail "help command failed"
grep -Fq "eaw intake <CARD> [--round=N]   # deprecated compatibility wrapper; planned removal in v1.0" <<<"$help_output" || fail "help missing deprecated intake marker"
grep -Fq "eaw analyze <CARD>              # deprecated compatibility wrapper; planned removal in v1.0" <<<"$help_output" || fail "help missing deprecated analyze marker"
grep -Fq "eaw implement <CARD>            # deprecated compatibility wrapper; planned removal in v1.0" <<<"$help_output" || fail "help missing deprecated implement marker"

printf "workflow_wrapper_compatibility OK\n"
