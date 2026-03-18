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
state_file="$workdir/out/$feature_card/state_card_feature.yaml"
ingest_input_file="$workdir/out/$feature_card/ingest/sources.md"
ingest_prompt_phase="$workdir/out/$feature_card/prompts/ingest.md"
intake_file="$workdir/out/$feature_card/investigations/00_intake.md"
findings_file="$workdir/out/$feature_card/investigations/20_findings.md"
findings_prompt_phase="$workdir/out/$feature_card/prompts/findings.md"
execution_log="$workdir/out/$feature_card/execution.log"

grep -Fq "current_phase: ingest" "$state_file" || fail "feature card should start in ingest"
grep -Eq '^  phase_started_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$state_file" || fail "feature card should record phase_started_at on creation"
grep -Fq "phase_completed: false" "$state_file" || fail "feature card should start with phase_completed false"
grep -Fq "phase_completed_at: null" "$state_file" || fail "feature card should start with null phase_completed_at"
grep -Fq "phase_status: RUN" "$state_file" || fail "feature card should start in RUN"
grep -Fq "completed_phases: []" "$state_file" || fail "feature card completed phases changed despite incomplete intake"
[[ -f "$ingest_input_file" ]] || fail "card should materialize ingest input"
[[ -f "$ingest_prompt_phase" ]] || fail "card should materialize phase-driven ingest prompt"
[[ -f "$intake_file" ]] || fail "00_intake.md should exist as an ingest-phase artifact scaffold"
test ! -f "$workdir/out/$feature_card/prompts/intake.md" || fail "intake prompt should not exist in feature next flow before ingest completion"
test ! -f "$workdir/out/$feature_card/investigations/intake_agent_prompt.round_1.md" || fail "legacy intake prompt should not exist before ingest advances"
grep -Eq '^workflow_phase_ingest\|OK\|' "$execution_log" || fail "execution log missing workflow phase entry for ingest"

next_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$feature_card" 2>&1)" || fail "feature next command should keep intake current while required artifacts are unfilled"
grep -Fq "unfilled required artifacts: investigations/00_intake.md investigations/_intake_provenance.md" <<<"$next_output" || fail "feature next output missing unfilled ingest gate"
grep -Fq "CARD $feature_card: ingest remains current; missing required artifacts" <<<"$next_output" || fail "feature next output missing remain-current summary"
grep -Fq "current_phase: ingest" "$state_file" || fail "feature card should remain in ingest while ingest artifacts are unfilled"
test ! -f "$findings_prompt_phase" || fail "phase-driven findings prompt should not exist before intake artifacts are filled"
test ! -f "$workdir/out/$feature_card/investigations/findings_agent_prompt.md" || fail "legacy findings prompt should not exist before intake artifacts are filled"

cat >>"$workdir/out/$feature_card/investigations/00_intake.md" <<'EOF'

Feature intake preenchido para teste.
Referencia textual mantida: out/<CARD>/investigations/00_intake.md
EOF
cat >>"$workdir/out/$feature_card/investigations/_intake_provenance.md" <<'EOF'

Fonte: teste automatizado.
EOF

next_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$feature_card" 2>&1)" || fail "feature next command failed after ingest artifacts were filled"

grep -Fq "current_phase: findings" "$state_file" || fail "feature card did not advance to findings"
grep -Fq "previous_phase: ingest" "$state_file" || fail "feature card previous_phase not updated"
grep -Eq '^  phase_started_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$state_file" || fail "feature next should stamp destination phase_started_at"
grep -Fq "phase_completed: false" "$state_file" || fail "feature next should reset phase_completed to false"
grep -Fq "phase_completed_at: null" "$state_file" || fail "feature next should reset phase_completed_at"
grep -Fq "phase_status: RUN" "$state_file" || fail "feature next should set destination phase_status to RUN"
grep -Fq "    - ingest" "$state_file" || fail "feature card completed_phases missing ingest"
[[ -f "$findings_file" ]] || fail "missing findings artifact after next"
[[ -f "$findings_prompt_phase" ]] || fail "missing phase-driven findings prompt after next"
test ! -f "$workdir/out/$feature_card/investigations/findings_agent_prompt.md" || fail "legacy findings prompt should not be mirrored into investigations"
grep -Eq '^workflow_phase_findings\|OK\|' "$execution_log" || fail "execution log missing workflow phase entry for findings"
grep -Fq "CARD $feature_card: ingest -> findings" <<<"$next_output" || fail "next output missing transition summary"
grep -Fq "RUNTIME: phase=findings action=phase_driven_execution" <<<"$next_output" || fail "next output missing phase execution summary"

next_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$feature_card" 2>&1)" || fail "feature next command should keep findings current while findings is unfilled"
grep -Fq "unfilled required artifacts: investigations/20_findings.md" <<<"$next_output" || fail "feature next output missing findings content gate"
grep -Fq "current_phase: findings" "$state_file" || fail "feature card should remain in findings while findings artifact is unfilled"

cat >>"$findings_file" <<'EOF'

Findings preenchido para teste.
Referencia textual mantida: out/<CARD>/investigations/20_findings.md
EOF

next_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$feature_card" 2>&1)" || fail "feature next command failed after findings was filled"
grep -Fq "current_phase: hypotheses" "$state_file" || fail "feature card did not advance to hypotheses after findings fill"

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
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md

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
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md

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
grep -Eq '^  phase_started_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$custom_state" || fail "custom legacy card should receive phase_started_at after next"
grep -Fq "phase_completed: false" "$custom_state" || fail "custom legacy card should reset phase_completed to false"
grep -Fq "phase_completed_at: null" "$custom_state" || fail "custom legacy card should reset phase_completed_at"
grep -Fq "phase_status: RUN" "$custom_state" || fail "custom legacy card should receive RUN phase_status after next"
[[ -f "$custom_report" ]] || fail "custom phase did not create declared artifact"
grep -Eq '^workflow_phase_code_review\|OK\|' "$custom_log" || fail "custom execution log missing workflow phase entry"
grep -Fq "RUNTIME: phase=code_review action=phase_driven_execution" <<<"$custom_output" || fail "custom next output missing phase execution summary"

missing_card="541MISSING"
missing_intake="$workdir/out/$missing_card/intake"
mkdir -p "$missing_intake"
cat >"$missing_intake/track_custom.yaml" <<'EOF'
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
cat >"$missing_intake/state_card_custom.yaml" <<'EOF'
card_state:
  track_id: custom
  previous_phase: null
  current_phase: analysis
  completed_phases: []
  phase_status: COMPLETE
EOF
cat >"$missing_intake/phase_analysis.yaml" <<'EOF'
phase:
  id: analysis
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md

  outputs:
    create_directories: []
    create_artifacts: []

  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - review/missing.md
EOF
cat >"$missing_intake/phase_code_review.yaml" <<'EOF'
phase:
  id: code_review
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md

  outputs:
    create_directories: []
    create_artifacts: []

  completion:
    strategy: required_artifacts_exist
    required_artifacts: []
EOF

missing_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$missing_card" 2>&1)" || fail "missing-artifact next command should materialize current phase and remain in place"
missing_state="$workdir/out/$missing_card/intake/state_card_custom.yaml"
missing_log="$workdir/out/$missing_card/execution.log"
grep -Fq "missing required artifacts: review/missing.md" <<<"$missing_output" || fail "missing-artifact output missing required artifact detail"
grep -Fq "CARD $missing_card: analysis remains current; missing required artifacts" <<<"$missing_output" || fail "missing-artifact output missing remain-current summary"
grep -Fq "current_phase: analysis" "$missing_state" || fail "missing-artifact card should remain in analysis"
grep -Fq "phase_status: RUN" "$missing_state" || fail "missing-artifact card should remain in RUN"
grep -Eq '^workflow_phase_analysis\|OK\|' "$missing_log" || fail "missing-artifact execution log missing current phase materialization"

unsupported_card="541UNSUPPORTED"
unsupported_intake="$workdir/out/$unsupported_card/intake"
mkdir -p "$unsupported_intake"
cat >"$unsupported_intake/track_custom.yaml" <<'EOF'
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
cat >"$unsupported_intake/state_card_custom.yaml" <<'EOF'
card_state:
  track_id: custom
  previous_phase: null
  current_phase: analysis
  completed_phases: []
  phase_status: COMPLETE
EOF
cat >"$unsupported_intake/phase_analysis.yaml" <<'EOF'
phase:
  id: analysis
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md

  outputs:
    create_directories: []
    create_artifacts: []

  completion:
    strategy: manual
EOF
cat >"$unsupported_intake/phase_code_review.yaml" <<'EOF'
phase:
  id: code_review
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md

  outputs:
    create_directories: []
    create_artifacts: []

  completion:
    strategy: required_artifacts_exist
    required_artifacts: []
EOF

if unsupported_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$unsupported_card" 2>&1)"; then
	fail "unsupported strategy next command should fail"
fi
grep -Fq "uses unsupported completion strategy 'manual'" <<<"$unsupported_output" || fail "unsupported strategy output missing explicit error"

printf "workflow_next_phase_execution OK\n"
