# PROMPT CONTRACT IMPLEMENTATION v1
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Implementation prompt generation
Applies to: `eaw implement`

---

## 1. Objetivo

Este documento define o contrato estrutural obrigatorio para os prompts gerados pela fase Implementation do EAW.

Seu proposito e:

- Garantir determinismo na fase de planejamento e execucao
- Evitar divergencia estrutural entre o prompt e o fluxo real observado
- Impedir expansao implicita de escopo durante a implementacao
- Assegurar rastreabilidade entre `40_next_steps.md` e os artefatos de implementation
- Controlar boundaries de leitura e escrita no card atual em ambiente multi-repo
- Bloquear execucao corretiva quando o objetivo soberano do card exigir auditoria previa ainda nao materializada

Nenhum prompt de Implementation pode violar este contrato.

---

## 2. Header Oficial (v1)

O prompt de Implementation deve iniciar com o bloco `RUNTIME_ENVIRONMENT` antes de `ROLE`, sem modificacoes estruturais nem secoes extras fora do contrato:

```text
RUNTIME_ENVIRONMENT

CARD_ID: {{CARD}}
TRACK_ID: {{TRACK_ID}}
STEP_ID: {{STEP_ID}}
WORKDIR: {{EAW_WORKDIR}}
CARD_DIR: {{CARD_DIR}}
OUT_DIR: {{OUT_DIR}}

TARGET_REPOSITORIES:
{{TARGET_REPOS}}

WRITE_ALLOWLIST:
{{WRITE_ALLOWLIST}}

CRITICAL_PATHS:
{{CRITICAL_PATHS}}

ROLE
...
```

O bloco `RUNTIME_ENVIRONMENT` e soberano para a fase Implementation, deve ser materializado pelo runtime no inicio do prompt final e nao pode ser redefinido por templates sem manter a mesma estrutura e a sequencia imediata `RUNTIME_ENVIRONMENT` -> `ROLE`.

## 3. Regras Globais Imutaveis

O prompt de Implementation nao pode:

- Modificar `RUNTIME_ROOT`
- Alterar arquivos fora da allowlist definida em `implementation/00_scope.lock.md`
- Escrever artefatos fora de `CARD_DIR`
- Expandir escopo alem de `investigations/40_next_steps.md` e do `10_change_plan.md`
- Alterar layout estrutural de saida da trilha
- Executar automacoes destrutivas
- Refatorar, otimizar ou alterar contratos publicos fora do plano aprovado
- Reduzir auditoria ampla a patch local sem justificativa evidencial e rastreavel

Leitura de `TARGET_REPOS` e permitida apenas para implementar o que foi aprovado. Escrita de codigo fica restrita ao que a allowlist do scope lock autorizar.

## 4. Sequencia Oficial da Trilha

A fase Implementation:

1. Executa somente apos Analyze concluido
2. Consome `investigations/40_next_steps.md`
3. Gera `implementation/implementation_planning_agent_prompt.md`
4. Gera `implementation/implementation_executor_agent_prompt.md`
5. Materializa ou preserva `implementation/00_scope.lock.md`
6. Materializa ou preserva `implementation/10_change_plan.md`
7. Materializa ou preserva `implementation/20_patch_notes.md`
8. Gera prompts e execucao sem alterar runtime, templates ou layout externo

Nenhuma etapa fora desta sequencia pode ser adicionada pelo prompt.

## 5. Artefatos e Dependencias

| Categoria | Caminho | Regra |
| --- | --- | --- |
| Entrada obrigatoria | `investigations/40_next_steps.md` | Deve existir antes do inicio da fase |
| Artefato runtime | `implementation/implementation_planning_agent_prompt.md` | Prompt auxiliar gerado pelo runtime |
| Artefato runtime | `implementation/implementation_executor_agent_prompt.md` | Prompt auxiliar gerado pelo runtime |
| Artefato obrigatorio | `implementation/00_scope.lock.md` | Define in scope, out of scope e allowlist soberana |
| Artefato obrigatorio | `implementation/10_change_plan.md` | Define steps numerados, hipoteses `H[0-9]+` selecionadas e validacao obrigatoria |
| Artefato obrigatorio | `implementation/20_patch_notes.md` | Permanece parte do layout oficial da fase |
| Gate obrigatorio | `investigations/20_findings.md`, `investigations/30_hypotheses.md`, `investigations/40_next_steps.md`, `implementation/00_scope.lock.md`, `implementation/10_change_plan.md` | Devem, em conjunto, cobrir o objetivo soberano do card antes da execucao corretiva |
| Boundary de escrita | `implementation/` | Artefatos da fase ficam confinados a este diretorio |
| Dependencia runtime | `/home/user/dev/EAW-tool/scripts/commands/cmd_implement.sh` | Fonte de verdade de execucao no runtime |
| Espelho no repositorio | `scripts/commands/cmd_implement.sh` | Espelho versionado em `EAW-dev`, atualmente identico ao runtime |

Nao ha permissao para alterar `prompts/`, `scripts/commands/`, `EAW-tool` ou qualquer layout externo da trilha como parte deste contrato.

## 6. Rastreabilidade Obrigatoria

O prompt de Implementation deve:

- Declarar `EAW_WORKDIR`, `RUNTIME_ROOT`, `CONFIG_SOURCE`, `OUT_DIR` e `CARD_DIR` no header
- Declarar `CARD_ID`, `TRACK_ID`, `STEP_ID`, `TARGET_REPOSITORIES`, `WRITE_ALLOWLIST` e `CRITICAL_PATHS` no bloco `RUNTIME_ENVIRONMENT`
- Tratar `investigations/40_next_steps.md` como base unica do planejamento
- Permitir os artefatos auxiliares `implementation/implementation_planning_agent_prompt.md` e `implementation/implementation_executor_agent_prompt.md` quando emitidos pelo runtime
- Exigir rastreabilidade explicita entre hipoteses `H[0-9]+` selecionadas, `40_next_steps.md` e `implementation/10_change_plan.md`
- Exigir que `implementation/00_scope.lock.md` contenha allowlist de escrita e regra de escrita
- Preservar a existencia de `implementation/20_patch_notes.md` no layout oficial da fase
- Exigir que prompts e runtime bloqueiem `implementation_planning` e `implementation_executor` quando `investigations/*` e `implementation/*` nao cobrirem integralmente o objetivo soberano do card
- Exigir que a allowlist soberana derive de `investigations/40_next_steps.md`, `implementation/00_scope.lock.md` e `implementation/10_change_plan.md`, ou de fatiamento explicitamente justificado e rastreavel

## 7. Principios Obrigatorios

- Determinismo > criatividade
- Plano antes de execucao
- Micro-passos rastreaveis
- Scope lock soberano
- Nenhuma alteracao funcional fora do plano aprovado
- Nunca inferir comportamento nao documentado
- Objetivo soberano do card acima de hipotese dominante local

Fail conditions bloqueantes da fase:

- Ausencia de `investigations/40_next_steps.md`
- Cobertura insuficiente do objetivo do card por `investigations/*` e `implementation/*`
- `RUNTIME_ROOT` invalido ou sem `./scripts/eaw`
- `CONFIG_SOURCE` ausente
- Ausencia de `implementation/00_scope.lock.md` ou `implementation/10_change_plan.md` quando exigidos pelo fluxo
- Tentativa de escrita fora da allowlist ou fora de `CARD_DIR`
- Divergencia sem justificativa rastreavel entre o objetivo soberano do card e o escopo operacional gerado
- Tentativa de emitir saida fora dos artefatos observados da fase: `implementation/implementation_planning_agent_prompt.md`, `implementation/implementation_executor_agent_prompt.md`, `implementation/00_scope.lock.md`, `implementation/10_change_plan.md` e `implementation/20_patch_notes.md`
- Tentativa de alterar runtime, templates, CLI, layout externo ou arquivos fora do escopo aprovado

## 8. Compatibilidade

Este contrato nao altera:

- CLI externa
- Layout de diretorios
- Templates em `prompts/`
- Runtime em `EAW-tool`
- Suporte multi-repo

Backward compatibility preservada.

## 9. Evolucao

Qualquer alteracao neste contrato deve:

- Criar nova versao (`PROMPT_CONTRACT_IMPLEMENTATION_v2.md`)
- Declarar breaking vs non-breaking
- Atualizar o header oficial se necessario
- Manter aderencia ao comportamento real da fase

## 10. Status

`PROMPT_CONTRACT_IMPLEMENTATION_v1` passa a definir o contrato oficial da fase Implementation.

O prompt de `eaw implement` deve obedecer integralmente a este contrato.
