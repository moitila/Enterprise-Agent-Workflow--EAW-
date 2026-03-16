# PROMPT CONTRACT ANALYZE v1
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Analyze prompt generation
Applies to: `eaw analyze`

---

## 1. Objetivo

Este documento define o contrato estrutural obrigatorio para os prompts gerados pela fase Analyze do EAW.

Seu proposito e:

- Garantir determinismo na geracao de findings, hypotheses e planning
- Evitar divergencia estrutural entre o prompt e o fluxo real observado
- Impedir expansao implicita de escopo durante a investigacao
- Assegurar rastreabilidade entre Intake e Implementation
- Controlar leitura e escrita no card atual em ambiente multi-repo

Nenhum prompt de Analyze pode violar este contrato.

---

## 2. Header Oficial (v1)

O prompt de `eaw analyze` deve iniciar com o bloco `RUNTIME_ENVIRONMENT` antes de `ROLE`, sem modificacoes estruturais nem secoes extras fora do contrato:

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

O bloco `RUNTIME_ENVIRONMENT` e soberano para a fase Analyze, deve ser materializado pelo runtime no inicio do prompt final e nao pode ser redefinido por templates sem manter a mesma estrutura e a sequencia imediata `RUNTIME_ENVIRONMENT` -> `ROLE`.

## 3. Regras Globais Imutaveis

O prompt de Analyze nao pode:

- Modificar `RUNTIME_ROOT`
- Alterar `TARGET_REPOS`
- Escrever fora de `CARD_DIR`
- Expandir escopo alem do intake corrente
- Alterar layout estrutural de saida em `investigations/`
- Executar automacoes destrutivas
- Criar artefatos fora da trilha oficial

Leitura e escrita ficam restritas ao card atual, com leitura de codigo em `TARGET_REPOS` apenas para investigacao e sem qualquer escrita.

## 4. Sequencia Oficial da Trilha

A fase Analyze:

1. Executa somente apos Intake concluido
2. Consome `investigations/00_intake.md`
3. Gera os prompts auxiliares `investigations/findings_agent_prompt.md`, `investigations/hypotheses_agent_prompt.md` e `investigations/planning_agent_prompt.md`
4. Pode materializar `TEST_PLAN_<CARD>.md` na raiz do card quando ausente
5. Produz `investigations/20_findings.md`
6. Produz `investigations/30_hypotheses.md`
7. Produz `investigations/40_next_steps.md`
8. Nao pode antecipar alteracoes da fase Implementation

Nenhuma etapa fora desta sequencia pode ser adicionada pelo prompt.

## 5. Artefatos e Dependencias

| Categoria | Caminho | Regra |
| --- | --- | --- |
| Entrada obrigatoria | `investigations/00_intake.md` | Deve existir antes do inicio da fase |
| Artefato runtime | `investigations/findings_agent_prompt.md` | Prompt auxiliar gerado pelo runtime |
| Artefato runtime | `investigations/hypotheses_agent_prompt.md` | Prompt auxiliar gerado pelo runtime |
| Artefato runtime | `investigations/planning_agent_prompt.md` | Prompt auxiliar gerado pelo runtime |
| Artefato runtime | `TEST_PLAN_<CARD>.md` | Placeholder auxiliar criado na raiz do card quando ausente |
| Saida obrigatoria | `investigations/20_findings.md` | Consolida evidencias observadas |
| Saida obrigatoria | `investigations/30_hypotheses.md` | Formaliza hipoteses rastreaveis via `H[0-9]+` |
| Saida obrigatoria | `investigations/40_next_steps.md` | Define proximo passo deterministico para Implementation |
| Dependencia de baseline | `docs/PROMPT_CONTRACT_v1.md` | Define o nivel minimo de rigor estrutural |
| Dependencia runtime | `/home/user/dev/EAW-tool/scripts/commands/cmd_analyze.sh` | Fonte de verdade de execucao no runtime |
| Espelho no repositorio | `scripts/commands/cmd_analyze.sh` | Espelho versionado em `EAW-dev`, atualmente identico ao runtime |

Nao ha permissao para escrever em `prompts/`, `scripts/commands/`, `docs/` fora do proprio contrato, ou em `EAW-tool`.

## 6. Rastreabilidade Obrigatoria

O prompt de Analyze deve:

- Declarar `EAW_WORKDIR`, `RUNTIME_ROOT`, `CONFIG_SOURCE`, `OUT_DIR` e `CARD_DIR` no header
- Declarar `CARD_ID`, `TRACK_ID`, `STEP_ID`, `TARGET_REPOSITORIES`, `WRITE_ALLOWLIST` e `CRITICAL_PATHS` no bloco `RUNTIME_ENVIRONMENT`
- Tratar `investigations/00_intake.md` como unica entrada obrigatoria da fase
- Permitir os artefatos auxiliares `findings_agent_prompt.md`, `hypotheses_agent_prompt.md`, `planning_agent_prompt.md` e `TEST_PLAN_<CARD>.md` quando emitidos pelo runtime
- Preservar a relacao causal entre findings, hypotheses e next steps
- Referenciar explicitamente identificadores `H[0-9]+` quando uma hipotese for promovida para plano
- Manter rastreabilidade suficiente para a fase Implementation operar sobre `investigations/40_next_steps.md`

## 7. Principios Obrigatorios

- Determinismo > criatividade
- Evidencia > opiniao
- Investigacao antes de plano
- Micro-passos rastreaveis
- Nenhuma alteracao funcional no sistema
- Nunca inferir comportamento nao documentado

Fail conditions bloqueantes da fase:

- Ausencia de `investigations/00_intake.md`
- `RUNTIME_ROOT` invalido ou sem `./scripts/eaw`
- `CONFIG_SOURCE` ausente
- Tentativa de escrita fora de `CARD_DIR`
- Tentativa de emitir saida fora dos artefatos observados da fase: `investigations/findings_agent_prompt.md`, `investigations/hypotheses_agent_prompt.md`, `investigations/planning_agent_prompt.md`, `TEST_PLAN_<CARD>.md`, `investigations/20_findings.md`, `investigations/30_hypotheses.md` e `investigations/40_next_steps.md`

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

- Criar nova versao (`PROMPT_CONTRACT_ANALYZE_v2.md`)
- Declarar breaking vs non-breaking
- Atualizar o header oficial se necessario
- Manter aderencia ao comportamento real da fase

## 10. Status

`PROMPT_CONTRACT_ANALYZE_v1` passa a definir o contrato oficial da fase Analyze.

O prompt de `eaw analyze` deve obedecer integralmente a este contrato.
