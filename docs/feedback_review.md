# feedback_review — EAW Track

## Descricao

`feedback_review` e a track EAW para revisao sistematica do feedback espontaneo
produzido por agentes durante a execucao de outra track (track de origem).

Cada execucao da `feedback_review` analisa uma unica track de origem (ex.: `bug_onboarding`),
cruzando feedback com: prompts operacionais reais, artefatos produzidos, handoffs,
journal e resultado observado.

A track transforma feedback espontaneo em backlog priorizado por classe de causa,
com rastreabilidade e evidencias documentadas.

## Fases

A track possui **6 fases** em sequencia:

| Fase | Artefatos de saida | Responsabilidade |
|---|---|---|
| `corpus_freeze` | `corpus/00_manifest.md`, `corpus/10_inventory.md` | Definir e congelar o corpus por identidade dos conjuntos |
| `case_reconstruction` | `analysis/20_cases.md` | Reconstruir a unidade minima de analise para cada execucao |
| `findings` | `analysis/30_findings.md`, `35_feedback_matrix.md`, `36_prompt_quality.md`, `37_feedback_prompt_eval.md` | Avaliar cada feedback contra evidencias; avaliar qualidade dos prompts |
| `phase_alignment` | `analysis/40_alignment_matrix.md` | Analisar harmonia entre fases consecutivas da track revisada |
| `diagnosis` | `analysis/50_diagnosis.md` | Diagnostico consolidado por categoria de causa |
| `backlog_finalization` | `analysis/60_backlog.md`, `61_appends_log.md`, `62_validation_report.md` + appends nos feedbacks originais | Gerar backlog, registrar appends idempotentes, validar completude |

## Como usar

Criar um card feedback_review e fornecer o ingest no arquivo raw_card_explication.md:

```bash
cd /path/to/eaw
export EAW_WORKDIR=/path/to/.eaw
./scripts/eaw card MEU-REVIEW-01 --track feedback_review "Revisar feedback da track bug_onboarding"
```

Editar o ingest antes de avancar:
`$EAW_WORKDIR/out/MEU-REVIEW-01/ingest/raw_card_explication.md`

Avancar fases:
```bash
./scripts/eaw next MEU-REVIEW-01
```

## Skills por fase

| Fase | skills declaradas | Justificativa |
|---|---|---|
| corpus_freeze | [] | Navegacao de paths e reconciliacao de identidade; workspace skill suficiente |
| case_reconstruction | [] | Coleta de evidencias estruturada; sem avaliacao analitica |
| findings | [eaw_reviewer] | Classificacao baseada em evidencia, avaliacao de qualidade de prompts |
| phase_alignment | [] | Leitura cruzada de artefatos ja produzidos; sem review analitico |
| diagnosis | [eaw_reviewer] | Sintese com classificacao por causa; derivacao de recomendacoes de evidencias |
| backlog_finalization | [] | Operacional de encerramento deterministico; sem analise nova |

## Escopo de analise

- **Horizontal dentro de uma track de origem**: multiplos cards, multiplas fases, multiplos feedbacks.
- **Corpus reconciliado por identidade**: nao somente por contagem.
- **Sem sampling silencioso**: IDs inacessiveis sao registrados, nunca estimados.
- **Dois prompts distintos**: o prompt operacional e o prompt de feedback sao avaliados separadamente.

## Escrita fora do CARD_DIR

A fase `backlog_finalization` escreve appends idempotentes nos arquivos originais de
feedback em `$EAW_WORKDIR/ci_feedback/<track_de_origem>/<fase>/`.

- Formato: `<YYYY-MM-DDTHH:MM:SS> | agente=<CARD> | track=feedback_review | card=<CARD> | fase=backlog_finalization | resultado=<RESULTADO>`
- Chave de idempotencia: `card=<CARD>|fase=backlog_finalization`
- Verificacao previa com grep -Fq antes de qualquer append.

## Vocabulario canonico

**Classificacao de feedbacks** (fase findings):
`confirmado`, `parcialmente confirmado`, `contradito pelas evidencias`, `nao verificavel`,
`duplicado`, `obsoleto`, `sem acao necessaria`, `necessita nova evidencia`

**Resultado do append** (fase backlog_finalization):
`BACKLOG:<ID>`, `NO_ACTION`, `NEEDS_EVIDENCE`, `CORRECAO_VERIFICADA`,
`PROBLEMA_PERSISTE`, `OBSOLETO`

**Categorias de causa** (fases findings e diagnosis):
`prompt operacional`, `prompt de feedback`, `design da track`, `handoff`, `scaffold`,
`contrato`, `documentacao`, `testes`, `skill`, `executor`, `orquestrador`, `runtime`,
`investigativo/NEEDS_EVIDENCE`, `obsoleto`

## Piloto recomendado

Apos a validacao da track, o proximo passo e executar um card real sobre `bug_onboarding`:

```bash
./scripts/eaw card EAW-FBR-BUG-ONBOARD-01 --track feedback_review \
  "Revisao sistematica do feedback da track bug_onboarding"
```

Preencher o ingest especificando:
- Track de origem: `bug_onboarding`
- Intervalo de cards a revisar (ex.: todos os cards disponiveis)
- Criterios de inclusao

## Notas de design

- A skill `eaw_feedback_reviewer` NAO foi criada nesta versao. `eaw_reviewer` e suficiente.
  A necessidade pode ser revisada apos a primeira execucao piloto.
- `skip_when` nao e declarado nesta versao: toda fase produz artefatos consumidos pela seguinte.
- Writes externos ao CARD_DIR ocorrem somente na fase `backlog_finalization` e sao
  declarados explicitamente como excecao operacional autorizada naquele prompt.
