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
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
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

write_official_track_card_without_completed() {
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
  completed_phases: []
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
write_official_track_card "$success_workdir" "539FEATURE" "feature" "findings" "ingest"
write_official_track_card "$success_workdir" "539BUG" "bug" "findings" "intake"
write_official_track_card "$success_workdir" "539SPIKE" "spike" "findings" "intake"

EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" card "540FEATURE" --track feature "feature track smoke" >/dev/null
EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" card "540BUG" --track bug "bug track smoke" >/dev/null
EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" card "540SPIKE" --track spike "spike track smoke" >/dev/null

grep -Fq "track_id: feature" "$success_workdir/out/540FEATURE/state_card_feature.yaml" || fail "card command did not create track_id: feature"
grep -Fq "track_id: bug" "$success_workdir/out/540BUG/state_card_bug.yaml" || fail "card command did not create track_id: bug"
grep -Fq "track_id: spike" "$success_workdir/out/540SPIKE/state_card_spike.yaml" || fail "card command did not create track_id: spike"

success_output="$(EAW_WORKDIR="$success_workdir" "$REPO_ROOT/scripts/eaw" validate 2>&1)" || fail "expected success validate to pass"
grep -Fq "current_phase=analysis prompt_phase=analyze_findings" <<<"$success_output" || fail "missing prompt_phase derived from prompt.path in success output"
grep -Fq "prompt_path=templates/prompts/default/analyze_findings/prompt_v<active>.md" <<<"$success_output" || fail "missing prompt_path in success output"
grep -Fq "workflow card=538OFFICIAL track=standard current_phase=findings prompt_phase=analyze_findings" <<<"$success_output" || fail "missing official track validation summary"
grep -Fq "workflow card=539FEATURE track=feature current_phase=findings prompt_phase=findings" <<<"$success_output" || fail "missing feature track validation summary"
grep -Fq "prompt_path=templates/prompts/feature/findings/prompt_v<active>.md" <<<"$success_output" || fail "missing feature track prompt_path summary"
grep -Fq "workflow card=539BUG track=bug current_phase=findings prompt_phase=findings" <<<"$success_output" || fail "missing bug track validation summary"
grep -Fq "prompt_path=templates/prompts/bug/findings/prompt_v<active>.md" <<<"$success_output" || fail "missing bug track prompt_path summary"
grep -Fq "workflow card=539SPIKE track=spike current_phase=findings prompt_phase=findings" <<<"$success_output" || fail "missing spike track validation summary"
grep -Fq "prompt_path=templates/prompts/spike/findings/prompt_v<active>.md" <<<"$success_output" || fail "missing spike track prompt_path summary"
if grep -Fq "inconsistent with phase.id" <<<"$success_output"; then
	fail "unexpected phase.id consistency error in success output"
fi

prompt_workdir="$tmp_root/workdir-prompts"
init_workdir "$prompt_workdir"
write_official_track_card_without_completed "$prompt_workdir" "544FEATURE" "feature" "findings" "ingest"
write_official_track_card_without_completed "$prompt_workdir" "544STANDARD" "standard" "findings" "intake"

feature_prompt_output="$(EAW_WORKDIR="$prompt_workdir" "$REPO_ROOT/scripts/eaw" next "544FEATURE" 2>&1)" || fail "expected feature findings prompt generation to pass"
standard_prompt_output="$(EAW_WORKDIR="$prompt_workdir" "$REPO_ROOT/scripts/eaw" next "544STANDARD" 2>&1)" || fail "expected standard findings prompt generation to pass"

feature_prompt="$prompt_workdir/out/544FEATURE/prompts/findings.md"
standard_prompt="$prompt_workdir/out/544STANDARD/prompts/findings.md"
feature_legacy_prompt="$prompt_workdir/out/544FEATURE/investigations/findings_agent_prompt.md"
standard_legacy_prompt="$prompt_workdir/out/544STANDARD/investigations/findings_agent_prompt.md"

grep -Fq "RUNTIME: wrote_prompt=prompts/findings.md" <<<"$feature_prompt_output" || fail "missing feature prompt artifact log"
grep -Fq "RUNTIME: wrote_prompt=prompts/findings.md" <<<"$standard_prompt_output" || fail "missing standard prompt artifact log"
grep -n "Tooling Hints" "$feature_prompt" >/dev/null || fail "missing Tooling Hints heading in feature prompt"
if grep -n "Tooling Hints" "$standard_prompt" >/dev/null; then
	fail "unexpected Tooling Hints heading in prompt without tooling_hints"
fi
if grep -En '<CARD>|<WORKDIR>|<OUTDIR>|<TARGET_REPO>|\{\{CARD\}\}|\{\{EAW_WORKDIR\}\}|\{\{OUT_DIR\}\}|\{\{TARGET_REPOS\}\}' "$feature_prompt" >/dev/null; then
	fail "feature prompt still contains unresolved tooling_hints placeholders"
fi
test ! -f "$feature_legacy_prompt" || fail "feature findings prompt should not be mirrored into investigations"
test ! -f "$standard_legacy_prompt" || fail "standard findings prompt should not be mirrored into investigations"

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

# --- phase.context validation tests (H5) ---
# Tests structural validation of phase.context via eaw validate workflow.
# Covers: phase without context, phase with dynamic_context_template only,
# phase with both fields, and phase with invalid context configuration.

context_valid_workdir="$tmp_root/workdir-context-valid"
context_invalid_workdir="$tmp_root/workdir-context-invalid"

init_workdir "$context_valid_workdir"

ctx_valid_track_dir="$context_valid_workdir/tracks/ctx-test/phases"
mkdir -p "$ctx_valid_track_dir"

cat >"$context_valid_workdir/tracks/ctx-test/track.yaml" <<'EOF'
track:
  id: ctx-test
  initial_phase: no-context
  final_phase: both-fields
  phases:
    - no-context
    - dynamic-only
    - both-fields
  transitions:
    no-context:
      next: dynamic-only
    dynamic-only:
      next: both-fields
EOF

# Fase sem context — fallback: comportamento legado preservado
cat >"$ctx_valid_track_dir/no-context.yaml" <<'EOF'
phase:
  id: no-context
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
EOF

# Fase com apenas dynamic_context_template
cat >"$ctx_valid_track_dir/dynamic-only.yaml" <<'EOF'
phase:
  id: dynamic-only
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
  context:
    dynamic_context_template: repo-diff
EOF

# Fase com ambos os campos (dynamic_context_template e onboarding_template)
cat >"$ctx_valid_track_dir/both-fields.yaml" <<'EOF'
phase:
  id: both-fields
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
  context:
    dynamic_context_template: repo-diff
    onboarding_template: workspace-onboarding
EOF

context_valid_output="$(EAW_WORKDIR="$context_valid_workdir" "$REPO_ROOT/scripts/eaw" validate workflow --track ctx-test 2>&1)" || fail "expected valid phase.context to pass validate workflow"
grep -Fq "OK track=ctx-test" <<<"$context_valid_output" || fail "missing OK for valid context track"

# Phase with invalid context (extra field) — should fail validate workflow
init_workdir "$context_invalid_workdir"

ctx_invalid_track_dir="$context_invalid_workdir/tracks/ctx-invalid/phases"
mkdir -p "$ctx_invalid_track_dir"

cat >"$context_invalid_workdir/tracks/ctx-invalid/track.yaml" <<'EOF'
track:
  id: ctx-invalid
  initial_phase: bad-context
  final_phase: bad-context
  phases:
    - bad-context
EOF

cat >"$ctx_invalid_track_dir/bad-context.yaml" <<'EOF'
phase:
  id: bad-context
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
  context:
    dynamic_context_template: repo-diff
    unsupported_field: bad-value
EOF

set +e
context_invalid_output="$(EAW_WORKDIR="$context_invalid_workdir" "$REPO_ROOT/scripts/eaw" validate workflow --track ctx-invalid 2>&1)"
context_invalid_rc=$?
set -e

[[ "$context_invalid_rc" -ne 0 ]] || fail "expected invalid phase.context (extra field) to fail validate workflow"
grep -Fq "unsupported context key" <<<"$context_invalid_output" || fail "missing unsupported context key error for extra field"

# Runtime failure: dynamic_context_template declared without materialized context
context_runtime_workdir="$tmp_root/workdir-context-runtime"
init_workdir "$context_runtime_workdir"

runtime_intake_dir="$context_runtime_workdir/out/545RUNTIME/intake"
mkdir -p "$runtime_intake_dir"

cat >"$runtime_intake_dir/track_runtime.yaml" <<'EOF'
track:
  id: ctx-runtime
  initial_phase: no-context
  final_phase: done
  phases:
    - no-context
    - dynamic-only
    - done
  transitions:
    no-context:
      next: dynamic-only
    dynamic-only:
      next: done
EOF

cat >"$runtime_intake_dir/phase_no_context.yaml" <<'EOF'
phase:
  id: no-context
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
EOF

cat >"$runtime_intake_dir/phase_dynamic_only.yaml" <<'EOF'
phase:
  id: dynamic-only
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
  context:
    dynamic_context_template: repo-diff
EOF

cat >"$runtime_intake_dir/phase_done.yaml" <<'EOF'
phase:
  id: done
  prompt:
    path: templates/prompts/default/analyze_findings/prompt_v<active>.md
EOF

cat >"$runtime_intake_dir/state_card_runtime.yaml" <<'EOF'
card_state:
  track_id: ctx-runtime
  previous_phase: no-context
  current_phase: dynamic-only
  completed_phases:
    - no-context
  phase_status: RUN
  phase_started_at: 2026-03-29T00:00:00Z
  phase_completed: false
  phase_completed_at: null
EOF

set +e
context_runtime_output="$(EAW_WORKDIR="$context_runtime_workdir" "$REPO_ROOT/scripts/eaw" next 545RUNTIME 2>&1)"
context_runtime_rc=$?
set -e

[[ "$context_runtime_rc" -ne 0 ]] || fail "expected dynamic context runtime without materialization to fail"
grep -Fq "context nao materializado" <<<"$context_runtime_output" || fail "missing deterministic runtime error for absent dynamic context"

printf "workflow_prompt_path_smoke OK\n"
