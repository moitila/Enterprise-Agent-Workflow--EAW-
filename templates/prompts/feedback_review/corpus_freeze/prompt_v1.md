{{RUNTIME_ENVIRONMENT}}

ROLE
- Analista de corpus EAW responsavel por definir e congelar o corpus da revisao
  por identidade dos conjuntos, sem estimativas silenciosas ou sampling.

OBJECTIVE
- Determinar os criterios de inclusao (track de origem, intervalo de cards,
  criterios de fase) e enumerar EXPECTED_EXECUTION_IDS.
- Descobrir DISCOVERED_FEEDBACK_IDS a partir dos arquivos existentes em
  ${EAW_WORKDIR}/ci_feedback/<track>/.
- Reconciliar por identidade: ANALYZED_FEEDBACK_IDS e MISSING_FEEDBACK_EXECUTION_IDS.
- Congelar o manifesto corpus/00_manifest.md e o inventario corpus/10_inventory.md.
- Casos inacessiveis sao registrados com IDs pendentes; nunca estimados silenciosamente.

INPUT
- CARD=${CARD}
- EAW_WORKDIR=${EAW_WORKDIR}
- CARD_DIR=${CARD_DIR}
- RUNTIME_ROOT=${RUNTIME_ROOT}
- REQUIRED_ARTIFACTS:
  - ${CARD_DIR}/ingest/raw_card_explication.md

READ_SCOPE
- ${CARD_DIR}/ingest/raw_card_explication.md
- ${CARD_DIR}/investigations/00_intake.md
- ${EAW_WORKDIR}/ci_feedback/<track_de_origem>/ (discovery de feedbacks existentes)
- ${EAW_WORKDIR}/out/<CARD>/state_card_*.yaml e execution_journal.jsonl de cada card
  da track de origem (enumerar execucoes esperadas)

WRITE_SCOPE
- Somente ${CARD_DIR}/corpus/00_manifest.md
- Somente ${CARD_DIR}/corpus/10_inventory.md

OUTPUT
- ${CARD_DIR}/corpus/00_manifest.md
- ${CARD_DIR}/corpus/10_inventory.md

OUTPUT_STRUCTURE

corpus/00_manifest.md:
---
# Corpus Manifest — <CARD>
Track de origem: <track_id>
Intervalo de cards: <start> a <end>
Criterios de inclusao: <declarados no ingest>
Data de congelamento: <YYYY-MM-DD>

## EXPECTED_EXECUTION_IDS
| ID | card | fase |

## DISCOVERED_FEEDBACK_IDS
| ID | path | fase |

## ANALYZED_FEEDBACK_IDS
| ID | path | fase |

## MISSING_FEEDBACK_EXECUTION_IDS
| ID | card | fase | motivo_da_ausencia |
---

corpus/10_inventory.md:
---
# Corpus Inventory — <CARD>

## Cards incluidos
| card | fases_executadas | feedbacks_encontrados | execucoes_sem_feedback |

## Arquivos de feedback
| path | fase | card | id_unico |

## IDs unicos de feedback
<lista deduplificada>
---

RULES
- Executar pre-check antes de qualquer acao:
  echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd "${RUNTIME_ROOT}"
  test -f ./scripts/eaw
  test -f "${EAW_WORKDIR}/config/repos.conf"
- Reconciliar por identidade dos conjuntos, nao por contagem; contagens coincidentes
  com IDs divergentes sao registradas como divergencia.
- Nunca omitir IDs pendentes ou inacessiveis; registrar com motivo.
- A track de origem e o intervalo de cards vem do ingest; nunca inferir por memoria.
- Emitir handoff ao final:
  printf '{"from_phase":"corpus_freeze","status":"completed","messages":[],"codes":[]}'
  > ${CARD_DIR}/investigations/20_handoff.json

FORBIDDEN
- Nao realizar analise analitica de feedbacks (reservado para findings).
- Nao criar arquivos fora de ${CARD_DIR}/corpus/.
- Nao amostrar (sampling) silenciosamente quando o corpus estiver parcialmente acessivel.
- Nao usar contagem como proxy de identidade.

FAIL_CONDITIONS
- Falhar se pre-check falhar.
- Falhar se ${CARD_DIR}/corpus/00_manifest.md estiver ausente ao final.
- Falhar se ${CARD_DIR}/corpus/10_inventory.md estiver ausente ao final.
- Falhar se qualquer um dos quatro conjuntos de IDs estiver ausente do manifesto.
- Falhar se ${CARD_DIR}/investigations/20_handoff.json estiver ausente.

skills: []
