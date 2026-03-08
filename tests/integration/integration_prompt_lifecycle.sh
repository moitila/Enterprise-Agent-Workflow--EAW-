#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

export EAW_WORKDIR="$WORK_ROOT/.eaw"
"$REPO_ROOT/scripts/eaw" init --workdir "$EAW_WORKDIR" >/dev/null

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

"$REPO_ROOT/scripts/eaw" propose-prompt 501 lifecycle_test intake v1 v2 >/dev/null
PROPOSAL_DIR="$EAW_WORKDIR/out/501/proposals"
test -f "$PROPOSAL_DIR/10_prompt_proposal.md"
test -f "$PROPOSAL_DIR/20_prompt_diff.txt"
test -f "$PROPOSAL_DIR/40_proposal_result.md"
grep -F "candidate generated; not applied" "$PROPOSAL_DIR/40_proposal_result.md" >/dev/null

"$REPO_ROOT/scripts/eaw" suggest-prompt 505 --track default --phase intake >/dev/null
SUGGEST_DIR="$EAW_WORKDIR/out/505/proposals"
test -f "$SUGGEST_DIR/prompt_patch_001.result.md"
grep -F "status: PASS" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null

set +e
"$REPO_ROOT/scripts/eaw" suggest-prompt 506 --track invalid_track --phase intake >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

set +e
"$REPO_ROOT/scripts/eaw" suggest-prompt 507 --track default --phase phase_inexistente >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

"$REPO_ROOT/scripts/eaw" validate-prompt lifecycle_test intake v1 >/dev/null
set +e
"$REPO_ROOT/scripts/eaw" validate-prompt lifecycle_test intake v2 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

"$REPO_ROOT/scripts/eaw" apply-prompt lifecycle_test intake v1 >/dev/null
[[ "$(cat "$PROMPT_DIR/ACTIVE")" == "v1" ]]

set +e
"$REPO_ROOT/scripts/eaw" apply-prompt lifecycle_test phase_inexistente v1 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

phases=(
	"intake"
	"analyze_findings"
	"analyze_hypotheses"
	"analyze_planning"
	"implementation_planning"
	"implementation_executor"
)
for phase in "${phases[@]}"; do
	phase_dir="$EAW_WORKDIR/templates/prompts/default/$phase"
	cp "$phase_dir/prompt_v1.md" "$phase_dir/prompt_v2.md"
	cp "$phase_dir/prompt_v1.meta" "$phase_dir/prompt_v2.meta"
	printf "\nACTIVE_BINDING_OK default/%s v2\n" "$phase" >>"$phase_dir/prompt_v2.md"
	printf "v2\n" >"$phase_dir/ACTIVE"
done

default_intake_dir="$EAW_WORKDIR/templates/prompts/default/intake"
printf "v999\n" >"$default_intake_dir/ACTIVE"
"$REPO_ROOT/scripts/eaw" feature 499 "Invalid active prompt guardrail" >/dev/null
set +e
"$REPO_ROOT/scripts/eaw" intake 499 --round=1 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]
test ! -f "$EAW_WORKDIR/out/499/investigations/intake_agent_prompt.round_1.md"
printf "v2\n" >"$default_intake_dir/ACTIVE"

"$REPO_ROOT/scripts/eaw" feature 500 "Prompt lifecycle integration" >/dev/null
"$REPO_ROOT/scripts/eaw" intake 500 --round=1 >/dev/null
"$REPO_ROOT/scripts/eaw" analyze 500 >/dev/null
"$REPO_ROOT/scripts/eaw" implement 500 >/dev/null

test -f "$EAW_WORKDIR/out/500/investigations/intake_agent_prompt.round_1.md"
test -f "$EAW_WORKDIR/out/500/investigations/findings_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/investigations/hypotheses_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/investigations/planning_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/implementation/implementation_planning_agent_prompt.md"
test -f "$EAW_WORKDIR/out/500/implementation/implementation_executor_agent_prompt.md"

grep -F "ACTIVE_BINDING_OK default/intake v2" "$EAW_WORKDIR/out/500/investigations/intake_agent_prompt.round_1.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_findings v2" "$EAW_WORKDIR/out/500/investigations/findings_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_hypotheses v2" "$EAW_WORKDIR/out/500/investigations/hypotheses_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_planning v2" "$EAW_WORKDIR/out/500/investigations/planning_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/implementation_planning v2" "$EAW_WORKDIR/out/500/implementation/implementation_planning_agent_prompt.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/implementation_executor v2" "$EAW_WORKDIR/out/500/implementation/implementation_executor_agent_prompt.md" >/dev/null

provenance_file="$EAW_WORKDIR/out/500/provenance/prompts_used.yaml"
test -f "$provenance_file"
grep -F "phase: intake" "$provenance_file" >/dev/null
grep -F "phase: analyze_findings" "$provenance_file" >/dev/null
grep -F "phase: analyze_hypotheses" "$provenance_file" >/dev/null
grep -F "phase: analyze_planning" "$provenance_file" >/dev/null
grep -F "phase: implementation_planning" "$provenance_file" >/dev/null
grep -F "phase: implementation_executor" "$provenance_file" >/dev/null
dups="$(awk '/phase:/{print $3}' "$provenance_file" | sort | uniq -d)"
[[ -z "$dups" ]]

printf "integration prompt lifecycle OK\n"
