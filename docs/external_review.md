# External Review Track

## Finalidade

`external_review` revisa alteracoes produzidas fora do EAW sem modificar codigo, Git, PRs, cards, CI ou fontes externas. O fluxo fixa as fontes e o diff antes de avaliar comportamento, requisitos e evidencias, preservando lacunas como parte auditavel do parecer.

## Pre-requisitos

O intake deve identificar o repositorio alvo, PR ou card de origem, base, head, fontes adicionais, criterios de aceite, evidencias de teste e CI, restricoes de acesso e lacunas conhecidas. Referencias sem conteudo acessivel nao contam como evidencia lida.

## Fases

1. `source_inventory`: congela identidade, proveniencia, disponibilidade e lacunas das fontes.
2. `baseline_validation`: comprova repositorio, base, head, merge-base e corpus revisavel.
3. `functional_context`: estrutura requisitos, criterios e contratos comprovados.
4. `change_mapping`: mapeia diff, dependencias e superficie de impacto.
5. `technical_review`: avalia somente mudancas atribuiveis.
6. `evidence_review`: avalia testes, CI, documentacao e evidencias funcionais.
7. `findings_consolidation`: deduplica e classifica findings, duvidas e recomendacoes.
8. `final_opinion`: emite parecer, cobertura, limitacoes e comentarios propostos.

## Artefatos

Os artefatos ficam em `review/` dentro do diretorio do card. As fases nao-finais tambem emitem `investigations/20_handoff.json` com envelope compacto, `messages:[]` e `codes:[]`. A fase final produz `70_final_review.md`, `71_proposed_comments.md` e `72_validation_report.md` e nao emite handoff.

## Resultados Finais

- `APROVADO`: baseline confiavel, cobertura suficiente e nenhum finding bloqueante.
- `APROVADO_COM_OBSERVACOES`: baseline confiavel, nenhum finding bloqueante e somente recomendacoes ou riscos residuais.
- `ALTERACOES_SOLICITADAS`: ao menos um finding confirmado exige alteracao.
- `BLOQUEADO_POR_CONTEXTO`: baseline, escopo, requisito essencial ou fonte obrigatoria nao foi comprovada.
- `BLOQUEADO_POR_EVIDENCIA`: baseline confiavel, mas testes, CI ou evidencias obrigatorias sao insuficientes.

## Comportamento Fail-closed

Sem repositorio, base, head e merge-base comprovados, nenhuma fase atribui defeitos ao autor. As fases posteriores registram `NAO_EXECUTADA_POR_BASELINE`, motivo e impacto. Codigo fora do diff pode servir de contexto, mas nao pode originar finding atribuivel.

## Operacao Read-only

A track nao altera working trees, refs, branches, commits ou estado remoto. Tambem nao publica comentarios, aprovacoes ou rejeicoes. `71_proposed_comments.md` contem somente texto candidato para publicacao manual posterior.

## Uso

Crie o card com a track instalada:

```bash
./scripts/eaw card REVIEW-123 --track external_review
```

Preencha o intake e avance manualmente, verificando os artefatos de cada fase antes do proximo ciclo:

```bash
./scripts/eaw preflight REVIEW-123
./scripts/eaw next REVIEW-123
```

Repita o ciclo de preflight e `next` ate a conclusao. A execucao das fases cabe a agentes isolados; somente o orquestrador avanca o estado do card.