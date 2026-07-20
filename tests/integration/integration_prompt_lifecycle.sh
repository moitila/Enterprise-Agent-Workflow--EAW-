#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

RUNTIME_ROOT="$WORK_ROOT/runtime"
mkdir -p "$RUNTIME_ROOT"
cp -R "$REPO_ROOT/scripts" "$RUNTIME_ROOT/"
cp -R "$REPO_ROOT/templates" "$RUNTIME_ROOT/"
cp -R "$REPO_ROOT/tracks" "$RUNTIME_ROOT/"
cp -R "$REPO_ROOT/config" "$RUNTIME_ROOT/"

export EAW_WORKDIR="$WORK_ROOT/.eaw"
"$RUNTIME_ROOT/scripts/eaw" init --workdir "$EAW_WORKDIR" >/dev/null

PROMPT_DIR="$RUNTIME_ROOT/templates/prompts/lifecycle_test/intake"
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

"$RUNTIME_ROOT/scripts/eaw" propose-prompt 501 lifecycle_test intake v1 v2 >/dev/null
PROPOSAL_DIR="$EAW_WORKDIR/out/501/proposals"
test -f "$PROPOSAL_DIR/10_prompt_proposal.md"
test -f "$PROPOSAL_DIR/20_prompt_diff.txt"
test -f "$PROPOSAL_DIR/40_proposal_result.md"
grep -F "candidate generated; not applied" "$PROPOSAL_DIR/40_proposal_result.md" >/dev/null

"$RUNTIME_ROOT/scripts/eaw" suggest-prompt 505 --track default --phase intake >/dev/null
SUGGEST_DIR="$EAW_WORKDIR/out/505/proposals"
test -f "$SUGGEST_DIR/prompt_patch_001.result.md"
grep -F "status: PASS" "$SUGGEST_DIR/prompt_patch_001.result.md" >/dev/null

set +e
"$RUNTIME_ROOT/scripts/eaw" suggest-prompt 506 --track invalid_track --phase intake >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

set +e
"$RUNTIME_ROOT/scripts/eaw" suggest-prompt 507 --track default --phase phase_inexistente >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

"$RUNTIME_ROOT/scripts/eaw" validate-prompt lifecycle_test intake v1 >/dev/null
set +e
"$RUNTIME_ROOT/scripts/eaw" validate-prompt lifecycle_test intake v2 >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]

"$RUNTIME_ROOT/scripts/eaw" apply-prompt lifecycle_test intake v1 >/dev/null
[[ "$(cat "$PROMPT_DIR/ACTIVE")" == "v1" ]]

set +e
"$RUNTIME_ROOT/scripts/eaw" apply-prompt lifecycle_test phase_inexistente v1 >/dev/null 2>&1
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
	phase_dir="$RUNTIME_ROOT/templates/prompts/default/$phase"
	cp "$phase_dir/prompt_v1.md" "$phase_dir/prompt_v2.md"
	cp "$phase_dir/prompt_v1.meta" "$phase_dir/prompt_v2.meta"
	printf "\nACTIVE_BINDING_OK default/%s v2\n" "$phase" >>"$phase_dir/prompt_v2.md"
	printf "v2\n" >"$phase_dir/ACTIVE"
done

default_intake_dir="$RUNTIME_ROOT/templates/prompts/default/intake"
printf "v999\n" >"$default_intake_dir/ACTIVE"
set +e
"$RUNTIME_ROOT/scripts/eaw" card 499 --track standard "Invalid active prompt guardrail" >/dev/null 2>&1
rc=$?
set -e
[[ "$rc" -ne 0 ]]
test ! -f "$EAW_WORKDIR/out/499/prompts/intake.md"
printf "v2\n" >"$default_intake_dir/ACTIVE"

"$RUNTIME_ROOT/scripts/eaw" card 500 --track standard "Prompt lifecycle integration" >/dev/null
cat >"$EAW_WORKDIR/out/500/investigations/00_intake.md" <<'EOF'
# intake ok

Prompt lifecycle integration fixture with deterministic substantive content. This intake
artifact is intentionally larger than the minimum content gate so the test can focus on
prompt binding and provenance behavior rather than placeholder rejection. It avoids
timestamps, random values, local absolute paths, and command output.

The fixture confirms that the standard track can advance from intake after active prompt
bindings are switched to v2. The resulting prompts should include the ACTIVE_BINDING_OK
markers injected above, and provenance should record each prompt phase once.
EOF
cat >"$EAW_WORKDIR/out/500/investigations/_intake_provenance.md" <<'EOF'
# provenance ok

Prompt lifecycle integration provenance fixture. This file documents that the intake
artifact was prepared by the test harness, that no external context is required, and that
the workflow should advance only because both intake artifacts are meaningfully filled.

The text is deterministic and intentionally above the runtime content floor so it remains
stable across Linux CI and local validation while exercising prompt lifecycle behavior.
It also records that the active prompt files were copied into an isolated runtime root,
that the card was created after ACTIVE was moved to v2, and that the expected next action is
to materialize findings without mutating the prompt template source. This additional detail
keeps the fixture representative of a real provenance note instead of a short placeholder.
EOF
"$RUNTIME_ROOT/scripts/eaw" next 500 >/dev/null
cat >"$EAW_WORKDIR/out/500/investigations/20_findings.md" <<'EOF'
# findings ok

Prompt lifecycle integration findings fixture with enough deterministic detail to satisfy
the content gate. The test does not validate findings prose quality; it validates that the
active default/analyze_findings prompt binding is materialized and recorded in provenance.

The content avoids timestamps, random values, command output, and local paths. It simply
represents a completed findings phase so the lifecycle can advance to hypotheses.
The findings phase confirms the card scaffold, active prompt binding, rendered prompt
location, and provenance flow are all available. It also records that no target repository
mutation is required for this integration fixture. The next phase should be hypotheses, and
the test will verify the default/analyze_hypotheses marker after materialization.
EOF
"$RUNTIME_ROOT/scripts/eaw" next 500 >/dev/null
cat >"$EAW_WORKDIR/out/500/investigations/30_hypotheses.md" <<'EOF'
# hypotheses ok

Prompt lifecycle integration hypotheses fixture. This deterministic artifact is long enough
for the meaningful-content validator and exists only to allow the standard workflow to
advance into planning while preserving the prompt binding assertions below.

The test expects the default/analyze_hypotheses v2 prompt marker to appear in the rendered
prompt and in provenance. No environment-specific data is required.
The selected hypothesis is that prompt lifecycle binding remains stable across sequential
phase transitions. This fixture intentionally uses deterministic prose so the runtime can
distinguish it from a placeholder while the integration continues to focus on rendered
prompt markers rather than domain analysis content.
EOF
"$RUNTIME_ROOT/scripts/eaw" next 500 >/dev/null
cat >"$EAW_WORKDIR/out/500/investigations/40_next_steps.md" <<'EOF'
# planning ok

Prompt lifecycle integration planning fixture with deterministic substantive content. It
allows the workflow to advance to implementation planning after the active planning prompt
binding has been changed to v2.

The artifact intentionally avoids timestamps, random values, local paths, and command
output. Its role is to be a stable completed planning output for prompt lifecycle checks.
The plan is to continue into implementation planning, materialize the implementation
planning prompt from the active v2 binding, and then produce the two implementation planning
artifacts required by the standard track. The final assertions verify prompt provenance for
each phase and ensure duplicate phase records are not emitted.
EOF
"$RUNTIME_ROOT/scripts/eaw" next 500 >/dev/null
mkdir -p "$EAW_WORKDIR/out/500/implementation"
cat >"$EAW_WORKDIR/out/500/implementation/00_scope.lock.md" <<'EOF'
# scope lock ok

## Base Obrigatoria

Prompt lifecycle integration uses the rendered prompt provenance as the base.

## Hipotese(s) Base

The active prompt binding selected for each default phase should be reflected in rendered prompts.

## Contexto

This fixture is deterministic and does not require repository writes outside the test card.

## In Scope

Validate prompt materialization, provenance entries, and implementation executor prompt binding.

## Out of Scope

No production source files are modified by this integration fixture.

## Allowlist de Escrita

write_allowlist:
  - tests/integration/integration_prompt_lifecycle.sh

## Regra de Escrita

Prompt lifecycle integration scope lock fixture. This deterministic content is above the
runtime minimum and represents a completed implementation planning artifact so the test can
advance to implementation executor and verify prompt binding provenance.
EOF
cat >"$EAW_WORKDIR/out/500/implementation/10_change_plan.md" <<'EOF'
# change plan ok

## Objetivo de Execucao

Advance the standard workflow through implementation executor prompt materialization.

## Hipotese(s) Selecionada(s)

The v2 prompt binding is selected consistently for every default prompt phase.

## Assuncoes Explicitas

The test runtime is isolated, deterministic, and does not depend on external repositories.

## Steps

1. Verify rendered prompt markers.
2. Verify provenance entries for each phase.
3. Verify duplicate prompt provenance records are not emitted.

## Validacao Tecnica Obrigatoria

The integration script itself performs the assertions after all prompts are materialized.

## Rollback

Remove the temporary fixture runtime directory created by the test harness.

Prompt lifecycle integration change plan fixture. The plan is intentionally substantive and
stable: verify rendered prompt markers, verify provenance entries, and avoid external state.

This artifact exists only to satisfy the formal implementation planning completion gate so
the test can validate default/implementation_executor prompt binding behavior.
EOF
"$RUNTIME_ROOT/scripts/eaw" next 500 >/dev/null

test -f "$EAW_WORKDIR/out/500/prompts/intake.md"
test -f "$EAW_WORKDIR/out/500/prompts/findings.md"
test -f "$EAW_WORKDIR/out/500/prompts/hypotheses.md"
test -f "$EAW_WORKDIR/out/500/prompts/planning.md"
test -f "$EAW_WORKDIR/out/500/prompts/implementation_planning.md"
test -f "$EAW_WORKDIR/out/500/prompts/implementation_executor.md"

[[ "$(sed -n '1p' "$EAW_WORKDIR/out/500/prompts/intake.md")" == "RUNTIME_ENVIRONMENT" ]]
grep -F "ACTIVE_BINDING_OK default/intake v2" "$EAW_WORKDIR/out/500/prompts/intake.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_findings v2" "$EAW_WORKDIR/out/500/prompts/findings.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_hypotheses v2" "$EAW_WORKDIR/out/500/prompts/hypotheses.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/analyze_planning v2" "$EAW_WORKDIR/out/500/prompts/planning.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/implementation_planning v2" "$EAW_WORKDIR/out/500/prompts/implementation_planning.md" >/dev/null
grep -F "ACTIVE_BINDING_OK default/implementation_executor v2" "$EAW_WORKDIR/out/500/prompts/implementation_executor.md" >/dev/null

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
