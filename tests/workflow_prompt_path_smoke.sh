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

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

success_workdir="$tmp_root/workdir-success"
failure_workdir="$tmp_root/workdir-failure"

init_workdir "$success_workdir"
write_valid_card "$success_workdir" "537SUCCESS"

success_output="$(EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" validate 2>&1)" || fail "expected success validate to pass"
grep -Fq "current_phase=analysis prompt_phase=analyze_findings" <<<"$success_output" || fail "missing prompt_phase derived from prompt.path in success output"
grep -Fq "prompt_path=templates/prompts/default/findings/prompt_v<active>.md" <<<"$success_output" || fail "missing prompt_path in success output"
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

printf "workflow_prompt_path_smoke OK\n"
