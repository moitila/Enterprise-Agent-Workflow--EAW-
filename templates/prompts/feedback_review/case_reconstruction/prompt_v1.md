{{RUNTIME_ENVIRONMENT}}

ROLE
- Analista de evidencias EAW responsavel por reconstruir a unidade minima de analise
  para cada execucao de fase presente no corpus congelado.

OBJECTIVE
- Para cada EXPECTED_EXECUTION_ID do manifesto, reconstruir:
  track + fase + card + prompt operacional executado + prompt de feedback + agente/skills
  + artefatos produzidos + handoff + fase seguinte + feedback produzido + resultado observado.
- Usar somente prompts materializados em CARD_DIR/prompts/ (nao templates atuais).
- Registrar divergencias entre template atual e prompt materializado.
- Casos com dados ausentes recebem status INCOMPLETO com lista de itens faltantes.
- Produzir analysis/20_cases.md.

INPUT
- CARD=${CARD}
- EAW_WORKDIR=${EAW_WORKDIR}
- CARD_DIR=${CARD_DIR}
- RUNTIME_ROOT=${RUNTIME_ROOT}
- REQUIRED_ARTIFACTS:
  - ${CARD_DIR}/corpus/00_manifest.md
  - ${CARD_DIR}/corpus/10_inventory.md

READ_SCOPE
- ${CARD_DIR}/corpus/00_manifest.md
- ${CARD_DIR}/corpus/10_inventory.md
- Para cada card da track de origem (paths em 10_inventory.md):
  - ${EAW_WORKDIR}/out/<CARD>/prompts/
  - ${EAW_WORKDIR}/out/<CARD>/provenance/prompts_used.yaml
  - ${EAW_WORKDIR}/out/<CARD>/investigations/
  - ${EAW_WORKDIR}/out/<CARD>/execution_journal.jsonl
  - ${EAW_WORKDIR}/out/<CARD>/state_card_*.yaml
  - ${EAW_WORKDIR}/ci_feedback/<track_de_origem>/<fase>/

WRITE_SCOPE
- Somente ${CARD_DIR}/analysis/20_cases.md

OUTPUT
- ${CARD_DIR}/analysis/20_cases.md

OUTPUT_STRUCTURE

analysis/20_cases.md:
---
# Case Reconstruction — <CARD>
Track de origem: <track_id>
Total de execucoes no corpus: <N>

## Caso <ID> — <card> / <fase>

| Campo | Valor |
|---|---|
| execution_id | <ID> |
| card | <card_id> |
| fase | <phase_id> |
| prompt_operacional | <path ou hash> |
| prompt_feedback | <path ou ausente> |
| agente_skills | <lista ou desconhecido> |
| artefatos_produzidos | <lista de paths> |
| handoff | <conteudo ou ausente> |
| fase_seguinte | <phase_id ou N/A> |
| feedback_produzido | <path ou ausente> |
| resultado_observado | <descricao curta> |
| divergencia_template | <sim/nao + detalhe> |
| status_reconstrucao | COMPLETO / INCOMPLETO |
| dados_ausentes | <lista ou nenhum> |
---

RULES
- Executar pre-check antes de qualquer acao:
  echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd "${RUNTIME_ROOT}"
  test -f ./scripts/eaw
  test -f "${EAW_WORKDIR}/config/repos.conf"
- O prompt materializado em prompts/ tem prioridade sobre o template atual.
- Divergencia entre template atual e prompt materializado deve ser registrada por caso.
- Dados ausentes nao devem ser inferidos; marcar como ausente com motivo.
- Cada caso do manifesto deve aparecer no arquivo de saida, mesmo que INCOMPLETO.
- Emitir handoff ao final:
  printf '{"from_phase":"case_reconstruction","status":"completed","messages":[],"codes":[]}'
  > ${CARD_DIR}/investigations/20_handoff.json

FORBIDDEN
- Nao avaliar ou classificar feedbacks (reservado para findings).
- Nao usar templates atuais como substitutos de prompts materializados ausentes sem registrar.
- Nao criar arquivos fora de ${CARD_DIR}/analysis/20_cases.md.
- Nao inferir dados ausentes; registrar a ausencia.

FAIL_CONDITIONS
- Falhar se pre-check falhar.
- Falhar se ${CARD_DIR}/analysis/20_cases.md estiver ausente ao final.
- Falhar se qualquer EXPECTED_EXECUTION_ID do manifesto estiver ausente do arquivo de casos.
- Falhar se ${CARD_DIR}/investigations/20_handoff.json estiver ausente.

skills: []
