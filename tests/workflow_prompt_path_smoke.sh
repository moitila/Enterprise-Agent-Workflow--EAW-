#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf "workflow_prompt_path_smoke failed: %s\n" "$1" >&2
	exit 1
}

init_workdir() {
	local workdir="$1"
	"$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
	cat >"$workdir/config/repos.conf" <<CFG
local-main|$REPO_ROOT|target
CFG
}

write_valid_card() {
	local workdir="$1"
	local card="$2"
	local intake_dir="$workdir/out/$card/intake"

	mkdir -p "$intake_dir"

	cat >"$intake_dir/track_prompt_path.yaml" <<'EOF'
track:
  id: declarative
  initial_phase: analysis
  final_phase: analysis
  phases:
    - analysis
EOF

	cat >"$intake_dir/state_card_prompt_path.yaml" <<'EOF'
card_state:
  track_id: declarative
  previous_phase: null
  current_phase: analysis
  completed_phases: []
EOF

	cat >"$intake_dir/phase_analysis.yaml" <<'EOF'
phase:
  id: analysis
  prompt:
    path: templates/prompts/default/findings/prompt_v<active>.md
EOF
}

write_official_track_card() {
	local workdir="$1"
	local card="$2"
	local track="$3"
	local current_phase="$4"
	local previous_phase="$5"
	local intake_dir="$workdir/out/$card/intake"

	mkdir -p "$intake_dir"

	cat >"$intake_dir/state_card_official.yaml" <<EOF
card_state:
  track_id: $track
  previous_phase: $previous_phase
  current_phase: $current_phase
  completed_phases:
    - $previous_phase
EOF
}

write_invalid_card() {
	local workdir="$1"
	local card="$2"
	local intake_dir="$workdir/out/$card/intake"

	mkdir -p "$intake_dir"

	cat >"$intake_dir/track_prompt_path.yaml" <<'EOF'
track:
  id: declarative
  initial_phase: analysis
  final_phase: analysis
  phases:
    - analysis
EOF

	cat >"$intake_dir/state_card_prompt_path.yaml" <<'EOF'
card_state:
  track_id: declarative
  previous_phase: null
  current_phase: analysis
  completed_phases: []
EOF

	cat >"$intake_dir/phase_analysis.yaml" <<'EOF'
phase:
  id: analysis
  prompt:
    path: templates/prompts/default/missing/prompt_v<active>.md
EOF
}

write_missing_official_track_card() {
	local workdir="$1"
	local card="$2"
	local intake_dir="$workdir/out/$card/intake"

	mkdir -p "$intake_dir"

	cat >"$intake_dir/state_card_missing.yaml" <<'EOF'
card_state:
  track_id: ghost
  previous_phase: null
  current_phase: intake
  completed_phases: []
EOF
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

success_workdir="$tmp_root/workdir-success"
failure_workdir="$tmp_root/workdir-failure"
missing_track_workdir="$tmp_root/workdir-missing-track"

init_workdir "$success_workdir"
write_valid_card "$success_workdir" "537SUCCESS"
write_official_track_card "$success_workdir" "538OFFICIAL" "standard" "findings" "intake"
write_official_track_card "$success_workdir" "539FEATURE" "feature" "findings" "intake"
write_official_track_card "$success_workdir" "539BUG" "bug" "findings" "intake"
write_official_track_card "$success_workdir" "539SPIKE" "spike" "findings" "intake"

EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" card "540FEATURE" --track feature "feature track smoke" >/dev/null
EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" card "540BUG" --track bug "bug track smoke" >/dev/null
EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" card "540SPIKE" --track spike "spike track smoke" >/dev/null

grep -Fq "track_id: feature" "$success_workdir/out/540FEATURE/intake/state_card_feature.yaml" || fail "card command did not create track_id: feature"
grep -Fq "track_id: bug" "$success_workdir/out/540BUG/intake/state_card_bug.yaml" || fail "card command did not create track_id: bug"
grep -Fq "track_id: spike" "$success_workdir/out/540SPIKE/intake/state_card_spike.yaml" || fail "card command did not create track_id: spike"

success_output="$(EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" validate 2>&1)" || fail "expected success validate to pass"
grep -Fq "current_phase=analysis prompt_phase=analyze_findings" <<<"$success_output" || fail "missing prompt_phase derived from prompt.path in success output"
grep -Fq "prompt_path=templates/prompts/default/findings/prompt_v<active>.md" <<<"$success_output" || fail "missing prompt_path in success output"
grep -Fq "workflow card=538OFFICIAL track=standard current_phase=findings prompt_phase=analyze_findings" <<<"$success_output" || fail "missing official track validation summary"
grep -Fq "workflow card=539FEATURE track=feature current_phase=findings prompt_phase=analyze_findings" <<<"$success_output" || fail "missing feature track validation summary"
grep -Fq "workflow card=539BUG track=bug current_phase=findings prompt_phase=analyze_findings" <<<"$success_output" || fail "missing bug track validation summary"
grep -Fq "workflow card=539SPIKE track=spike current_phase=findings prompt_phase=analyze_findings" <<<"$success_output" || fail "missing spike track validation summary"
if grep -Fq "inconsistent with phase.id" <<<"$success_output"; then
	fail "unexpected phase.id consistency error in success output"
fi

init_workdir "$failure_workdir"
write_invalid_card "$failure_workdir" "537FAIL"

set +e
failure_output="$(EAW_WORKDIR="$failure_workdir" "$REPO_ROOT/scripts/eaw" validate 2>&1)"
failure_rc=$?
set -e

[[ "$failure_rc" -ne 0 ]] || fail "expected invalid prompt.path validate to fail"
grep -Fq "phase file '$failure_workdir/out/537FAIL/intake/phase_analysis.yaml' has prompt.path 'templates/prompts/default/missing/prompt_v<active>.md' that is not resolvable via ACTIVE" <<<"$failure_output" || fail "missing actionable invalid prompt.path error"

init_workdir "$missing_track_workdir"
write_missing_official_track_card "$missing_track_workdir" "537MISSING"

set +e
missing_track_output="$(EAW_WORKDIR="$missing_track_workdir" "$REPO_ROOT/scripts/eaw" validate 2>&1)"
missing_track_rc=$?
set -e

[[ "$missing_track_rc" -ne 0 ]] || fail "expected missing official track validate to fail"
grep -Fq "no official track 'ghost' was found" <<<"$missing_track_output" || fail "missing actionable missing official track error"

printf "workflow_prompt_path_smoke OK\n"
