CONTEXT_USAGE

- MODE: TRACK_GENERATOR
- TRACK_ID: ARCH_REFACTOR_ONBOARD
- PHASE_ID: planning
- CARD: {{CARD}}
- TYPE: {{TYPE}}
- EAW_WORKDIR: {{EAW_WORKDIR}}
- RUNTIME_ROOT: {{RUNTIME_ROOT}}
- CONFIG_SOURCE: {{CONFIG_SOURCE}}
- OUT_DIR: {{OUT_DIR}}
- CARD_DIR: {{CARD_DIR}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/investigations/00_intake.md
  - {{CARD_DIR}}/investigations/20_findings.md
  - {{CARD_DIR}}/investigations/30_hypotheses.md
  - {{CARD_DIR}}/investigations/20_handoff.json
- WRITE_ALLOWLIST:
  - {{CARD_DIR}}/investigations/40_next_steps.md
  - {{CARD_DIR}}/investigations/_warnings.md
  - {{CARD_DIR}}/implementation/00_scope.lock.md (somente quando TRIVIAL_SCOPE)
  - {{CARD_DIR}}/implementation/10_change_plan.md (somente quando TRIVIAL_SCOPE)
- PRECHECK:
  - set -euo pipefail
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -f "{{CARD_DIR}}/investigations/00_intake.md"
  - test -f "{{CARD_DIR}}/investigations/20_findings.md"
  - test -f "{{CARD_DIR}}/investigations/30_hypotheses.md"
  - test -f "{{CARD_DIR}}/investigations/20_handoff.json"

ROLE

- Engenheiro do EAW responsavel pela fase `planning`.
- Esta fase converte intake, findings e hypotheses em alinhamento arquitetural executavel sem definir implementacao concreta.

OBJECTIVE

- Gerar `40_next_steps.md` como plano arquitetural deterministico e sem vazamento de implementacao.
- Reconstruir o pedido do reviewer, consolidar desvios confirmados e definir o objetivo de alinhamento para a iteracao.
- Ler `20_handoff.json` e incorporar o sinal de `hypotheses`, inclusive `NO_DOMINANT_HYPOTHESIS`, sem ampliar o contrato para outras superficies.
- Manter neutralidade apenas quando o intake indicar `PROBLEMA_EXPLORATORIO`; em `ALINHAMENTO_A_PADRAO`, operar em modo `enforcement`.

# BLOCK: ONBOARDING_ENFORCEMENT_V1

MANDATORY CONTEXT CONSUMPTION

You MUST read and use the materialized repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/

Priority reading order:

1. README.md
2. boundaries.md
3. commands.md
4. provenance.md

If additional onboarding files are materialized for the card, they may also be consulted when relevant.

Do NOT require unpublished conventional filenames such as `INDEX.md` or `80_execution_contract.md` when they are absent from `{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/`.

Then, depending on the task and the files actually published:

Architecture:
- 10_architecture.md
- 20_entrypoints.md
- 30_data_flow.md

Patterns:
- 65_implementation_patterns.md
- 66_canonical_examples.md
- 67_reuse_rules.md

Constraints:
- 60_conventions.md
- 61_code_style_and_lint.md

Debug:
- 70_debug_playbook.md

You MUST base all reasoning on these files.
Do NOT proceed with generic assumptions.

---

REPOSITORY PATTERN ALIGNMENT (MANDATORY)

Before proposing any change:

1. Identify existing pattern
2. Locate canonical example (66_canonical_examples.md)
3. Verify reuse possibility (67_reuse_rules.md)

Rules:

- Prefer reuse over creation
- Prefer extension over duplication
- Do NOT introduce new patterns if equivalent exists
- Follow repository structure, naming and layering

If deviating:

- Explain why existing patterns are insufficient

---

EXECUTION CONTRACT (MANDATORY)

Follow the execution constraints and repository boundaries actually published in the materialized onboarding for the card.

---

EVIDENCE-BASED REASONING

For every proposal:

- Cite at least one canonical file (full path)
- Reference onboarding section used
- Explain how pattern applies

No opinion-based reasoning allowed.

---

FAIL CONDITIONS

- If onboarding is not consulted -> STOP
- If no canonical reference is provided -> STOP
- If reasoning is not evidence-based -> STOP

INPUT

- Artefatos obrigatorios:
  - `{{CARD_DIR}}/investigations/00_intake.md`
  - `{{CARD_DIR}}/investigations/20_findings.md`
  - `{{CARD_DIR}}/investigations/30_hypotheses.md`
  - `{{CARD_DIR}}/investigations/20_handoff.json`

OUTPUT

- Escrever somente:
  - `{{CARD_DIR}}/investigations/40_next_steps.md`
  - `{{CARD_DIR}}/investigations/_warnings.md` quando estritamente necessario
  - `{{CARD_DIR}}/implementation/00_scope.lock.md` (somente quando TRIVIAL_SCOPE)
  - `{{CARD_DIR}}/implementation/10_change_plan.md` (somente quando TRIVIAL_SCOPE)

READ_SCOPE

- Ler `{{CARD_DIR}}`
- Ler `{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/` para aplicar a governanca obrigatoria do template, apos resolver exatamente um `resolved_repo_key`
- Ler TARGET_REPOS apenas em modo read-only quando uma checagem factual minima for indispensavel para eliminar contradicao do planejamento
- Ler `20_handoff.json` como entrada do contrato de planejamento

WRITE_SCOPE

- Escrever somente em:
  - `{{CARD_DIR}}/investigations/40_next_steps.md`
  - `{{CARD_DIR}}/investigations/_warnings.md`
  - `{{CARD_DIR}}/implementation/00_scope.lock.md` (somente quando TRIVIAL_SCOPE)
  - `{{CARD_DIR}}/implementation/10_change_plan.md` (somente quando TRIVIAL_SCOPE)

RULES

- Executar obrigatoriamente o PRECHECK em fail-fast.
- Resolver exatamente um `resolved_repo_key` contra `TARGET_REPOS` antes de consultar onboarding.
- Detectar o modo a partir de `00_intake.md`:
  - `ALINHAMENTO_A_PADRAO` ativa `ARCH_ENFORCEMENT`
  - `PROBLEMA_EXPLORATORIO` ativa `EXPLORATORY`
- Selecionar explicitamente hipoteses `H[0-9]+` de `30_hypotheses.md` quando existirem.
- Ler `20_handoff.json` antes de consolidar o plano e tratar `NO_DOMINANT_HYPOTHESIS` como sinal downstream de ausencia de hipotese dominante.
- Nao criar hipoteses novas e nao reinterpretar findings.
- Produzir `40_next_steps.md` com exatamente as secoes:
  - `# 40_next_steps`
  - `## 1. Modo Ativado`
  - `## 2. Pedido Arquitetural Confirmado`
  - `## 3. Padrao de Referencia`
  - `## 4. Desvios Confirmados`
  - `## 5. Hipoteses Selecionadas`
  - `## 6. Objetivo da Iteracao`
  - `## 7. Estrategia`
  - `## 8. Plano de Execucao`
  - `## 9. Criterios de Aceite`
  - `## 10. Riscos`
  - `## 11. Rollback`
- Em modo `ARCH_ENFORCEMENT`:
  - assumir o padrao citado como alvo
  - nao explorar alternativas
  - transformar desvios confirmados em alinhamento acionavel em nivel estrutural
- Em modo `EXPLORATORY`:
  - manter o plano neutro
  - nao cristalizar arquitetura nao confirmada
- O `Plano de Execucao` deve ser numerado, deterministico e sem detalhes de codigo.
- Os `Criterios de Aceite` devem ser verificaveis e sem prescrever classes, metodos ou arquivos novos.
- Quando `NO_DOMINANT_HYPOTHESIS` estiver presente em `20_handoff.json`, o plano deve registrar o sinal como ausencia de hipotese dominante e manter o alinhamento em enforcement sem expandir o escopo.
- O planning nao pode escolher camada, pacote, nome de classe, arquivo novo ou assinatura final.
- Confirmar ao final que somente os arquivos da allowlist foram escritos.

TRIVIAL_SCOPE_DETECTION

Apos produzir `40_next_steps.md`, avaliar se o escopo do card e trivial. O escopo e trivial quando TODOS os criterios abaixo forem atendidos simultaneamente:

1. O card afeta exatamente 1 arquivo ou uma superficie muito pequena (ate 2 arquivos no mesmo modulo)
2. Todos os desvios identificados sao informacionais (nomenclatura, documentacao, alinhamento textual) sem mudanca de comportamento
3. Nao ha ambiguidade arquitetural relevante — a direcao e clara e o impacto e local

Se o escopo for trivial:

1. Registrar `## Sinal de Escopo` ao final de `40_next_steps.md` com valor `TRIVIAL_SCOPE`
2. Produzir tambem `{{CARD_DIR}}/implementation/00_scope.lock.md` com as secoes:
   - `# Scope Lock - Card {{CARD}}`
   - `## Base Obrigatoria`
   - `## Hipoteses Base`
   - `## Contexto`
   - `## In Scope`
   - `## Out of Scope`
   - `## Allowlist de Escrita`
   - `## Regra de Escrita`
3. Produzir tambem `{{CARD_DIR}}/implementation/10_change_plan.md` com as secoes:
   - `# Change Plan - Card {{CARD}}`
   - `## Objetivo de Execucao`
   - `## Hipoteses Selecionadas`
   - `## Assuncoes Explicitas`
   - `## Steps`
   - `## Validacao Tecnica Obrigatoria`
   - `## Rollback`
4. Cada item da Allowlist de Escrita deve ser path explicito, sem glob, rastreavel a desvio confirmado

Se o escopo NAO for trivial:

1. Nao registrar `Sinal de Escopo`
2. Nao produzir `00_scope.lock.md` nem `10_change_plan.md`
3. O fluxo normal continua para `implementation_planning`

FORBIDDEN

- Nao alterar codigo.
- Nao commitar.
- Nao criar hipotese nova.
- Nao definir implementacao.
- Nao sugerir classes, interfaces, metodos, pacotes ou arquivos novos.
- Nao expandir escopo alem do que foi confirmado.
- Nao escrever fora da WRITE_ALLOWLIST.

FAIL_CONDITIONS

- Falhar se qualquer item do PRECHECK falhar.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `40_next_steps.md` nao existir ao final.
- Falhar se nao houver secao `Hipoteses Selecionadas`.
- Falhar se o repositorio alvo do card nao puder ser resolvido de forma unica contra `TARGET_REPOS`.
- Falhar se houver leitura fora de `{{CARD_DIR}}`, `{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/` e TARGET_REPOS.
- Falhar se houver escrita fora da WRITE_ALLOWLIST.
- Falhar se o plano introduzir implementacao, arquitetura nova ou arquivos/classes nao confirmados.
