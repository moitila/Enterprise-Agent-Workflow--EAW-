#!/usr/bin/env bash
# smoke_audit_skip.sh — TDD-reverso do audit skip-aware + track-aware (EAW-FIX-HYP-GATE).
# Invoca eaw_card_enforce_mandatory_analysis_audit diretamente (source do runtime) e checa exit codes.
# CA-1 skip -> nao exige (FALHA antes do fix); CA-2 nao-regressao; CA-3 multi-skip; CA-4 patch sem seeds.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Clausula (2) le as tracks reais do repo.
EAW_TRACKS_DIR="${EAW_TRACKS_DIR:-$REPO_ROOT/tracks}"
export EAW_TRACKS_DIR

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/lib.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/commands/eaw_commands.sh"

PASS_COUNT=0
pass() {
	printf "PASS: %s\n" "$1"
	PASS_COUNT=$((PASS_COUNT + 1))
}
fail() {
	printf "FAIL: %s\n" "$1" >&2
	exit 1
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# make_state <card_dir> <track> <completed_phase...>
make_state() {
	local card_dir="$1" track="$2"
	shift 2
	local phase
	{
		printf 'config_version: 1\n\n'
		printf 'card_state:\n'
		printf '  card_id: CARD_T\n'
		printf '  track_id: %s\n' "$track"
		printf '  current_phase: implementation_executor\n'
		printf '  completed_phases:\n'
		for phase in "$@"; do
			printf '    - %s\n' "$phase"
		done
	} >"$card_dir/state_card_${track}.yaml"
}

# seed <card_dir> <rel_path>  — cria artefato nao-vazio
seed() {
	local card_dir="$1" rel="$2"
	mkdir -p "$card_dir/$(dirname "$rel")"
	printf 'fixture substantive content for %s\n' "$rel" >"$card_dir/$rel"
}

# run_audit <card_dir> <phase_id>  — imprime o exit code do audit
run_audit() {
	local card_dir="$1" phase_id="$2" rc=0
	eaw_card_enforce_mandatory_analysis_audit CARD_T "$card_dir" "$phase_id" >/dev/null 2>&1 || rc=$?
	printf '%s' "$rc"
}

# ── CA-1 — skip: fase 'hypotheses' pulada nao bloqueia (FALHA hoje, exit 0 apos fix) ──
c1="$WORK/ca1"
mkdir -p "$c1/investigations" "$c1/implementation"
make_state "$c1" bug_ONBOARD intake findings planning implementation_planning
seed "$c1" investigations/20_findings.md
seed "$c1" investigations/40_next_steps.md
seed "$c1" implementation/00_scope.lock.md
seed "$c1" implementation/10_change_plan.md
# investigations/30_hypotheses.md ausente de proposito
rc1="$(run_audit "$c1" implementation_executor)"
[[ "$rc1" -eq 0 ]] || fail "CA-1 (skip -> nao exige): esperado exit 0, obtido $rc1"
pass "CA-1 skip-aware: hypotheses pulada nao bloqueia (exit 0)"

# ── CA-2 — nao-regressao: fase real presente em completed, artefato ausente -> bloqueia ──
c2="$WORK/ca2"
mkdir -p "$c2/investigations" "$c2/implementation"
make_state "$c2" bug intake findings hypotheses planning implementation_planning
seed "$c2" investigations/20_findings.md
seed "$c2" investigations/40_next_steps.md
seed "$c2" implementation/00_scope.lock.md
seed "$c2" implementation/10_change_plan.md
# investigations/30_hypotheses.md ausente; 'hypotheses' NAO foi pulada
rc2="$(run_audit "$c2" implementation_executor)"
[[ "$rc2" -eq 1 ]] || fail "CA-2 (nao-regressao): esperado exit 1, obtido $rc2"
pass "CA-2 nao-regressao: artefato genuino ausente bloqueia (exit 1)"

# ── CA-3 — multi-skip ARCH_REFACTOR_ONBOARD (findings/hypotheses/implementation_planning pulados) ──
c3="$WORK/ca3"
mkdir -p "$c3/investigations" "$c3/implementation"
make_state "$c3" ARCH_REFACTOR_ONBOARD intake planning
seed "$c3" investigations/40_next_steps.md
# ausentes: 20_findings, 30_hypotheses, 00_scope.lock, 10_change_plan (produtores pulados)
rc3="$(run_audit "$c3" implementation_executor)"
[[ "$rc3" -eq 0 ]] || fail "CA-3 (multi-skip): esperado exit 0, obtido $rc3"
pass "CA-3 multi-skip ARCH_REFACTOR_ONBOARD: 3 skips nao bloqueiam (exit 0)"

# ── CA-4 — patch sem seeds: planning nao declara 40_next_steps -> nao exige ──
c4="$WORK/ca4"
mkdir -p "$c4/investigations" "$c4/implementation"
make_state "$c4" patch ingest planning implementation_executor
seed "$c4" implementation/00_scope.lock.md
seed "$c4" implementation/10_change_plan.md
# ausentes: 20_findings, 30_hypotheses, 40_next_steps
rc4="$(run_audit "$c4" implementation_executor)"
[[ "$rc4" -eq 0 ]] || fail "CA-4 (patch sem seeds): esperado exit 0, obtido $rc4"
pass "CA-4 patch sem seeds: planning nao declara 40_next_steps (exit 0)"

if [[ "$PASS_COUNT" -ne 4 ]]; then
	fail "esperados 4 casos aprovados, obtidos $PASS_COUNT"
fi
printf "ALL PASSED (%d/4)\n" "$PASS_COUNT"
