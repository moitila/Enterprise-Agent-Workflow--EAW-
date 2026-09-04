#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() {
	printf 'smoke_adversarial_review failed: %s\n' "$1" >&2
	exit 1
}

pass() {
	printf 'PASS: %s\n' "$1"
}

TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

RUNTIME_COPY="$TEMP_ROOT/runtime"
WORKDIR="$TEMP_ROOT/workdir"
TARGET_REPO="$TEMP_ROOT/target-repo"
mkdir -p "$RUNTIME_COPY" "$TARGET_REPO"
cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/templates" "$REPO_ROOT/tracks" \
	"$REPO_ROOT/config" "$REPO_ROOT/skills" "$REPO_ROOT/docs" "$RUNTIME_COPY/"

git -C "$TARGET_REPO" init -q
git -C "$TARGET_REPO" config user.email smoke@example.com
git -C "$TARGET_REPO" config user.name smoke
printf 'target\n' >"$TARGET_REPO/target.txt"
git -C "$TARGET_REPO" add target.txt
git -C "$TARGET_REPO" commit -q -m target

"$RUNTIME_COPY/scripts/eaw" init --workdir "$WORKDIR" --force >/dev/null
printf 'target-repo|%s|target\n' "$TARGET_REPO" >"$WORKDIR/config/repos.conf"

INSTALL_OUTPUT="$(EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" tracks install 2>&1)"
grep -Fq 'track_id: adversarial_review' "$RUNTIME_COPY/tracks/tracks.yaml" \
	|| fail 'temporary tracks install did not register adversarial_review'
if grep -Fq 'rejected: adversarial_review' <<<"$INSTALL_OUTPUT"; then
	fail "temporary tracks install rejected adversarial_review: $INSTALL_OUTPUT"
fi
EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" validate workflow --track adversarial_review >/dev/null
EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" prompt validate >/dev/null
pass 'workflow, prompt families, and temporary registration validate'

for required_path in \
	"$RUNTIME_COPY/templates/intake_adversarial_review.md" \
	"$RUNTIME_COPY/docs/adversarial_review.md"; do
	test -s "$required_path" || fail "missing operational file: $required_path"
done

assert_prompt_materialized() {
	local card_id="$1"
	local phase_id="$2"
	local prompt_file="$WORKDIR/out/$card_id/prompts/$phase_id.md"
	local read_source

	test -s "$prompt_file" || fail "$card_id missing prompt for $phase_id"
	grep -Fq 'READ_SOURCES:' "$prompt_file" || fail "$card_id/$phase_id missing READ_SOURCES"
	if grep -Eq '\{\{(CARD_DIR|EAW_WORKDIR|OUT_DIR|RUNTIME_ROOT)\}\}' "$prompt_file"; then
		fail "$card_id/$phase_id contains unresolved operational placeholder"
	fi
	while IFS= read -r read_source; do
		[[ "$read_source" == /* ]] || fail "$card_id/$phase_id has relative read source: $read_source"
		[[ "$read_source" != *'/../'* ]] || fail "$card_id/$phase_id has traversal read source: $read_source"
		test -e "$read_source" || fail "$card_id/$phase_id read source does not exist: $read_source"
	done < <(awk '/^READ_SOURCES:/{capture=1; next} /^CRITICAL_PATHS:/{capture=0} capture && /^\//{print}' "$prompt_file")
}

run_next() {
	local card_id="$1"
	local output
	output="$(EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" next "$card_id" 2>&1)" \
		|| fail "$card_id next failed: $output"
	if grep -Fq 'resolution failed' <<<"$output"; then
		fail "$card_id emitted read_sources resolution warning: $output"
	fi
}

CARD="ADV1"
TARGET_CARD="TARGET1"

mkdir -p "$WORKDIR/out/$TARGET_CARD/investigations"
cat >"$WORKDIR/out/$TARGET_CARD/investigations/00_intake.md" <<'EOF'
# Intake - TARGET1

## Criterios de Aceite
- Corrigir o defeito X sem regressao.

## Status Final Declarado
COMPLETE
EOF

CARD_OUTPUT="$(EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" card "$CARD" --track adversarial_review "adversarial review smoke" 2>&1)" \
	|| fail "$CARD creation failed: $CARD_OUTPUT"
if grep -Fq 'resolution failed' <<<"$CARD_OUTPUT"; then
	fail "$CARD creation emitted read_sources resolution warning: $CARD_OUTPUT"
fi
test -d "$WORKDIR/out/$CARD/ingest" || fail "$CARD missing ingest scaffold"
test -d "$WORKDIR/out/$CARD/audit" || fail "$CARD missing audit scaffold"
assert_prompt_materialized "$CARD" case_reconstruction

cat >"$WORKDIR/out/$CARD/ingest/raw_card_explication.md" <<EOF
# Adversarial Review Intake - $CARD

## Card Alvo (Target Card)

- ID do card alvo: $TARGET_CARD
- Track do card alvo: standard
- Localizacao esperada: $WORKDIR/out/$TARGET_CARD
EOF

cat >"$WORKDIR/out/$CARD/audit/00_case_reconstruction.md" <<EOF
# Case Reconstruction - $TARGET_CARD

## Identificacao
Card alvo: $TARGET_CARD (track standard), status final declarado: COMPLETE.

## O que foi prometido
Criterio de aceite: corrigir o defeito X sem regressao (investigations/00_intake.md).

## O que foi alterado
Nenhum change plan ou patch notes encontrado sob out/$TARGET_CARD.

## Evidencias inventariadas
Nenhum artefato de teste/execucao/CI encontrado.

## Lacunas/contradicoes observaveis
Status COMPLETE sem evidencia de teste ou execucao associada.

## Itens ausentes
scope.lock, change_plan, patch_notes, execution_journal: ausentes.
EOF
run_next "$CARD"
assert_prompt_materialized "$CARD" evidence_audit

cat >"$WORKDIR/out/$CARD/audit/10_evidence_matrix.md" <<EOF
# Evidence Matrix - $TARGET_CARD

| claim | classe | execucao/estrutural | fonte | justificativa |
| corrigir defeito X sem regressao | (nenhuma classe aplicavel) | n/a | n/a | ausencia total de evidencia |
EOF
cat >"$WORKDIR/out/$CARD/audit/11_evidence_gaps.md" <<EOF
# Evidence Gaps - $TARGET_CARD

- Criterio "corrigir o defeito X sem regressao": evidencia nao comprovada. Motivo: ausencia total de artefato de teste/execucao/CI.
EOF
run_next "$CARD"
assert_prompt_materialized "$CARD" adversarial_design

cat >"$WORKDIR/out/$CARD/audit/20_adversarial_plan.md" <<EOF
# Adversarial Plan - $TARGET_CARD

## Tecnicas selecionadas
- oracle audit: lacuna alvo = 11_evidence_gaps.md (criterio sem evidencia). Justificativa: unica lacuna registrada. Modo: somente suporte estrutural (allowlist/rollback/baseline/evidencia preservavel nao satisfeitos).

## Tecnicas descartadas
- Demais tecnicas da lista fixa: nao pertinentes, nenhum outro claim ou lacuna registrado.
EOF
run_next "$CARD"
assert_prompt_materialized "$CARD" adversarial_execution

cat >"$WORKDIR/out/$CARD/audit/30_adversarial_results.md" <<EOF
# Adversarial Results - $TARGET_CARD

## oracle audit
Resultado observado: nenhum artefato de teste localizado sob out/$TARGET_CARD para validar oracle.
Classificacao: suporte-estrutural (execucao real nao autorizada em 20_adversarial_plan.md).
Evidencia/artefato: out/$TARGET_CARD/investigations/00_intake.md (unico artefato existente).
Rollback: nao aplicavel, nenhuma mutacao realizada.
EOF
run_next "$CARD"
assert_prompt_materialized "$CARD" verdict

cat >"$WORKDIR/out/$CARD/audit/40_verdict.md" <<EOF
# Verdict - $TARGET_CARD

## CORRECAO FUNCIONAL
Classificacao: NAO COMPROVADA. Evidencia: audit/11_evidence_gaps.md. Confianca: baixa.

## CAUSA RAIZ
Classificacao: NAO COMPROVADA. Evidencia: audit/00_case_reconstruction.md. Confianca: baixa.

## QUALIDADE DA EVIDENCIA
Classificacao: INSUFICIENTE. Evidencia: audit/10_evidence_matrix.md. Confianca: alta.

## REGRESSAO
Classificacao: NAO AVALIAVEL. Evidencia: audit/30_adversarial_results.md. Confianca: baixa.

## CRITERIOS DE ACEITE
Classificacao: PENDENTE. Evidencia: audit/11_evidence_gaps.md. Confianca: alta.

## COERENCIA DO FECHAMENTO EAW
Classificacao: INCOERENTE. Evidencia: status COMPLETE declarado em out/$TARGET_CARD sem evidencia associada (audit/00_case_reconstruction.md). Confianca: alta.

## Resumo executivo
Os seis eixos permanecem separados; nenhum colapso em PASS/FAIL unico.
EOF
run_next "$CARD"
assert_prompt_materialized "$CARD" remediation_handoff

cat >"$WORKDIR/out/$CARD/audit/50_remediation_handoff.md" <<EOF
# Remediation Handoff - $TARGET_CARD

## Proxima acao recomendada
evidencia externa necessaria

## Justificativa
Eixo QUALIDADE DA EVIDENCIA (audit/40_verdict.md) classificado INSUFICIENTE; nenhuma evidencia de execucao ou teste foi localizada.

## Referencias
- audit/11_evidence_gaps.md
- audit/40_verdict.md

## Declaracao
Nenhum card, PR, commit ou push foi criado por esta fase.
EOF
run_next "$CARD"

FINAL_STATE="$(EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" status "$CARD" 2>&1)"
grep -Fq 'remediation_handoff' <<<"$FINAL_STATE" || fail "$CARD did not reach remediation_handoff: $FINAL_STATE"
pass 'adversarial_review card completes all six phases'

printf '[smoke] adversarial_review OK\n'
