#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

export EAW_WORKDIR="$WORK_ROOT/.eaw"

"$ROOT_DIR/scripts/eaw" init --workdir "$EAW_WORKDIR" >/dev/null

header_template="$EAW_WORKDIR/templates/prompts/default/intake/prompt_v1.md"
intake_feature_template="$EAW_WORKDIR/templates/intake_feature.md"
repo_header_template="$ROOT_DIR/templates/prompts/default/intake/prompt_v1.md"
repo_intake_feature_template="$ROOT_DIR/templates/intake_feature.md"

printf "STALE HEADER\n" >"$header_template"
printf "STALE FEATURE TEMPLATE\n" >"$intake_feature_template"

"$ROOT_DIR/scripts/eaw" init --workdir "$EAW_WORKDIR" --upgrade >/dev/null

cmp -s "$header_template" "$repo_header_template"
cmp -s "$intake_feature_template" "$repo_intake_feature_template"

repo_default_dir="$ROOT_DIR/templates/prompts/default"
work_default_dir="$EAW_WORKDIR/templates/prompts/default"
phases=(
	"intake"
	"analyze_findings"
	"analyze_hypotheses"
	"analyze_planning"
	"implementation_planning"
	"implementation_executor"
)

for phase in "${phases[@]}"; do
	test -f "$repo_default_dir/$phase/prompt_v1.md"
	test -f "$repo_default_dir/$phase/prompt_v1.meta"
	test -f "$repo_default_dir/$phase/ACTIVE"
done

mkdir -p "$work_default_dir"
cp -R "$repo_default_dir/." "$work_default_dir/"

PROMPT_DIR="$EAW_WORKDIR/templates/prompts/lifecycle_test/intake"
mkdir -p "$PROMPT_DIR"

cat >"$PROMPT_DIR/prompt_v1.md" <<'EOF'
ROLE
PROMPT HEADER
OBJECTIVE
MANDATORY CHECK
INPUT
fixture
OUTPUT
fixture
READ_SCOPE
fixture
WRITE_SCOPE
fixture
FORBIDDEN
none
FAIL_CONDITIONS
fixture
EOF

cat >"$PROMPT_DIR/prompt_v1.meta" <<'EOF'
version=v1
required_substrings=PROMPT HEADER|MANDATORY CHECK
forbidden_words=BLOCKED TOKEN
EOF

cat >"$PROMPT_DIR/prompt_v2.md" <<'EOF'
ROLE
PROMPT HEADER
OBJECTIVE
MANDATORY CHECK
INPUT
fixture
OUTPUT
fixture
READ_SCOPE
fixture
WRITE_SCOPE
fixture
FORBIDDEN
BLOCKED TOKEN
FAIL_CONDITIONS
fixture
EOF

cat >"$PROMPT_DIR/prompt_v2.meta" <<'EOF'
version=v2
required_substrings=PROMPT HEADER|MANDATORY CHECK
forbidden_words=BLOCKED TOKEN
EOF

printf "v0\n" >"$PROMPT_DIR/ACTIVE"

before_non_active="$(cksum "$PROMPT_DIR/prompt_v1.md" "$PROMPT_DIR/prompt_v1.meta" "$PROMPT_DIR/prompt_v2.md" "$PROMPT_DIR/prompt_v2.meta")"
before_active="$(cat "$PROMPT_DIR/ACTIVE")"
before_templates="$(cksum "$PROMPT_DIR/prompt_v1.md" "$PROMPT_DIR/prompt_v1.meta" "$PROMPT_DIR/prompt_v2.md" "$PROMPT_DIR/prompt_v2.meta" "$PROMPT_DIR/ACTIVE")"

EAW_WORKDIR="$WORK_ROOT/.eaw" "$ROOT_DIR/scripts/eaw" propose-prompt 501 lifecycle_test intake v1 v2 >/dev/null

PROPOSAL_DIR="$EAW_WORKDIR/out/501/proposals"
test -f "$PROPOSAL_DIR/10_prompt_proposal.md"
test -f "$PROPOSAL_DIR/20_prompt_diff.txt"
test -f "$PROPOSAL_DIR/30_prompt_candidate.meta"
test -f "$PROPOSAL_DIR/31_prompt_candidate.md"
test -f "$PROPOSAL_DIR/40_proposal_result.md"
grep -F "candidate generated; not applied" "$PROPOSAL_DIR/40_proposal_result.md" >/dev/null
grep -F "timestamp:" "$PROPOSAL_DIR/40_proposal_result.md" >/dev/null
grep -F "exit_code: 0" "$PROPOSAL_DIR/40_proposal_result.md" >/dev/null
grep -F "@@" "$PROPOSAL_DIR/20_prompt_diff.txt" >/dev/null

EAW_WORKDIR="$WORK_ROOT/.eaw" "$ROOT_DIR/scripts/eaw" suggest-prompt 505 --track default --phase intake >/dev/null

SUGGEST_DIR="$EAW_WORKDIR/out/505/proposals"
test -f "$SUGGEST_DIR/prompt_patch_001.md"
test -f "$SUGGEST_DIR/prompt_patch_001.diff"
test -f "$SUGGEST_DIR/prompt_patch_001.result.md"
grep -F "status: PASS" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "exit_code: 0" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "safe_track: PASS" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "proposal_diff: PASS" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "ROLE:" "$SUGGEST_DIR/prompt_patch_001.md" >/dev/null
grep -F "@@" "$SUGGEST_DIR/prompt_patch_001.diff" >/dev/null

set +e
EAW_WORKDIR="$WORK_ROOT/.eaw" "$ROOT_DIR/scripts/eaw" suggest-prompt 505 --track '../x' --phase intake >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
	echo "expected suggest-prompt invalid track to fail" >&2
	exit 1
fi
grep -F "status: FAIL" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "safe_track: FAIL" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null

set +e
EAW_WORKDIR="$WORK_ROOT/.eaw" "$ROOT_DIR/scripts/eaw" suggest-prompt 505 --track default --phase missing_phase >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
	echo "expected suggest-prompt missing_phase to fail" >&2
	exit 1
fi
grep -F "status: FAIL" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "exit_code: 1" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
grep -F "phase_directory: FAIL" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null
test ! -e "$EAW_WORKDIR/templates/prompts/default/missing_phase/ACTIVE"

if [[ "$(cat "$PROMPT_DIR/ACTIVE")" != "$before_active" ]]; then
	echo "ACTIVE changed during propose-prompt" >&2
	exit 1
fi

after_proposal_templates="$(cksum "$PROMPT_DIR/prompt_v1.md" "$PROMPT_DIR/prompt_v1.meta" "$PROMPT_DIR/prompt_v2.md" "$PROMPT_DIR/prompt_v2.meta" "$PROMPT_DIR/ACTIVE")"
if [[ "$before_templates" != "$after_proposal_templates" ]]; then
	echo "templates changed during propose-prompt" >&2
	exit 1
fi

set +e
"$ROOT_DIR/scripts/eaw" apply-prompt lifecycle_test missing-phase v1 >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
	echo "expected apply-prompt missing-phase to fail" >&2
	exit 1
fi
if [[ -e "$EAW_WORKDIR/templates/prompts/lifecycle_test/missing-phase/ACTIVE" ]]; then
	echo "ACTIVE should not be created for missing prompt phase directory" >&2
	exit 1
fi

EAW_WORKDIR="$WORK_ROOT/.eaw" "$ROOT_DIR/scripts/eaw" validate-prompt lifecycle_test intake v1 >/dev/null

set +e
"$ROOT_DIR/scripts/eaw" validate-prompt lifecycle_test intake v2 >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
	echo "expected validate-prompt v2 to fail" >&2
	exit 1
fi

"$ROOT_DIR/scripts/eaw" apply-prompt lifecycle_test intake v1 >/dev/null

if [[ "$(cat "$PROMPT_DIR/ACTIVE")" != "v1" ]]; then
	echo "ACTIVE was not updated to v1" >&2
	exit 1
fi

after_non_active="$(cksum "$PROMPT_DIR/prompt_v1.md" "$PROMPT_DIR/prompt_v1.meta" "$PROMPT_DIR/prompt_v2.md" "$PROMPT_DIR/prompt_v2.meta")"
if [[ "$before_non_active" != "$after_non_active" ]]; then
	echo "non-ACTIVE prompt artifacts changed" >&2
	exit 1
fi

special_title='Prompt/lifecycle & back\slash | smoke'
feature_log="$WORK_ROOT/feature.log"
"$ROOT_DIR/scripts/eaw" feature 550 "$special_title" >"$feature_log" 2>&1
grep -F "$special_title" "$EAW_WORKDIR/out/550/feature_550.md" >/dev/null
if grep -F "unknown option to \`s'" "$feature_log" >/dev/null; then
	echo "render_template still fails for title with slash" >&2
	exit 1
fi

for phase in "${phases[@]}"; do
	phase_dir="$EAW_WORKDIR/templates/prompts/default/$phase"
	before_md="$(cksum "$phase_dir/prompt_v1.md")"
	before_meta="$(cksum "$phase_dir/prompt_v1.meta")"

	"$ROOT_DIR/scripts/eaw" validate-prompt default "$phase" v1 >/dev/null
	"$ROOT_DIR/scripts/eaw" apply-prompt default "$phase" v1 >/dev/null

	if [[ "$(cat "$phase_dir/ACTIVE")" != "v1" ]]; then
		echo "ACTIVE was not updated to v1 for default/$phase" >&2
		exit 1
	fi
	if [[ "$before_md" != "$(cksum "$phase_dir/prompt_v1.md")" ]]; then
		echo "prompt_v1.md changed during apply-prompt for default/$phase" >&2
		exit 1
	fi
	if [[ "$before_meta" != "$(cksum "$phase_dir/prompt_v1.meta")" ]]; then
		echo "prompt_v1.meta changed during apply-prompt for default/$phase" >&2
		exit 1
	fi
done

grep -Fq "validate-prompt" "$ROOT_DIR/docs/integration.md"
grep -Fq "apply-prompt" "$ROOT_DIR/docs/integration.md"
grep -Fq "templates/prompts/<track>/<phase>/" "$ROOT_DIR/docs/integration.md"
grep -Fq "default/intake" "$ROOT_DIR/docs/integration.md"
grep -Fq "default/analyze_findings" "$ROOT_DIR/docs/integration.md"
grep -Fq "default/analyze_hypotheses" "$ROOT_DIR/docs/integration.md"
grep -Fq "default/analyze_planning" "$ROOT_DIR/docs/integration.md"
grep -Fq "default/implementation_planning" "$ROOT_DIR/docs/integration.md"
grep -Fq "default/implementation_executor" "$ROOT_DIR/docs/integration.md"

"$ROOT_DIR/scripts/eaw" feature 500 "Prompt lifecycle smoke" >/dev/null
"$ROOT_DIR/scripts/eaw" doctor >/dev/null
"$ROOT_DIR/scripts/eaw" validate >/dev/null

for phase in "${phases[@]}"; do
	phase_dir="$EAW_WORKDIR/templates/prompts/default/$phase"
	cp "$phase_dir/prompt_v1.md" "$phase_dir/prompt_v2.md"
	printf "\nACTIVE_BINDING_OK default/%s v2\n" "$phase" >>"$phase_dir/prompt_v2.md"
	printf "v2\n" >"$phase_dir/ACTIVE"
done

"$ROOT_DIR/scripts/eaw" intake 500 --round=1 >/dev/null
"$ROOT_DIR/scripts/eaw" analyze 500 >/dev/null
"$ROOT_DIR/scripts/eaw" implement 500 >/dev/null

test -f "$EAW_WORKDIR/out/500/investigations/intake_agent_prompt.round_1.md"
test -f "$EAW_WORKDIR/out/500/investigations/findings_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/investigations/hypotheses_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/investigations/planning_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/implementation/implementation_planning_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/implementation/implementation_executor_agent_prompt.md"

provenance_file="$EAW_WORKDIR/out/500/provenance/prompts_used.yaml"
test -f "$provenance_file"

grep -F "ACTIVE_BINDING_OK default/intake v2" "$EAW_WORKDIR/out/500/investigations/intake_agent_prompt.round_1.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_findings v2" "$EAW_WORKDIR/out/500/investigations/findings_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_hypotheses v2" "$EAW_WORKDIR/out/500/investigations/hypotheses_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_planning v2" "$EAW_WORKDIR/out/500/investigations/planning_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/implementation_planning v2" "$EAW_WORKDIR/out/500/implementation/implementation_planning_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/implementation_executor v2" "$EAW_WORKDIR/out/500/implementation/implementation_executor_agent_prompt.md" >/dev/null
grep -F "phase: intake" "$provenance_file" >/dev/null
grep -F "phase: analyze_findings" "$provenance_file" >/dev/null
grep -F "phase: analyze_hypotheses" "$provenance_file" >/dev/null
grep -F "phase: analyze_planning" "$provenance_file" >/dev/null
grep -F "phase: implementation_planning" "$provenance_file" >/dev/null
grep -F "phase: implementation_executor" "$provenance_file" >/dev/null
grep -Eq "prompt_used: intake_v[0-9]+" "$provenance_file"
grep -Eq "prompt_used: analyze_findings_v[0-9]+" "$provenance_file"
grep -Eq "prompt_used: analyze_hypotheses_v[0-9]+" "$provenance_file"
grep -Eq "prompt_used: analyze_planning_v[0-9]+" "$provenance_file"
grep -Eq "prompt_used: implementation_planning_v[0-9]+" "$provenance_file"
grep -Eq "prompt_used: implementation_executor_v[0-9]+" "$provenance_file"
grep -F "source_root:" "$provenance_file" >/dev/null
grep -F "phase_dir:" "$provenance_file" >/dev/null
grep -F "active:" "$provenance_file" >/dev/null
grep -F "file:" "$provenance_file" >/dev/null
echo "ACTIVE_BINDING_OK"
