# ARCH_REFACTOR Refactor Report

## Prompts encontrados

Fonte lida recursivamente em `/home/user/dev/.eaw/out/570/prompts/ARCH_REFACTOR`.

Fase `ingest`
- `Ingest/REFACTOR_INGEST.txt`
- `Ingest/REfactor_ingest_2txt`
- `Ingest/REFACTOR_INGEST_3.txt`
- `Ingest/REFACTOR_INGEST_4.txt`

Fase `intake`
- `intake/refactor_intake.txt`
- `intake/refactor_intake_2.txt`
- `intake/refactor_intake_3.txt`
- `intake/refactor_intake_4.txt`
- `intake/refactor_intake_5.txt`

Fase `findings`
- `FINDINGS/REFACTOR_FINDINGS.txt`
- `FINDINGS/REFACTOR_FINDINGS_2.txt`
- `FINDINGS/REFACTOR_FINDINGS_3.txt`
- `FINDINGS/REFACTOR_FINDINGS_4.txt`

Fase `hypotheses`
- `Hipoteses/REFACTOR_HIPOTESES.txt`
- `Hipoteses/REFACTOR_HIPOTESES_2.txt`
- `Hipoteses/REFACTOR_HIPOTESES_3.txt`
- `Hipoteses/REFACTOR_HIPOTESES_4.txt`

Fase `planning`
- `Planing/REFACTOR_PLANING.txt`
- `Planing/REFACTOR_PLANING_2.txt`
- `Planing/REFACTOR_PLANING_3.txt`
- `Planing/REFACTOR_PLANING_4.txt`
- `Planing/REFACTOR_PLANING_5.txt`

Fase `implementation_planning`
- `Planning/IMPLEMENTATION_PLANNING.txt`
- `Planning/IMPLEMENTATION_PLANNING_2.txt`
- `Planning/IMPLEMENTATION_PLANNING_3.txt`
- `Planning/IMPLEMENTATION_PLANNING_4.txt`

Fase `executor`
- `Executor/IMPLEMENTATION_EXECUTOR.txt`
- `Executor/IMPLEMENTATION_EXECUTOR_v2.txt`
- `Executor/IMPLEMENTATION_EXECUTOR_v3.txt`
- `Executor/IMPLEMENTATION_EXECUTOR_v4.txt`
- `Executor/IMPLEMENTATION_EXECUTOR_v5.txt`

Artefatos fora do fluxo oficial
- `Journal/Journal_VALIDATOR.txt`
- `Auditor/auditor.txt`

## Decisoes tomadas

- Mantive apenas as sete fases oficiais solicitadas: `ingest`, `intake`, `findings`, `hypotheses`, `planning`, `implementation_planning` e `executor`.
- Descartei `Journal` e `Auditor` por nao pertencerem ao fluxo oficial da track.
- Normalizei grafias divergentes:
  - `Hipoteses` -> `hypotheses`
  - `Planing` -> `planning`
  - `Executor` -> `executor`
- Padronizei todos os prompts para a estrutura exata:
  - `RUNTIME_ENVIRONMENT`
  - `ROLE`
  - `OBJECTIVE`
  - `INPUT`
  - `OUTPUT`
  - `READ_SCOPE`
  - `WRITE_SCOPE`
  - `RULES`
  - `FORBIDDEN`
  - `FAIL_CONDITIONS`
- Removi ids de card hardcoded como `688419REF*` e substitui por placeholders compativeis com o runtime.
- Padronizei caminhos reais usando a base `/home/user/dev/.eaw/out/<CARD>`.
- Alinhei a fase final ao identificador oficial do runtime: `implementation_executor`.
- Alinhei o diretório humano da fase final para `implementation_executor/`, eliminando a divergencia anterior com `executor/`.

## Base selecionada por fase

`ingest`
- Base principal: `REFACTOR_INGEST_4.txt`
- Complementos: `REFACTOR_INGEST_3.txt` e `REFACTOR_INGEST.txt`
- Motivo: melhor classificacao de intencao, separacao entre direcao local e global e maior rigor contra promocao indevida de sugestoes.

`intake`
- Base principal: `refactor_intake_5.txt`
- Complementos: `refactor_intake_4.txt` e `refactor_intake_2.txt`
- Motivo: melhor consumo de ingest estruturado, melhor sinal para pipeline e boa separacao entre problema, direcao e ambiguidades.

`findings`
- Base principal: `REFACTOR_FINDINGS_4.txt`
- Complementos: `REFACTOR_FINDINGS.txt`
- Motivo: melhor validacao contra ingest estruturado e direcao arquitetural, combinada com pre-check e baseline mais fortes.

`hypotheses`
- Base principal: `REFACTOR_HIPOTESES_4.txt`
- Complementos: `REFACTOR_HIPOTESES_2.txt`
- Motivo: regra explicita para nao gerar hipoteses desnecessarias e, quando necessarias, manter estrutura priorizada e controlada.

`planning`
- Base principal: `REFACTOR_PLANING_3.txt`
- Complementos: `REFACTOR_PLANING.txt`
- Motivo: melhor enforcement arquitetural sem vazar para implementacao, preservando plano atomico e criterios verificaveis.

`implementation_planning`
- Base principal: `IMPLEMENTATION_PLANNING_4.txt`
- Complementos: `IMPLEMENTATION_PLANNING.txt`
- Motivo: melhor rastreabilidade entre desvios, evidencias, plano e allowlist, sem perder o principio de nao introduzir design novo.

`executor`
- Base principal: `IMPLEMENTATION_EXECUTOR_v5.txt`
- Complementos: `IMPLEMENTATION_EXECUTOR.txt`
- Motivo: melhor controle de bloqueios, ordem de execucao, warnings como contratos e respeito a allowlist soberana.

## Melhorias aplicadas

- Adicionei `set -euo pipefail` em todas as fases.
- Restrigi explicitamente a `WRITE_ALLOWLIST` em todos os prompts.
- Reforcei a separacao de responsabilidades entre fases:
  - `ingest` apenas coleta e normaliza
  - `intake` apenas define o problema
  - `findings` apenas valida evidencias
  - `hypotheses` apenas explica incerteza residual
  - `planning` apenas alinha arquiteturalmente
  - `implementation_planning` apenas congela escopo executavel
  - `executor` apenas executa o plano aprovado
- Removi ambiguidade entre `planning` e `implementation_planning`, que aparecia em varias versoes de origem.
- Removi a divergencia de naming entre `executor` no material inicial e `implementation_executor` no runtime oficial.
- Removi saidas em `investigations/` para artefatos de implementacao e padronizei em `implementation/` para `00_scope.lock.md`, `10_change_plan.md` e `20_patch_notes.md`.
- Mantive a possibilidade de `hypotheses` gerar um arquivo minimo quando nao houver lacunas reais, evitando duplicacao da fase.

## Inconsistencias corrigidas

- Cards fixos e tracks antigas hardcoded nas versoes de origem.
- Mistura de portugues com ingles e naming inconsistente de fases.
- Estruturas diferentes de headings entre versoes.
- Escrita em caminhos inconsistentes entre `investigations/` e `implementation/`.
- Risco de vazamento de implementacao no `planning`.
- Risco de derivacao arquitetural indevida no `implementation_planning`.
- Risco de criacao estrutural no `executor` sem contrato suficientemente explicito.
- Dependencia de artefatos extras fora das fases oficiais.

## Validacao interna aplicada

- Estrutura dos sete prompts conferida contra o contrato unico de secoes.
- Cada fase recebeu `PRECHECK` fail-fast.
- Cada fase recebeu `WRITE_ALLOWLIST` restrita.
- Cada fase foi revisada para remover mistura de responsabilidade com fases adjacentes.
- O fluxo final respeita:
  - `ingest -> intake -> findings -> hypotheses -> planning -> implementation_planning -> executor`
