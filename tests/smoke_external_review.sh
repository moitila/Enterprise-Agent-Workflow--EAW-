#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() {
	printf 'smoke_external_review failed: %s\n' "$1" >&2
	exit 1
}

pass() {
	printf 'PASS: %s\n' "$1"
}

TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

RUNTIME_COPY="$TEMP_ROOT/runtime"
WORKDIR="$TEMP_ROOT/workdir"
REVIEW_REPO="$TEMP_ROOT/review-repo"
mkdir -p "$RUNTIME_COPY" "$REVIEW_REPO"
cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/templates" "$REPO_ROOT/tracks" \
	"$REPO_ROOT/config" "$REPO_ROOT/skills" "$REPO_ROOT/docs" "$RUNTIME_COPY/"

git -C "$REVIEW_REPO" init -q
git -C "$REVIEW_REPO" config user.email smoke@example.com
git -C "$REVIEW_REPO" config user.name smoke
printf 'base\n' >"$REVIEW_REPO/reviewed.txt"
git -C "$REVIEW_REPO" add reviewed.txt
git -C "$REVIEW_REPO" commit -q -m base
BASE_COMMIT="$(git -C "$REVIEW_REPO" rev-parse HEAD)"
printf 'head\n' >>"$REVIEW_REPO/reviewed.txt"
git -C "$REVIEW_REPO" commit -q -am head
HEAD_COMMIT="$(git -C "$REVIEW_REPO" rev-parse HEAD)"
MERGE_BASE="$(git -C "$REVIEW_REPO" merge-base "$BASE_COMMIT" "$HEAD_COMMIT")"
REPO_HEAD_BEFORE="$(git -C "$REVIEW_REPO" rev-parse HEAD)"
REPO_TREE_BEFORE="$(git -C "$REVIEW_REPO" write-tree)"
REPO_STATUS_BEFORE="$(git -C "$REVIEW_REPO" status --porcelain=v1)"

"$RUNTIME_COPY/scripts/eaw" init --workdir "$WORKDIR" --force >/dev/null
printf 'review-repo|%s|target\n' "$REVIEW_REPO" >"$WORKDIR/config/repos.conf"

INSTALL_OUTPUT="$(EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" tracks install 2>&1)"
grep -Fq 'track_id: external_review' "$RUNTIME_COPY/tracks/tracks.yaml" \
	|| fail 'temporary tracks install did not register external_review'
if grep -Fq 'rejected: external_review' <<<"$INSTALL_OUTPUT"; then
	fail "temporary tracks install rejected external_review: $INSTALL_OUTPUT"
fi
EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" validate workflow --track external_review >/dev/null
EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" prompt validate >/dev/null
pass 'workflow, prompt families, and temporary registration validate'

for required_path in \
	"$RUNTIME_COPY/templates/intake_external_review.md" \
	"$RUNTIME_COPY/docs/external_review.md"; do
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

write_handoff() {
	local card_id="$1"
	local phase_id="$2"
	printf '%s\n' "{\"from_phase\":\"$phase_id\",\"status\":\"completed\",\"messages\":[],\"codes\":[]}" \
		>"$WORKDIR/out/$card_id/investigations/20_handoff.json"
	grep -Fxq "{\"from_phase\":\"$phase_id\",\"status\":\"completed\",\"messages\":[],\"codes\":[]}" \
		"$WORKDIR/out/$card_id/investigations/20_handoff.json" \
		|| fail "$card_id invalid handoff for $phase_id"
}

create_review_card() {
	local card_id="$1"
	local card_output
	card_output="$(EAW_WORKDIR="$WORKDIR" "$RUNTIME_COPY/scripts/eaw" card "$card_id" --track external_review "external review smoke" 2>&1)" \
		|| fail "$card_id creation failed: $card_output"
	if grep -Fq 'resolution failed' <<<"$card_output"; then
		fail "$card_id creation emitted read_sources resolution warning: $card_output"
	fi
	test -d "$WORKDIR/out/$card_id/ingest" || fail "$card_id missing ingest scaffold"
	test -d "$WORKDIR/out/$card_id/review" || fail "$card_id missing review scaffold"
	assert_prompt_materialized "$card_id" source_inventory
}

fill_source_inventory() {
	local card_id="$1"
	local mode="$2"
	cat >"$WORKDIR/out/$card_id/review/00_source_manifest.md" <<EOF
# Source Manifest

Status: COMPLETO

| id | tipo | origem | identidade | proveniencia | acesso | referencia | uso |
| SRC-1 | git | local | review-repo | repos.conf | ACESSIVEL | $HEAD_COMMIT | baseline |
| SRC-2 | requisito | intake | acceptance | card $card_id | ACESSIVEL | ingest/intake.md | contexto |
EOF
	cat >"$WORKDIR/out/$card_id/review/01_source_gaps.md" <<EOF
# Source Gaps

Mode: $mode. Requisito ausente permanece visivel como lacuna; nenhuma fonte inacessivel foi inferida.
EOF
	write_handoff "$card_id" source_inventory
}

fill_baseline() {
	local card_id="$1"
	local mode="$2"
	if [[ "$mode" == trusted ]]; then
		cat >"$WORKDIR/out/$card_id/review/10_baseline.md" <<EOF
# Baseline

Status: CONFIAVEL
Repositorio: $REVIEW_REPO
Base: $BASE_COMMIT
Head: $HEAD_COMMIT
Merge-base: $MERGE_BASE
Metodo: git rev-parse e git merge-base em modo read-only.
Justificativa: identidades imutaveis comprovadas.
EOF
		cat >"$WORKDIR/out/$card_id/review/11_diff_identity.md" <<EOF
# Diff Identity

Repositorio: $REVIEW_REPO
Intervalo: $BASE_COMMIT..$HEAD_COMMIT
Merge-base: $MERGE_BASE
Commit: $HEAD_COMMIT
Arquivo do corpus: reviewed.txt
Metodo: diff por commits imutaveis. Codigo fora do diff e contexto nao atribuivel.
EOF
	else
		cat >"$WORKDIR/out/$card_id/review/10_baseline.md" <<EOF
# Baseline

Status: BLOQUEADO
Repositorio: $REVIEW_REPO
Base: AUSENTE
Head: $HEAD_COMMIT
Merge-base: NAO_COMPROVADO
Justificativa: baseline ausente impede fixar o corpus e atribuir findings.
EOF
		cat >"$WORKDIR/out/$card_id/review/11_diff_identity.md" <<EOF
# Diff Identity

Repositorio: $REVIEW_REPO
Referencia observada: $HEAD_COMMIT
Limites do corpus: NAO_COMPROVADOS por baseline ausente.
Itens excluidos: todo codigo presumido ate identificacao de base e merge-base.
EOF
	fi
	write_handoff "$card_id" baseline_validation
}

fill_functional_context() {
	local card_id="$1"
	cat >"$WORKDIR/out/$card_id/review/20_requirements_matrix.md" <<'EOF'
# Requirements Matrix

| id | texto | tipo | fonte | classificacao | criterio | caso | contrato | evidencia | estado |
| REQ-1 | preservar conteudo | funcional | SRC-2 | OBSERVADO | arquivo contem head | atualizacao | texto | teste | COMPROVADO |
| REQ-GAP | requisito ausente | funcional | nenhuma | INFERIDO_A_VALIDAR | pergunta pendente | desconhecido | nao comprovado | ausente | LACUNA |
EOF
	cat >"$WORKDIR/out/$card_id/review/21_context_limits.md" <<'EOF'
# Context Limits

Requisito ausente visivel: REQ-GAP. A lacuna limita cobertura funcional e nao e convertida em defeito.
EOF
	write_handoff "$card_id" functional_context
}

fill_change_mapping() {
	local card_id="$1"
	local mode="$2"
	if [[ "$mode" == trusted ]]; then
		cat >"$WORKDIR/out/$card_id/review/30_change_map.md" <<EOF
# Change Map

Status: EXECUTADA
Arquivo/hunk: reviewed.txt:2
Simbolo: conteudo textual
Commit: $HEAD_COMMIT
Requisito: REQ-1
Introduzido: linha head. Preexistente: linha base. Evidencia: diff $BASE_COMMIT..$HEAD_COMMIT.
EOF
		cat >"$WORKDIR/out/$card_id/review/31_impact_matrix.md" <<'EOF'
# Impact Matrix

| componente | propagacao | consumidores | teste/CI/docs | risco | confianca | lacuna |
| texto | arquivo | leitor | teste ausente | regressao | ALTA | CI ausente |
EOF
	else
		cat >"$WORKDIR/out/$card_id/review/30_change_map.md" <<'EOF'
# Change Map

Status: NAO_EXECUTADA_POR_BASELINE
Motivo: baseline ausente. Nenhuma mudanca foi atribuida; codigo preexistente e introduzido nao podem ser distinguidos.
EOF
		cat >"$WORKDIR/out/$card_id/review/31_impact_matrix.md" <<'EOF'
# Impact Matrix

Status: NAO_EXECUTADA_POR_BASELINE
Impacto: consumidores e riscos nao podem ser mapeados. Confianca: NULA.
EOF
	fi
	write_handoff "$card_id" change_mapping
}

fill_technical_review() {
	local card_id="$1"
	local mode="$2"
	if [[ "$mode" == trusted ]]; then
		cat >"$WORKDIR/out/$card_id/review/40_technical_analysis.md" <<'EOF'
# Technical Analysis

Status: EXECUTADA. Dimensoes: comportamento, contratos, regressao, seguranca, desempenho e manutencao.
Evidencia: diff imutavel. Limite: CI ausente. Risco descartado: codigo fora do diff nao atribuivel.
EOF
		cat >"$WORKDIR/out/$card_id/review/41_review_candidates.md" <<'EOF'
# Review Candidates

| id | categoria | requisito | localizacao | evidencia | descricao | impacto | recomendacao | confianca | classificacao | atribuibilidade |
| C-1 | comportamento | REQ-1 | reviewed.txt:2 | diff | finding bloqueante | alto | corrigir | ALTA | PROBLEMA | ATRIBUIVEL |
| C-2 | manutencao | REQ-1 | reviewed.txt:2 | diff | recomendacao nao bloqueante | baixo | documentar | MEDIA | RECOMENDACAO | ATRIBUIVEL |
| C-3 | contexto | REQ-GAP | sem localizacao | lacuna | duvida nao promovida a defeito | desconhecido | esclarecer | BAIXA | DUVIDA | NAO_ATRIBUIVEL |
EOF
	else
		cat >"$WORKDIR/out/$card_id/review/40_technical_analysis.md" <<'EOF'
# Technical Analysis

Status: NAO_EXECUTADA_POR_BASELINE. Dimensoes nao avaliadas; evidencia e limites registrados no baseline.
EOF
		cat >"$WORKDIR/out/$card_id/review/41_review_candidates.md" <<'EOF'
# Review Candidates

Status: NAO_EXECUTADA_POR_BASELINE. Nenhum candidato atribuivel foi produzido.
EOF
	fi
	write_handoff "$card_id" technical_review
}

fill_evidence_review() {
	local card_id="$1"
	local mode="$2"
	if [[ "$mode" == trusted ]]; then
		cat >"$WORKDIR/out/$card_id/review/50_evidence_matrix.md" <<EOF
# Evidence Matrix

| requisito/risco | evidencia | identidade/proveniencia | resultado | correspondencia | cobertura | status | confianca |
| REQ-1 | diff | $HEAD_COMMIT local | observado | comprovada | parcial | SUFICIENTE | ALTA |
| CI | nenhuma | ausente | nao observado | nao comprovada | nenhuma | AUSENTE | ALTA |
EOF
		cat >"$WORKDIR/out/$card_id/review/51_validation_gaps.md" <<'EOF'
# Validation Gaps

CI ausente visivel; afeta REQ-1; evidencia esperada: execucao ligada ao head; impacto: bloqueio por evidencia; natureza: obrigatoria; acao: fornecer resultado.
EOF
	else
		cat >"$WORKDIR/out/$card_id/review/50_evidence_matrix.md" <<'EOF'
# Evidence Matrix

Status: NAO_EXECUTADA_POR_BASELINE. Evidencias nao podem ser relacionadas ao corpus; confianca NULA.
EOF
		cat >"$WORKDIR/out/$card_id/review/51_validation_gaps.md" <<'EOF'
# Validation Gaps

Baseline ausente impede validar testes e CI; impacto: BLOQUEADO_POR_CONTEXTO; natureza obrigatoria.
EOF
	fi
	write_handoff "$card_id" evidence_review
}

fill_findings() {
	local card_id="$1"
	local mode="$2"
	if [[ "$mode" == trusted ]]; then
		cat >"$WORKDIR/out/$card_id/review/60_findings.md" <<'EOF'
# Findings

Status: CONSOLIDADO

| id | severidade | categoria | requisito | localizacao | evidencia | descricao | impacto | recomendacao | confianca | atribuibilidade | natureza |
| F-1 | ALTA | comportamento | REQ-1 | reviewed.txt:2 | diff | finding bloqueante | regressao | corrigir | ALTA | ATRIBUIVEL | BLOQUEANTE |
| F-2 | BAIXA | manutencao | REQ-1 | reviewed.txt:2 | diff | recomendacao nao bloqueante | residual | documentar | MEDIA | ATRIBUIVEL | NAO_BLOQUEANTE |
| D-1 | NA | contexto | REQ-GAP | nenhuma | lacuna | duvida nao promovida a defeito | desconhecido | esclarecer | BAIXA | NAO_ATRIBUIVEL | DUVIDA |
EOF
		cat >"$WORKDIR/out/$card_id/review/61_traceability_matrix.md" <<'EOF'
# Traceability Matrix

| fonte | requisito | diff | evidencia | finding | estado |
| SRC-1 | REQ-1 | reviewed.txt:2 | diff | F-1/F-2 | LIGADO |
| nenhuma | REQ-GAP | nenhum | ausente | D-1 | LACUNA |
EOF
		cat >"$WORKDIR/out/$card_id/review/62_positive_aspects.md" <<'EOF'
# Positive Aspects

Nenhum aspecto positivo relevante foi identificado; nenhum elogio foi fabricado.
EOF
	else
		cat >"$WORKDIR/out/$card_id/review/60_findings.md" <<'EOF'
# Findings

Status: NAO_EXECUTADA_POR_BASELINE. Zero findings atribuiveis.
EOF
		cat >"$WORKDIR/out/$card_id/review/61_traceability_matrix.md" <<'EOF'
# Traceability Matrix

Status: NAO_EXECUTADA_POR_BASELINE. Fonte e requisito nao podem ser ligados a diff, evidencia, finding ou conclusao.
EOF
		cat >"$WORKDIR/out/$card_id/review/62_positive_aspects.md" <<'EOF'
# Positive Aspects

Status: NAO_EXECUTADA_POR_BASELINE. Nenhum aspecto positivo foi fabricado.
EOF
	fi
	write_handoff "$card_id" findings_consolidation
}

fill_final_opinion() {
	local card_id="$1"
	local mode="$2"
	local result
	if [[ "$mode" == trusted ]]; then
		result=ALTERACOES_SOLICITADAS
	else
		result=BLOQUEADO_POR_CONTEXTO
	fi
	cat >"$WORKDIR/out/$card_id/review/70_final_review.md" <<EOF
# Final Review

Resultado: $result
Escopo e identidade: card $card_id, repo $REVIEW_REPO, head $HEAD_COMMIT.
Resumo: conclusao limitada pelas evidencias registradas.
Findings: bloqueantes e nao bloqueantes conforme 60_findings.md; duvidas permanecem duvidas.
Cobertura: tecnica e funcional explicitada. Limitacoes: requisito e CI ausentes.
Evidencias determinantes: baseline e matrizes. Proxima acao: revisao manual.
EOF
	cat >"$WORKDIR/out/$card_id/review/71_proposed_comments.md" <<'EOF'
# Proposed Comments

Comentario apenas proposto para publicacao manual: ligado a F-1 ou ao bloqueio de contexto, com localizacao, evidencia, impacto e acao solicitada. Nenhuma publicacao foi executada.
EOF
	cat >"$WORKDIR/out/$card_id/review/72_validation_report.md" <<EOF
# Validation Report

Identidade: SRC-1 e card $card_id conferidos.
Completude: artefatos 00 a 72 presentes.
Rastreabilidade: fonte-requisito-diff-evidencia-finding-parecer verificada.
Contradicoes: resultado $result coerente com baseline e findings.
Status final: VALIDO.
EOF
}

run_review_flow() {
	local card_id="$1"
	local mode="$2"

	create_review_card "$card_id"
	cat >"$WORKDIR/out/$card_id/ingest/intake.md" <<EOF
# Intake

Repositorio: $REVIEW_REPO
Base: $BASE_COMMIT
Head: $HEAD_COMMIT
Mode: $mode
EOF
	fill_source_inventory "$card_id" "$mode"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" baseline_validation
	fill_baseline "$card_id" "$mode"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" functional_context
	fill_functional_context "$card_id"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" change_mapping
	fill_change_mapping "$card_id" "$mode"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" technical_review
	fill_technical_review "$card_id" "$mode"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" evidence_review
	fill_evidence_review "$card_id" "$mode"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" findings_consolidation
	fill_findings "$card_id" "$mode"
	run_next "$card_id"
	assert_prompt_materialized "$card_id" final_opinion
	fill_final_opinion "$card_id" "$mode"
	run_next "$card_id"
	grep -Fq 'phase_status: COMPLETE' "$WORKDIR/out/$card_id/state_card_external_review.yaml" \
		|| fail "$card_id did not mark the final phase COMPLETE"
	grep -Fq 'phase_completed: true' "$WORKDIR/out/$card_id/state_card_external_review.yaml" \
		|| fail "$card_id did not persist final phase completion"
}

run_review_flow EXTREV-TRUSTED trusted
run_review_flow EXTREV-BLOCKED blocked

grep -Fq 'finding bloqueante' "$WORKDIR/out/EXTREV-TRUSTED/review/60_findings.md" || fail 'blocking finding not visible'
grep -Fq 'recomendacao nao bloqueante' "$WORKDIR/out/EXTREV-TRUSTED/review/60_findings.md" || fail 'non-blocking recommendation not visible'
grep -Fq 'duvida nao promovida a defeito' "$WORKDIR/out/EXTREV-TRUSTED/review/60_findings.md" || fail 'question was not preserved'
grep -Fq 'Codigo fora do diff e contexto nao atribuivel' "$WORKDIR/out/EXTREV-TRUSTED/review/11_diff_identity.md" || fail 'outside-diff attribution guard missing'
grep -Fq 'CI ausente visivel' "$WORKDIR/out/EXTREV-TRUSTED/review/51_validation_gaps.md" || fail 'missing CI gap not visible'
grep -Fq 'Comentario apenas proposto' "$WORKDIR/out/EXTREV-TRUSTED/review/71_proposed_comments.md" || fail 'manual comment proposal missing'
grep -Fq 'BLOQUEADO_POR_CONTEXTO' "$WORKDIR/out/EXTREV-BLOCKED/review/70_final_review.md" || fail 'blocked baseline did not produce blocked outcome'
grep -Fq 'NAO_EXECUTADA_POR_BASELINE' "$WORKDIR/out/EXTREV-BLOCKED/review/60_findings.md" || fail 'blocked baseline produced attributable findings'
pass 'trusted and blocked review scenarios preserve all required distinctions'

[[ "$(git -C "$REVIEW_REPO" rev-parse HEAD)" == "$REPO_HEAD_BEFORE" ]] || fail 'reviewed repo HEAD changed'
[[ "$(git -C "$REVIEW_REPO" write-tree)" == "$REPO_TREE_BEFORE" ]] || fail 'reviewed repo tree changed'
[[ "$(git -C "$REVIEW_REPO" status --porcelain=v1)" == "$REPO_STATUS_BEFORE" ]] || fail 'reviewed repo worktree changed'
pass 'reviewed repository hash and status remained unchanged'

printf 'smoke external_review OK\n'