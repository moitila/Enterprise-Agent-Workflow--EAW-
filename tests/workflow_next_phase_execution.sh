#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf "workflow_next_phase_execution failed: %s\n" "$1" >&2
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

feature_card="541NEXT"
EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$feature_card" --track feature "phase driven next" >/dev/null
if next_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$feature_card" 2>&1)"; then
	fail "feature next command should block when intake artifacts are missing"
fi

state_file="$workdir/out/$feature_card/intake/state_card_feature.yaml"
findings_file="$workdir/out/$feature_card/investigations/20_findings.md"
findings_prompt="$workdir/out/$feature_card/investigations/findings_agent_prompt.md"
execution_log="$workdir/out/$feature_card/execution.log"

grep -Fq "phase 'intake' is incomplete" <<<"$next_output" || fail "feature next output missing completion gate message"
grep -Fq "investigations/_intake_provenance.md" <<<"$next_output" || fail "feature next output missing intake provenance artifact"
grep -Fq "current_phase: intake" "$state_file" || fail "feature card advanced despite incomplete intake"
grep -Fq "completed_phases: []" "$state_file" || fail "feature card completed phases changed despite incomplete intake"
test ! -f "$findings_prompt" || fail "findings prompt should not exist before phase completion"
! grep -Eq '^workflow_phase_findings\|OK\|' "$execution_log" || fail "execution log should not record findings phase before completion"

cat >"$workdir/out/$feature_card/investigations/_intake_provenance.md" <<'EOF'
# Provenance
EOF

next_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$feature_card" 2>&1)" || fail "feature next command failed after intake completion"

grep -Fq "current_phase: findings" "$state_file" || fail "feature card did not advance to findings"
grep -Fq "previous_phase: intake" "$state_file" || fail "feature card previous_phase not updated"
grep -Fq "    - intake" "$state_file" || fail "feature card completed_phases missing intake"
[[ -f "$findings_file" ]] || fail "missing findings artifact after next"
[[ -f "$findings_prompt" ]] || fail "missing findings prompt after next"
grep -Eq '^workflow_phase_findings\|OK\|' "$execution_log" || fail "execution log missing workflow phase entry for findings"
grep -Fq "CARD $feature_card: intake -> findings" <<<"$next_output" || fail "next output missing transition summary"
grep -Fq "RUNTIME: phase=findings action=phase_driven_execution" <<<"$next_output" || fail "next output missing phase execution summary"

custom_card="541CUSTOM"
custom_intake="$workdir/out/$custom_card/intake"
mkdir -p "$custom_intake"
cat >"$custom_intake/track_custom.yaml" <<'EOF'
track:
  id: custom
  initial_phase: analysis
  final_phase: code_review
  phases:
    - analysis
    - code_review
  transitions:
    analysis:
      next: code_review
EOF
cat >"$custom_intake/state_card_custom.yaml" <<'EOF'
card_state:
  track_id: custom
  previous_phase: null
  current_phase: analysis
  completed_phases: []
EOF
cat >"$custom_intake/phase_analysis.yaml" <<'EOF'
phase:
  id: analysis
  prompt:
    path: templates/prompts/default/findings/prompt_v<active>.md

  outputs:
    create_directories: []
    create_artifacts: []

  completion:
    strategy: required_artifacts_exist
    required_artifacts: []
EOF
cat >"$custom_intake/phase_code_review.yaml" <<'EOF'
phase:
  id: code_review
  prompt:
    path: templates/prompts/default/findings/prompt_v<active>.md

  outputs:
    create_directories:
      - review
    create_artifacts:
      - review/report.md

  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - review/report.md
EOF

custom_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$custom_card" 2>&1)" || fail "custom next command failed"
custom_state="$workdir/out/$custom_card/intake/state_card_custom.yaml"
custom_report="$workdir/out/$custom_card/review/report.md"
custom_log="$workdir/out/$custom_card/execution.log"

grep -Fq "current_phase: code_review" "$custom_state" || fail "custom card did not advance to code_review"
[[ -f "$custom_report" ]] || fail "custom phase did not create declared artifact"
grep -Eq '^workflow_phase_code_review\|OK\|' "$custom_log" || fail "custom execution log missing workflow phase entry"
grep -Fq "RUNTIME: phase=code_review action=phase_driven_execution" <<<"$custom_output" || fail "custom next output missing phase execution summary"

printf "workflow_next_phase_execution OK\n"
