# PHASE: IMPLEMENT — Minimal Contract (v1)

## Purpose
Este contrato existe para definir, de forma objetiva e verificavel, quando a fase IMPLEMENT pode ser considerada concluida no fluxo EAW, reduzindo execucao improvisada, expansao indevida de escopo, refatoracoes nao solicitadas e mudancas sem rastreabilidade.

## Inputs (required)
- Referencia obrigatoria: `out/<CARD>/investigations/40_next_steps.md`.
- Equivalente permitido na v1: nao existe equivalente definido; somente `40_next_steps.md` atende ao requisito obrigatorio de entrada.

## Required Artifacts (inside out/<CARD>/implementation/)
- `00_scope.lock.md`: define o escopo permitido da execucao, incluindo os arquivos que podem ser alterados na fase.
- `10_change_plan.md`: registra o plano objetivo de mudancas a executar, alinhado aos next steps aprovados.
- `20_patch_notes.md`: registra evidencias das alteracoes aplicadas e rastreabilidade entre plano e mudancas realizadas.

## Mandatory Rules
- Mudanca minima: executar apenas o necessario para cumprir o plano definido.
- Proibicao de refatoracao nao solicitada: nao realizar refatoracao fora do que estiver explicitamente no plano.
- Proibicao de expansao de escopo: nao introduzir requisitos, artefatos ou alteracoes fora do escopo acordado.
- Apenas arquivos permitidos pelo `00_scope.lock.md` podem ser alterados.
- Toda alteracao aplicada deve ser registrada com evidencia em `20_patch_notes.md`.
- Se faltar input obrigatorio, a fase IMPLEMENT deve ser abortada.

## Definition of Done (DoD)
- `out/<CARD>/investigations/40_next_steps.md` existe e foi usado como base do plano.
- `out/<CARD>/implementation/00_scope.lock.md` existe e lista explicitamente os arquivos permitidos.
- `out/<CARD>/implementation/10_change_plan.md` existe e cobre os itens de execucao da fase.
- `out/<CARD>/implementation/20_patch_notes.md` existe e registra as alteracoes aplicadas.
- Nao ha alteracoes em arquivos fora do permitido por `00_scope.lock.md`.
- Nao ha mudancas aplicadas fora do plano definido em `10_change_plan.md`.

## Compatibility
- O contrato v1 e aditivo e, por padrao, nao altera comportamento legado do fluxo EAW.

## Validation Hooks (future)
- Verificar existencia de `out/<CARD>/investigations/40_next_steps.md` antes de iniciar IMPLEMENT.
- Verificar existencia dos tres artefatos obrigatorios em `out/<CARD>/implementation/`.
- Verificar consistencia entre escopo permitido (`00_scope.lock.md`) e arquivos realmente alterados.
- Verificar consistencia entre itens do `10_change_plan.md` e registros do `20_patch_notes.md`.
- Falhar validacao quando houver input obrigatorio ausente.
