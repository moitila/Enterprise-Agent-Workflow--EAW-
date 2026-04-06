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
- MODE: quando `EAW_WORKDIR` estiver vazio, saida em `OUT_DIR`; quando definido, saida isolada em `EAW_WORKDIR`.
- EXECUTION_STRUCTURE: `RUNTIME_ROOT` nunca deve ser modificado; `TARGET_REPOS` somente leitura; `CARD_DIR` e o limite unico de escrita da fase.

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/40_next_steps.md`.
- Escrever `{{CARD_DIR}}/investigations/_warnings.md` somente se necessario.
- Incluir hipoteses selecionadas no formato `H[0-9]+`, objetivo da iteracao, estrategia, plano atomico, criterios de aceite, riscos, mitigacao e rollback.

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
- Cada hipotese selecionada deve estar identificada no formato `H[0-9]+`.
- Criterios de aceite devem conter comandos verificaveis com exit codes esperados.

READ_SCOPE
- Ler `{{CARD_DIR}}`.
- Ler TARGET_REPOS somente em modo read-only quando estritamente necessario para checagens factuais.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/40_next_steps.md`.
- Escrever somente `{{CARD_DIR}}/investigations/_warnings.md` se necessario.

RULES
- Executar pre-check em fail-fast:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`
- Confirmar existencia de `00_intake.md`, `20_findings.md` e `30_hypotheses.md`; se qualquer um estiver ausente, bloquear.

- PASSO 1 - SELECIONAR HIPOTESES:
  - Em `## Hipotese(s) Selecionada(s)`, listar explicitamente identificadores `H[0-9]+` extraidos de `30_hypotheses.md`.
  - Selecionar somente as hipoteses necessarias para uma iteracao minima, coerente e executavel.
  - Nao selecionar hipoteses sem cobertura nos findings ou sem relacao direta com o objetivo da iteracao.

- PASSO 2 - DEFINIR ESTRATEGIA (COM ONBOARDING):
  - Usar onboarding para:
    - identificar padroes existentes
    - identificar componentes reutilizaveis
    - evitar criacao de nova arquitetura
    - alinhar com comportamento esperado do framework
  - A estrategia deve:
    - seguir padrao existente
    - ser minima (sem refatoracao desnecessaria)
    - respeitar o fluxo real do sistema
    - ser coerente com findings, hypotheses e onboarding

- PASSO 3 - PLANO ATOMICO:
  - Garantir que cada passo do plano atomico seja deterministico, executavel e reversivel quando aplicavel.
  - O plano deve ser numerado.
  - Cada passo deve conter, quando aplicavel:
    - objetivo
    - alvo tecnico
    - justificativa ligada a `H[0-9]+`
    - validacao tecnica obrigatoria
  - Se as hipoteses selecionadas incluirem cenarios de debugging, falhas de runtime ou mudancas estruturais, garantir que o plano atomico cubra esses cenarios de forma verificavel.
  - Cada passo deve estar alinhado com:
    - findings (evidencia)
    - hypotheses (causa)
    - onboarding (padrao)

- PASSO 4 - CRITERIOS DE ACEITE:
  - Garantir que os criterios de aceite tenham comandos verificaveis, exit codes esperados, artefatos esperados e prefixos textuais quando aplicavel.
  - Os criterios devem validar exatamente os efeitos previstos no plano atomico.
  - Nao usar criterios subjetivos.

- PASSO 5 - RISCOS E MITIGACAO:
  - Identificar riscos de:
    - quebra de comportamento existente
    - impacto em outros fluxos relacionados
    - divergencia com padroes do framework
  - Para cada risco relevante, registrar mitigacao objetiva.

- PASSO 6 - ROLLBACK:
  - Definir rollback claro, objetivo e verificavel.
  - O rollback deve permitir reversao da iteracao planejada sem expandir escopo.

- VALIDACOES FINAIS:
  - Confirmar secao `Hipotese(s) Selecionada(s)`.
  - Confirmar pelo menos uma hipotese explicita no formato `H[0-9]+`.
  - Confirmar plano numerado.
  - Confirmar criterios verificaveis.
  - Confirmar aderencia ao onboarding.
  - Validar `test -f "{{CARD_DIR}}/investigations/40_next_steps.md"`.
  - Confirmar escrita apenas na whitelist da fase.
  - Retornar lista de hipoteses `H[0-9]+` selecionadas, confirmacao de escrita unica e saida literal dos testes executados.

FORBIDDEN
- Nao alterar codigo.
- Nao commitar.
- Nao violar a fronteira operacional da fase (detalhada em FAIL_CONDITIONS).
- Nao criar hipotese nova.
- Nao alterar findings.
- Nao propor arquitetura nova.
- Nao ignorar onboarding quando houver padrao existente.
- Nao transformar o prompt em plano preenchido de um card especifico.

FAIL_CONDITIONS
- Falhar em qualquer erro de pre-check ou comando critico (fail-fast).
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `40_next_steps.md` nao contiver secao `Hipotese(s) Selecionada(s)`.
- Falhar se nao houver pelo menos uma hipotese explicita no formato `H[0-9]+`.
- Falhar se o plano nao estiver numerado.
- Falhar em qualquer tentativa de leitura fora de `{{CARD_DIR}}` e TARGET_REPOS.
- Falhar em qualquer tentativa de escrita fora da whitelist (`{{CARD_DIR}}/investigations/40_next_steps.md` e `{{CARD_DIR}}/investigations/_warnings.md`).
- Falhar se `{{CARD_DIR}}/investigations/40_next_steps.md` nao existir ao final.