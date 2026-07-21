#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_implement failed: %s\n" "$1" >&2
	exit 1
}

CARD="abc-501"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export EAW_WORKDIR="$tmpdir/.eaw"
CARD_DIR="$EAW_WORKDIR/out/$CARD"
IMPL_DIR="$CARD_DIR/implementation"
INVESTIGATIONS_DIR="$CARD_DIR/investigations"

if [[ ! -f "./scripts/eaw" ]]; then
	echo "ERROR: must run from repo root containing scripts/eaw" >&2
	exit 1
fi

echo "SMOKE: card=$CARD"

bash ./scripts/eaw init --workdir "$EAW_WORKDIR" --upgrade >/dev/null 2>&1
bash ./scripts/eaw card "$CARD" --track standard "smoke implement" >/dev/null 2>&1
cat >"$INVESTIGATIONS_DIR/00_intake.md" <<'EOF'
# intake ok

Smoke implement intake fixture with deterministic substantive content. It exists only to
advance the standard workflow into findings while satisfying the runtime meaningful-content
gate. The text avoids timestamps, random values, local paths, and command output.

The implementation smoke validates that implementation planning and executor prompts are
materialized and that implementation artifacts exist as regular non-empty files.
It also records the expected path through findings, hypotheses, planning, implementation
planning, and implementation executor so the fixture is clearly not a generated scaffold.
The content is stable across Linux CI and local Windows/WSL validation because it avoids
wall-clock timestamps, host-specific absolute paths, random values, and command output.
EOF
cat >"$INVESTIGATIONS_DIR/_intake_provenance.md" <<'EOF'
# provenance ok

Smoke implement provenance fixture. This deterministic content documents that the intake
artifact was created by the test harness and that no external context is required.

The file is intentionally substantive so completion validation treats intake as filled and
allows the standard workflow to advance to findings.
It records that the harness created the intake artifact, that the card is isolated in a
temporary EAW workdir, and that no external repository context is necessary. The provenance
text is deliberately deterministic and long enough to satisfy the default runtime content
floor without changing what the smoke is meant to verify.
EOF
bash ./scripts/eaw next "$CARD" >/dev/null 2>&1
cat >"$INVESTIGATIONS_DIR/20_findings.md" <<'EOF'
# findings ok

Smoke implement findings fixture with enough deterministic content to satisfy the runtime
content gate. The scenario confirms that the implementation smoke can proceed through the
analysis phases before checking implementation artifacts and prompts.

The content avoids environment-specific data and keeps the behavioral assertions focused on
the implement command surface.
The findings fixture also records that intake and provenance were accepted, that findings is
the current phase before hypotheses, and that no repository writes should occur while this
analysis artifact is being prepared. It names the expected downstream artifacts so the file
is clearly a substantive phase output rather than a scaffold: hypotheses, planning,
implementation scope lock, implementation change plan, executor prompt, and patch notes.
EOF
bash ./scripts/eaw next "$CARD" >/dev/null 2>&1
cat >"$INVESTIGATIONS_DIR/30_hypotheses.md" <<'EOF'
# hypotheses ok

Smoke implement hypotheses fixture. The selected hypothesis is that implementation planning
and executor prompts are generated after the standard track reaches those phases.

This artifact is intentionally above the minimum size floor and deterministic across CI and
local validation environments.
It records a single smoke hypothesis: once findings are complete, the standard track should
materialize planning and then implementation planning without requiring source repository
mutation. This content is deliberately stable and long enough for the completion gate while
remaining narrowly focused on the implement smoke's file and prompt assertions.
EOF
bash ./scripts/eaw next "$CARD" >/dev/null 2>&1
cat >"$INVESTIGATIONS_DIR/40_next_steps.md" <<'EOF'
# planning ok

Smoke implement planning fixture. The plan is to advance into implementation planning,
write scope and change plan artifacts, and verify implementation prompts plus patch notes.

The fixture is deterministic and substantive so the runtime content gate accepts it without
turning this test into a prose-quality check.

The planning output explicitly states that implementation planning is in scope, that the
next phase should create or preserve implementation artifacts in the card directory, and
that the smoke will provide scope lock and change plan content before asking the runtime to
materialize the executor prompt. This extra deterministic detail keeps the artifact above
the default size floor while preserving the test's narrow purpose.

Additional stable detail: the implementation smoke is intentionally not exercising source
patch application, repository mutation, branch creation, or rollback behavior. It is only
checking the phase-driven workflow path from analysis artifacts into implementation
planning and then into implementation executor. The fixture therefore names the expected
artifacts, records that they belong under the temporary card directory, and keeps all data
independent of wall-clock time, local absolute paths, random values, command output, and
machine-specific checkout configuration.
EOF
bash ./scripts/eaw next "$CARD" >/dev/null 2>&1
mkdir -p "$IMPL_DIR"
cat >"$IMPL_DIR/00_scope.lock.md" <<'EOF'
# scope lock ok

## Base Obrigatoria

Smoke implement standard workflow fixture.

## Hipotese(s) Base

Implementation prompts and artifacts are generated once prior phases are complete.

## Contexto

The test uses an isolated EAW_WORKDIR and no target source mutation.

## In Scope

Verify implementation planning prompt, executor prompt, scope lock, change plan, and patch notes.

## Out of Scope

No production source edits are performed by this smoke.

## Allowlist de Escrita

write_allowlist:
  - tests/smoke_implement.sh

## Regra de Escrita

Only the smoke fixture card directory is written during validation.
The scope lock is deliberately deterministic, includes every heading required by the
standard implementation planning contract, and stays above the runtime content floor. It
does not authorize writes to production source files; it only allows the smoke fixture to
verify implementation prompt and artifact behavior inside the temporary EAW workdir.
EOF
cat >"$IMPL_DIR/10_change_plan.md" <<'EOF'
# change plan ok

## Objetivo de Execucao

Advance the standard workflow to implementation executor.

## Hipotese(s) Selecionada(s)

The implementation prompt lifecycle is available after implementation planning artifacts exist.

## Assuncoes Explicitas

The test runtime is isolated and deterministic.

## Steps

1. Materialize implementation planning.
2. Provide scope lock and change plan.
3. Materialize implementation executor.
4. Verify artifacts and prompts.

## Validacao Tecnica Obrigatoria

The smoke asserts file existence, regular file status, non-empty content, and prompt sections.

## Rollback

Remove the temporary workdir created by the smoke harness.
The change plan is deliberately deterministic, includes every heading required by the
standard implementation planning contract, and stays above the runtime content floor. It
does not describe a production implementation; it only supplies enough formal plan content
for the runtime to advance into the implementation executor phase during the smoke.
EOF
bash ./scripts/eaw next "$CARD" >/dev/null 2>&1
cat >"$IMPL_DIR/20_patch_notes.md" <<'EOF'
# patch notes ok

Smoke implement patch notes fixture. The executor phase is now materialized, and this
non-empty artifact represents the implementation result expected by the smoke assertions.

The content is deterministic and local to the temporary card directory. It avoids timestamps,
random values, command output, and production source changes while proving the implementation
artifact path can be written and validated.
EOF
echo "SMOKE: implement OK"

if [[ ! -d "$IMPL_DIR" ]]; then
	echo "ERROR: missing implement artifact: $IMPL_DIR" >&2
	exit 1
fi

	PROMPTS_DIR="$CARD_DIR/prompts"
	for path in \
		"$IMPL_DIR/00_scope.lock.md" \
		"$IMPL_DIR/10_change_plan.md" \
		"$IMPL_DIR/20_patch_notes.md" \
		"$PROMPTS_DIR/implementation_planning.md" \
		"$PROMPTS_DIR/implementation_executor.md"; do
	if [[ ! -e "$path" ]]; then
		echo "ERROR: missing implement artifact: $path" >&2
		exit 1
	fi
	if [[ ! -f "$path" ]]; then
		echo "ERROR: implement artifact not a regular file: $path" >&2
		exit 1
	fi
	if [[ ! -s "$path" ]]; then
		echo "ERROR: empty implement artifact: $path" >&2
		exit 1
	fi
	done
	grep -Fq "ROLE" "$PROMPTS_DIR/implementation_planning.md" || fail "missing planning prompt ROLE section"
	grep -Fq "OBJECTIVE" "$PROMPTS_DIR/implementation_planning.md" || fail "missing planning prompt OBJECTIVE section"
	grep -Fq "ROLE" "$PROMPTS_DIR/implementation_executor.md" || fail "missing executor prompt ROLE section"
	grep -Fq "OBJECTIVE" "$PROMPTS_DIR/implementation_executor.md" || fail "missing executor prompt OBJECTIVE section"
	echo "SMOKE: artifacts OK"

set +e
bash ./scripts/eaw validate >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -ne 0 ]]; then
	echo "ERROR: validate failed" >&2
	exit "$rc"
fi

echo "SMOKE: validate OK"
echo "SMOKE: PASS"
