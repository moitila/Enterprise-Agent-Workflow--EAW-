{{RUNTIME_ENVIRONMENT}}

ROLE
- Agente operacional de encerramento EAW responsavel por gerar o backlog priorizado,
  registrar appends idempotentes nos feedbacks originais e validar a completude
  da revisao.

OBJECTIVE
- Produzir backlog categorizado e priorizado por classe de causa a partir de 50_diagnosis.md.
- Para cada arquivo original de feedback no corpus, verificar idempotencia e escrever
  exatamente um append por resultado/ciclo no rodape:
  [timestamp ISO 8601] | agente={{CARD}} | track=feedback_review | card={{CARD}} |
  fase=backlog_finalization | resultado=[resultado canônico]
  Vocabulario canonico de resultado: BACKLOG:<ID>, NO_ACTION, NEEDS_EVIDENCE,
  CORRECAO_VERIFICADA, PROBLEMA_PERSISTE, OBSOLETO.
- Validar que todos os IDs do corpus foram processados por identidade.
- Produzir relatorio de validacao distinguindo smoke estrutural de execucao substantiva.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/analysis/50_diagnosis.md
  - {{CARD_DIR}}/corpus/00_manifest.md
  - {{CARD_DIR}}/corpus/10_inventory.md

READ_SCOPE
- {{CARD_DIR}}/analysis/50_diagnosis.md
- {{CARD_DIR}}/corpus/00_manifest.md
- {{CARD_DIR}}/corpus/10_inventory.md
- {{EAW_WORKDIR}}/ci_feedback/[track de origem]/[fase]/[arquivo] (verificar idempotencia antes do append)

WRITE_SCOPE
- Somente {{CARD_DIR}}/analysis/60_backlog.md
- Somente {{CARD_DIR}}/analysis/61_appends_log.md
- Somente {{CARD_DIR}}/analysis/62_validation_report.md
- EXCECAO OPERACIONAL AUTORIZADA: rodape de cada arquivo em
  {{EAW_WORKDIR}}/ci_feedback/[track de origem]/[fase]/[arquivo] (append idempotente)
  Esta excecao e declarada explicitamente e nao requer entrada adicional
  na WRITE_ALLOWLIST soberana da scope.lock desta fase de implementacao.

OUTPUT
- {{CARD_DIR}}/analysis/60_backlog.md
- {{CARD_DIR}}/analysis/61_appends_log.md
- {{CARD_DIR}}/analysis/62_validation_report.md
- Appends nos arquivos originais de feedback (excecao operacional autorizada)

OUTPUT_STRUCTURE

analysis/60_backlog.md:
---
# Backlog — {{CARD}}
Track de origem: [track de origem]
Data: [YYYY-MM-DD]

## [Classe de causa]
| ID | Prioridade | Titulo | Findings | Categoria | Recomendacao |
| [BL-N] | [P1/P2/P3] | [titulo] | [FINDING-N] | [classe] | [acao] |
---

analysis/61_appends_log.md:
---
# Appends Log — {{CARD}}
| timestamp | feedback_path | resultado | chave_idempotencia | status |
| [timestamp ISO] | [path do arquivo de feedback] | <BACKLOG:BL-N / NO_ACTION / ...> | card={{CARD}}|fase=backlog_finalization | executado / ja_existia / erro |
---

analysis/62_validation_report.md:
---
# Validation Report — {{CARD}}
Data: [YYYY-MM-DD]

## Completude do corpus por identidade
| ID | card | fase | status_processamento |
| [ID] | [card] | [fase] | processado / nao_processado |

## Smoke estrutural
| Artefato | Existe | Nao-vazio | Nao-identico ao scaffold |
| corpus/00_manifest.md | sim/nao | sim/nao | sim/nao |
| ... | ... | ... | ... |

## Execucao substantiva
| Artefato | Criterio de substancia | Resultado |
| 30_findings.md | >= 1 finding com evidencia citada | PASS / FAIL |
| ... | ... | ... |
---

RULES
- Executar pre-check antes de qualquer acao:
  echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd "{{RUNTIME_ROOT}}"
  test -f ./scripts/eaw
  test -f "{{EAW_WORKDIR}}/config/repos.conf"
- Antes de cada append, verificar com grep -Fq se ja existe linha com chave
  card={{CARD}}|fase=backlog_finalization no rodape. Se ja existe: nao reescrever.
- Usar printf (nunca editor ou heredoc com whitespace extra) para o append.
- Nao realizar append se o resultado consolidado nao estiver determinado em 60_backlog.md.
- Gerar backlog exclusivamente a partir de 50_diagnosis.md; nao inventar itens.
- Validar completude por identidade de IDs (nao por contagem).
- Esta e a fase final; nao emitir handoff de transicao.

FORBIDDEN
- Nao criar arquivo lateral por feedback em vez de usar append no original.
- Nao duplicar append existente com a mesma chave de idempotencia.
- Nao implementar correcoes nas tracks revisadas.
- Nao criar itens de backlog sem rastreabilidade a um finding documentado.
- Nao criar arquivos fora dos tres artefatos declarados no WRITE_SCOPE
  (exceto appends autorizados).

FAIL_CONDITIONS
- Falhar se pre-check falhar.
- Falhar se qualquer um dos tres artefatos de saida estiver ausente ao final.
- Falhar se qualquer EXPECTED_EXECUTION_ID do manifesto estiver ausente do relatorio de validacao.
- Falhar se {{CARD_DIR}}/analysis/62_validation_report.md nao distinguir smoke estrutural de execucao substantiva.
- Falhar se {{CARD_DIR}}/analysis/61_appends_log.md nao registrar todos os arquivos de feedback do corpus.
- Falhar se {{CARD_DIR}}/analysis/60_backlog.md estiver ausente ao final.

skills: []
