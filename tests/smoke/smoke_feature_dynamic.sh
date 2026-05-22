#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export TZ=UTC

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRACK_ID="feature_dynamic"
STARTED_AT="2026-04-17T00:00:00Z"

fail() {
	printf "smoke_feature_dynamic failed: %s\n" "$1" >&2
	exit 1
}

init_workdir() {
	local workdir="$1"
	env -u EAW_WORKDIR -u EAW_OUT_DIR bash "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
}

create_repo() {
	local repo_dir="$1"
	if [[ -d "$repo_dir/.git" ]]; then
		return 0
	fi
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@feature-dynamic.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add README.md
	git -C "$repo_dir" commit -q -m "fixture"
}

write_repos_conf() {
	local workdir="$1"
	local repo_key="$2"
	local repo_dir="$3"
	cat >"$workdir/config/repos.conf" <<EOF
${repo_key}|${repo_dir}|target
EOF
}

bootstrap_card() {
	local workdir="$1"
	local card="$2"
	mkdir -p \
		"$workdir/out/$card/ingest" \
		"$workdir/out/$card/investigations" \
		"$workdir/out/$card/context/dynamic" \
		"$workdir/out/$card/prompts" \
		"$workdir/out/$card/implementation"
}

state_file() {
	local workdir="$1"
	local card="$2"
	printf "%s/out/%s/state_card_%s.yaml" "$workdir" "$card" "$TRACK_ID"
}

prime_findings_state() {
	local workdir="$1"
	local card="$2"
	cat >"$(state_file "$workdir" "$card")" <<EOF
card_state:
  track_id: ${TRACK_ID}
  previous_phase: dynamic_context
  current_phase: findings
  completed_phases:
    - ingest
    - intake
    - dynamic_context
  phase_status: RUN
  phase_started_at: ${STARTED_AT}
  phase_completed: false
  phase_completed_at: null
EOF
}

assert_phase() {
	local workdir="$1"
	local card="$2"
	local expected="$3"
	local state
	state="$(state_file "$workdir" "$card")"
	grep -Fq "current_phase: ${expected}" "$state" || fail "expected current_phase=${expected} in ${state}"
}

run_next() {
	local workdir="$1"
	local card="$2"
	EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" next "$card" 2>&1
}

write_ingest_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/ingest"
	cat >"$workdir/out/$card/ingest/raw_card_explication.md" <<EOF
# Raw Card Explication

FD-08 smoke fixture for ${card}.
EOF
	cat >"$workdir/out/$card/ingest/sources.md" <<EOF
# Sources

FD-08 smoke input for ${card}.
EOF
}

write_intake_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/00_intake.md" <<EOF
# 00_intake

- criar tests/smoke/smoke_feature_dynamic.sh
- validar fluxo completo, skip legitimo e determinismo
EOF
}

write_dynamic_context_artifacts() {
	local workdir="$1"
	local card="$2"
	local dynamic_dir="$workdir/out/$card/context/dynamic"
	mkdir -p "$dynamic_dir"
	cat >"$dynamic_dir/00_scope_manifest.md" <<EOF
# Scope Manifest

template: deterministic_baseline_v1
EOF
	: >"$dynamic_dir/20_candidate_files.txt"
	cat >"$dynamic_dir/30_target_snippets.md" <<EOF
# Target Snippets

Nenhum snippet selecionado.
EOF
}

write_findings_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/20_findings.md" <<EOF
# 20_findings

- dedicated smoke harness absent
- skip contracts already published
EOF
}

write_hypotheses_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/30_hypotheses.md" <<EOF
# 30_hypotheses

## Coverage Map
- dedicated smoke

### H1
- dedicated smoke script is missing

## Ranking de Prioridade
1. H1

## Hipotese Dominante
DOMINANTE: H1

## Risco Residual Apos Mitigacao
- external smoke failures may still exist

## Provenance
- smoke fixture
EOF
}

write_planning_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/40_next_steps.md" <<EOF
# 40_next_steps

## Hipotese(s) Selecionada(s)
- H1

## Objetivo da Iteracao
Create dedicated smoke harness.

## Estrategia
Use findings and current contracts only.

## Plano Atomico
1. H1 implementa criar harness.
2. H1 implementa integrar no smoke canonico.
3. H1 valida executar harness dedicado.

## Criterios de Aceite
- harness dedicado passa

## Riscos e Mitigacao
- failures outside allowlist stay isolated

## Rollback
- remove dedicated harness and smoke hook
EOF
}

write_phase_output() {
	local workdir="$1"
	local card="$2"
	local phase="$3"
	local summary="$4"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/10_phase_output.json" <<EOF
{"phase_id":"${phase}","status":"completed","summary":"${summary}"}
EOF
}

write_handoff() {
	local workdir="$1"
	local card="$2"
	local phase="$3"
	shift 3
	local codes_json="" code first=1
	for code in "$@"; do
		if [[ $first -eq 1 ]]; then
			codes_json="\"${code}\""
			first=0
		else
			codes_json="${codes_json},\"${code}\""
		fi
	done
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/20_handoff.json" <<EOF
{"from_phase":"${phase}","status":"completed","messages":[],"codes":[${codes_json}]}
EOF
}

prepare_findings_ready_card() {
	local workdir="$1"
	local card="$2"
	write_ingest_artifact "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_dynamic_context_artifacts "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
}

run_full_flow_no_skip_scenario() {
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="FD08FULL"
	repo_key="fd08-full"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	bootstrap_card "$workdir" "$card"
	prepare_findings_ready_card "$workdir" "$card"

	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "findings"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> hypotheses" <<<"$output" || fail "full flow did not advance findings -> hypotheses"
	assert_phase "$workdir" "$card" "hypotheses"
	test -f "$workdir/out/$card/investigations/20_handoff.json" || fail "full flow missing findings handoff artifact"

	write_hypotheses_artifact "$workdir" "$card"
	write_phase_output "$workdir" "$card" "hypotheses" "H1 dominant"
	write_handoff "$workdir" "$card" "hypotheses"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: hypotheses -> planning" <<<"$output" || fail "full flow did not advance hypotheses -> planning"
	assert_phase "$workdir" "$card" "planning"
	test -f "$workdir/out/$card/investigations/10_phase_output.json" || fail "full flow missing phase output artifact"
	test -f "$workdir/out/$card/investigations/20_handoff.json" || fail "full flow missing hypotheses handoff artifact"

	write_planning_artifact "$workdir" "$card"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: planning -> implementation_planning" <<<"$output" || fail "full flow did not advance planning -> implementation_planning"
	assert_phase "$workdir" "$card" "implementation_planning"
}

run_skip_hypotheses_scenario() {
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="FD08SKIP"
	repo_key="fd08-skip"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	bootstrap_card "$workdir" "$card"
	prepare_findings_ready_card "$workdir" "$card"

	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "findings" "NO_CODE_DEVIATION"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "NO_CODE_DEVIATION did not skip findings -> planning"
	assert_phase "$workdir" "$card" "planning"
	test ! -f "$workdir/out/$card/investigations/30_hypotheses.md" || fail "skip scenario unexpectedly created hypotheses artifact"
}

run_skip_plus_planning_scenario() {
	local tmpdir workdir repo_dir card repo_key output prompt_source
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="FD08PLAN"
	repo_key="fd08-plan"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	bootstrap_card "$workdir" "$card"
	prepare_findings_ready_card "$workdir" "$card"

	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "findings" "ADHERENCE_CONFIRMED"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "ADHERENCE_CONFIRMED did not skip findings -> planning"
	assert_phase "$workdir" "$card" "planning"

	prompt_source="$REPO_ROOT/templates/prompts/feature_dynamic/planning/prompt_v6.md"
	test -f "$prompt_source" || fail "skip plus planning scenario missing planning prompt source"
	grep -Fq '`20_findings.md` como base unica' "$prompt_source" || fail "planning prompt source missing findings-only continuation contract"
	test ! -f "$workdir/out/$card/investigations/30_hypotheses.md" || fail "skip plus planning scenario unexpectedly created hypotheses artifact"

	write_planning_artifact "$workdir" "$card"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: planning -> implementation_planning" <<<"$output" || fail "planning without hypotheses did not advance"
	assert_phase "$workdir" "$card" "implementation_planning"
}

materialize_skip_prompt() {
	local workdir="$1"
	local repo_dir="$2"
	local card="$3"
	local repo_key="$4"
	local output

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	bootstrap_card "$workdir" "$card"
	prepare_findings_ready_card "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "findings" "NO_CODE_DEVIATION"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "determinism setup did not reach planning"
	assert_phase "$workdir" "$card" "planning"
}

run_determinism_scenario() {
	local tmpdir repo_dir workdir1 workdir2 card repo_key prompt1 prompt2
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	repo_dir="$tmpdir/repo"
	workdir1="$tmpdir/run1"
	workdir2="$tmpdir/run2"
	card="FD08DET"
	repo_key="fd08-det"

	materialize_skip_prompt "$workdir1" "$repo_dir" "$card" "$repo_key"
	materialize_skip_prompt "$workdir2" "$repo_dir" "$card" "$repo_key"

	prompt1="$tmpdir/prompt1.norm"
	prompt2="$tmpdir/prompt2.norm"
	sed -e "s#${tmpdir}/run1#WORKDIR#g" -e "s#${tmpdir}/repo#REPO#g" \
		"$workdir1/out/$card/prompts/planning.md" >"$prompt1"
	sed -e "s#${tmpdir}/run2#WORKDIR#g" -e "s#${tmpdir}/repo#REPO#g" \
		"$workdir2/out/$card/prompts/planning.md" >"$prompt2"
	cmp -s "$prompt1" "$prompt2" || fail "determinism scenario produced different planning prompts for equivalent input"
}

printf "[smoke] full flow without skip\n"
run_full_flow_no_skip_scenario
printf "[smoke] skip hypotheses via findings code\n"
run_skip_hypotheses_scenario
printf "[smoke] skip hypotheses with planning continuation\n"
run_skip_plus_planning_scenario
printf "[smoke] determinism for equivalent input\n"
run_determinism_scenario
printf "[smoke] feature_dynamic OK\n"
