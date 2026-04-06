{{RUNTIME_ENVIRONMENT}}

ROLE
- Agente responsavel pela fase PLANNING do card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Gerar `40_next_steps.md` transformando hipoteses formais em plano executavel minimo.
- Nao criar hipotese nova, nao alterar findings e nao propor arquitetura nova.

# ONBOARDING CONTEXT (MANDATORY)

Before creating the plan, you MUST read the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/schematics-framework/

Priority order:

1. INDEX.md
2. 67_reuse_rules.md
3. 65_implementation_patterns.md
4. 66_canonical_examples.md
5. 70_debug_playbook.md
6. 75_rich_editor_and_ckeditor.md (if applicable)

Usage rules:

- Onboarding MUST guide implementation strategy
- Onboarding MUST enforce reuse of existing components and patterns
- Onboarding MUST prevent creation of new architecture when existing solutions exist
- Onboarding MUST be used to align the plan with framework conventions
- If onboarding defines a pattern, the plan MUST follow it
- Findings and hypotheses ALWAYS take precedence over onboarding assumptions

INPUT
- CARD={{CARD}}
- TYPE={{TYPE}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- TARGET_REPOS:
{{TARGET_REPOS}}
- EXCLUDED_REPOS:
{{EXCLUDED_REPOS}}
- WARNINGS:
{{WARNINGS_BLOCK}}
- REQUIRED_ARTIFACTS:
  - `{{CARD_DIR}}/investigations/00_intake.md`
  - `{{CARD_DIR}}/investigations/20_findings.md`
  - `{{CARD_DIR}}/investigations/30_hypotheses.md`

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/40_next_steps.md`.

OUTPUT_STRUCTURE
- `40_next_steps.md` deve conter obrigatoriamente:
  - `# 40_next_steps`
  - `## Hipotese(s) Selecionada(s)`
  - `## Objetivo da Iteracao`
  - `## Estrategia`
  - `## Plano Atomico`
  - `## Criterios de Aceite`
  - `## Riscos e Mitigacao`
  - `## Rollback`

READ_SCOPE
- Ler `{{CARD_DIR}}`
- Ler TARGET_REPOS somente em read-only quando necessario

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/40_next_steps.md`

RULES

- Executar pre-check:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`

- Confirmar existencia de:
  - `00_intake.md`
  - `20_findings.md`
  - `30_hypotheses.md`

PASSO 1 - SELECIONAR HIPOTESES

- Selecionar hipoteses `H[0-9]+` com base em:
  - ranking
  - impacto
  - cobertura do problema

PASSO 2 - DEFINIR ESTRATEGIA (COM ONBOARDING)

- Usar onboarding para:
  - identificar padroes existentes
  - identificar componentes reutilizaveis
  - evitar criacao de nova arquitetura
  - alinhar com comportamento esperado do framework

- Estrategia deve:
  - seguir padrao existente
  - ser minima (sem refatoracao desnecessaria)
  - respeitar fluxo real do sistema (ex: paste pipeline, editor, pagination)

PASSO 3 - PLANO ATOMICO

- Cada passo deve:
  - ser pequeno e executavel
  - ser verificavel
  - ser reversivel quando aplicavel

- Cada passo deve estar alinhado com:
  - findings (evidencia)
  - hypotheses (causa)
  - onboarding (padrao)

PASSO 4 - CRITERIOS DE ACEITE

- Definir:
  - comandos verificaveis
  - comportamento esperado
  - saida esperada
  - exit codes

PASSO 5 - RISCOS

- Identificar riscos:
  - quebra de comportamento existente
  - impacto em outros fluxos (ex: copy, pagination)
  - divergencia com CKEditor

PASSO 6 - ROLLBACK

- Definir rollback claro:
  - como desfazer
  - como validar reversao

VALIDACOES FINAIS

- Confirmar:
  - hipoteses listadas (H[0-9]+)
  - plano numerado
  - criterios verificaveis
  - aderencia ao onboarding
  - apenas `40_next_steps.md` foi escrito

FORBIDDEN
- Nao alterar codigo
- Nao commitar
- Nao criar hipotese nova
- Nao alterar findings
- Nao propor arquitetura nova
- Nao ignorar onboarding quando houver padrao existente

FAIL_CONDITIONS
- Falhar se pre-check falhar
- Falhar se artefatos obrigatorios nao existirem
- Falhar se nao houver hipotese selecionada
- Falhar se plano nao estiver numerado
- Falhar se houver escrita fora da whitelist