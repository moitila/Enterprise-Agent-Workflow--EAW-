#!/usr/bin/env bash
# smoke_completion_content.sh — TDD-reverso do predicado de completion por IDENTIDADE.
# Invoca eaw_phase_completion_artifact_has_meaningful_content, eaw_scaffold_phase_artifact e
# eaw_card_enforce_mandatory_analysis_audit diretamente (source do runtime) e checa exit codes.
# REGRA DE OURO: nenhum criterio de aprovacao por TAMANHO. "Preenchido" = existe E nao-vazio E
# NAO-identico-ao-scaffold E sem token de placeholder de template. Artefato legitimo curto PASSA.
# Antes dos fixes (piso de tamanho presente e sem FIX-SCOPELOCK) os casos b/c/e/f FALHAM.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# render_expected_scaffold le $EAW_TEMPLATES_DIR sob set -u; audit reusa o mesmo predicado.
EAW_TEMPLATES_DIR="${EAW_TEMPLATES_DIR:-$REPO_ROOT/templates}"
EAW_TRACKS_DIR="${EAW_TRACKS_DIR:-$REPO_ROOT/tracks}"
export EAW_TEMPLATES_DIR EAW_TRACKS_DIR

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

CARD="smoke_card"

# has_content <card_dir> <phase_id> <rel_path>  — imprime exit code do predicado do gate
has_content() {
	local card_dir="$1" phase_id="$2" rel="$3" rc=0
	eaw_phase_completion_artifact_has_meaningful_content "$CARD" "$card_dir" "$phase_id" "$rel" >/dev/null 2>&1 || rc=$?
	printf '%s' "$rc"
}

seed_file() {
	local card_dir="$1" rel="$2" content="$3"
	mkdir -p "$card_dir/$(dirname "$rel")"
	printf '%s' "$content" >"$card_dir/$rel"
}

# ── (a) artefato AUSENTE -> exit 1 ──
cA="$WORK/a"
mkdir -p "$cA/investigations"
[[ "$(has_content "$cA" findings investigations/20_findings.md)" -eq 1 ]] ||
	fail "(a) artefato ausente deveria dar exit 1"
pass "(a) artefato ausente rejeitado (exit 1)"

# ── (a') scaffold byte-identico ao template renderizado -> exit 1 (anti-scaffold cmp) ──
cAP="$WORK/ap"
mkdir -p "$cAP/investigations"
eaw_phase_completion_render_expected_scaffold "$CARD" "$cAP" findings investigations/20_findings.md \
	>"$cAP/investigations/20_findings.md"
[[ "$(has_content "$cAP" findings investigations/20_findings.md)" -eq 1 ]] ||
	fail "(a') scaffold byte-identico deveria dar exit 1"
pass "(a') scaffold byte-identico rejeitado (exit 1)"

# ── (a'') variavel de template {{...}} nao renderizada -> exit 1 (guard de identidade) ──
# Nota: o token de card <CARD> (scaffold/seed) ja e coberto por (a') via anti-scaffold cmp;
# aqui cobrimos a variavel de template em chaves-duplas ainda nao substituida.
cAT="$WORK/at"
seed_file "$cAT" investigations/30_hypotheses.md $'# H1\n\nvalor {{WRITE_ALLOWLIST}} ainda nao renderizado.\n'
[[ "$(has_content "$cAT" hypotheses investigations/30_hypotheses.md)" -eq 1 ]] ||
	fail "(a'') token {{...}} deveria dar exit 1"
pass "(a'') variavel de template {{...}} nao renderizada rejeitada (exit 1)"

# ── (b) .md CURTO nao-scaffold sem placeholder (~40 bytes) -> exit 0 (SEM piso) ──
cB="$WORK/b"
seed_file "$cB" investigations/40_next_steps.md $'# Passo 1\nfoo bar baz.\n'
[[ "$(wc -c <"$cB/investigations/40_next_steps.md")" -lt 500 ]] ||
	fail "(b) fixture deveria ser curto (<500 bytes) para provar ausencia de piso"
[[ "$(has_content "$cB" planning investigations/40_next_steps.md)" -eq 0 ]] ||
	fail "(b) artefato curto legitimo deveria PASSAR (exit 0); ha piso de tamanho?"
pass "(b) artefato curto legitimo aprovado sem piso (exit 0)"

# ── (c) scaffold de implementation/20_patch_notes.md -> deferido (ausente) ──
cC="$WORK/c"
mkdir -p "$cC/implementation"
c_out="$(eaw_scaffold_phase_artifact "$CARD" "$cC" implementation_executor implementation/20_patch_notes.md)"
grep -Fq "deferred_artifact=implementation/20_patch_notes.md" <<<"$c_out" ||
	fail "(c) esperado deferral de 20_patch_notes.md; obtido: $c_out"
[[ ! -f "$cC/implementation/20_patch_notes.md" ]] ||
	fail "(c) 20_patch_notes.md deveria permanecer AUSENTE (deferido)"
pass "(c) implementation/20_patch_notes.md deferido/ausente"

# ── (d) envelope JSON validado por schema, nunca por tamanho ──
cD="$WORK/d"
seed_file "$cD" investigations/20_handoff.json \
	'{"from_phase":"findings","status":"completed","messages":[],"codes":[]}'
[[ "$(wc -c <"$cD/investigations/20_handoff.json")" -lt 500 ]] ||
	fail "(d) envelope fixture deveria ser curto (<500 bytes)"
[[ "$(has_content "$cD" findings investigations/20_handoff.json)" -eq 0 ]] ||
	fail "(d) envelope curto valido deveria PASSAR (exit 0)"
seed_file "$cD" investigations/20_handoff.json '{}'
[[ "$(has_content "$cD" findings investigations/20_handoff.json)" -eq 1 ]] ||
	fail "(d) envelope {} deveria FALHAR por schema (exit 1)"
pass "(d) envelope JSON por schema, curto passa e {} falha"

# ── (e) audit reusa o predicado por identidade (skip/track-aware preservado) ──
make_state_e() {
	local card_dir="$1" track="$2"
	shift 2
	local phase
	{
		printf 'config_version: 1\n\ncard_state:\n'
		printf '  card_id: %s\n  track_id: %s\n' "$CARD" "$track"
		printf '  current_phase: implementation_executor\n'
		printf '  completed_phases:\n'
		for phase in "$@"; do printf '    - %s\n' "$phase"; done
	} >"$card_dir/state_card_${track}.yaml"
}
run_audit_e() {
	local card_dir="$1" rc=0
	eaw_card_enforce_mandatory_analysis_audit "$CARD" "$card_dir" implementation_executor >/dev/null 2>&1 || rc=$?
	printf '%s' "$rc"
}
seed_scope_lock_structural() {
	seed_file "$1" implementation/00_scope.lock.md \
		$'# Scope Lock\n\nwrite_allowlist: []\n\n## In Scope\n\n## Out of Scope\n'
}

# e-pass: seeds curtos nao-scaffold (identidade) -> exit 0
cE1="$WORK/e1"
mkdir -p "$cE1/investigations" "$cE1/implementation"
make_state_e "$cE1" bug intake findings hypotheses planning implementation_planning
seed_file "$cE1" investigations/20_findings.md $'# Findings\nreal.\n'
seed_file "$cE1" investigations/30_hypotheses.md $'# H1\nreal.\n'
seed_file "$cE1" investigations/40_next_steps.md $'# Plan\nreal.\n'
seed_file "$cE1" implementation/10_change_plan.md $'# Change Plan\nStep 1.\n'
seed_scope_lock_structural "$cE1"
[[ "$(run_audit_e "$cE1")" -eq 0 ]] ||
	fail "(e) seeds curtos legitimos deveriam PASSAR no audit (exit 0)"

# e-fail: um artefato exigido byte-identico ao scaffold -> exit 1
cE2="$WORK/e2"
mkdir -p "$cE2/investigations" "$cE2/implementation"
make_state_e "$cE2" bug intake findings hypotheses planning implementation_planning
seed_file "$cE2" investigations/20_findings.md $'# Findings\nreal.\n'
eaw_phase_completion_render_expected_scaffold "$CARD" "$cE2" hypotheses investigations/30_hypotheses.md \
	>"$cE2/investigations/30_hypotheses.md"
seed_file "$cE2" investigations/40_next_steps.md $'# Plan\nreal.\n'
seed_file "$cE2" implementation/10_change_plan.md $'# Change Plan\nStep 1.\n'
seed_scope_lock_structural "$cE2"
[[ "$(run_audit_e "$cE2")" -eq 1 ]] ||
	fail "(e) artefato scaffold-identico exigido deveria BLOQUEAR o audit (exit 1)"
pass "(e) audit por identidade: seed curto passa; scaffold-identico bloqueia"

# ── (f) 00_scope.lock.md validado por PARSE ESTRUTURAL, nunca por tamanho ──
cF="$WORK/f"
seed_scope_lock_structural "$cF"
[[ "$(wc -c <"$cF/implementation/00_scope.lock.md")" -lt 500 ]] ||
	fail "(f) scope.lock estrutural fixture deveria ser curto (<500 bytes)"
[[ "$(has_content "$cF" implementation_planning implementation/00_scope.lock.md)" -eq 0 ]] ||
	fail "(f) scope.lock estrutural curto deveria PASSAR (exit 0)"
seed_file "$cF" implementation/00_scope.lock.md $'# scope lock\n\nconteudo generico sem estrutura.\n'
[[ "$(has_content "$cF" implementation_planning implementation/00_scope.lock.md)" -eq 1 ]] ||
	fail "(f) scope.lock generico sem estrutura deveria FALHAR (exit 1)"
pass "(f) scope.lock por estrutura: write_allowlist/headings passa; generico falha"

if [[ "$PASS_COUNT" -ne 8 ]]; then
	fail "esperados 8 casos aprovados, obtidos $PASS_COUNT"
fi
printf "smoke_completion_content OK (%d/8)\n" "$PASS_COUNT"

# --- Allowlist gate tests (BL-03) ---
# g: scope.lock com In Scope + Out of Scope mas SEM Allowlist de Escrita -> deve FALHAR
cG="$WORK/g"
seed_file "$cG" implementation/00_scope.lock.md \
	$'# Scope Lock\n\n## In Scope\n\nalgum conteudo\n\n## Out of Scope\n\nalgum conteudo\n'
if eaw_phase_completion_artifact_has_meaningful_content "SMOKE" "$cG" "implementation_planning" \
		"implementation/00_scope.lock.md" 2>/dev/null; then
	fail "(g) gate deveria rejeitar scope.lock sem ## Allowlist de Escrita"
fi
pass "(g) gate rejeitou scope.lock sem Allowlist de Escrita"
PASS_COUNT=$((PASS_COUNT + 1))

# h: scope.lock com Allowlist de Escrita preenchida com path real -> deve PASSAR
cH="$WORK/h"
seed_file "$cH" implementation/00_scope.lock.md \
	$'# Scope Lock\n\n## Base Obrigatoria\n\nalgum conteudo\n\n## In Scope\n\nalgum conteudo\n\n## Out of Scope\n\nalgum conteudo\n\n## Allowlist de Escrita\n- /home/user/dev/eaw/tracks/bug_ONBOARD/phases/intake.yaml\n\n## Regra de Escrita\n\nalguma regra\n'
if ! eaw_phase_completion_artifact_has_meaningful_content "SMOKE" "$cH" "implementation_planning" \
		"implementation/00_scope.lock.md" 2>/dev/null; then
	fail "(h) gate deveria aceitar scope.lock com Allowlist preenchida com path real"
fi
pass "(h) gate aceitou scope.lock com Allowlist de Escrita preenchida"
PASS_COUNT=$((PASS_COUNT + 1))

printf "smoke_completion_content Allowlist gate OK (%d total)\n" "$PASS_COUNT"
