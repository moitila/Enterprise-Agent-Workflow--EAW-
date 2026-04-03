{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro do EAW responsavel pela fase de implementation planning do card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Converter o plano aprovado em `00_scope.lock.md` e `10_change_plan.md`.
- Nao alterar escopo, nao propor nova solucao e nao expandir arquitetura.

# ONBOARDING CONTEXT (MANDATORY)

Before creating the implementation plan, you MUST read the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/schematics-framework/

Priority order:

1. INDEX.md
2. 67_reuse_rules.md
3. 65_implementation_patterns.md
4. 66_canonical_examples.md
5. 70_debug_playbook.md
6. 75_rich_editor_and_ckeditor.md (if applicable)

Usage rules:

- Onboarding MUST guide file selection and implementation boundaries
- Onboarding MUST enforce reuse of existing components and logic
- Onboarding MUST prevent unnecessary changes outside the required scope
- If onboarding defines a pattern, it MUST be followed
- Allowlist MUST reflect minimal and correct modification points
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

OUTPUT
- Escrever somente:
  - `out/{{CARD}}/implementation/00_scope.lock.md`
  - `out/{{CARD}}/implementation/10_change_plan.md`

READ_SCOPE
- Ler somente:
  - `{{CARD_DIR}}`
  - `{{CARD_DIR}}/investigations`
  - `{{CARD_DIR}}/context`

WRITE_SCOPE
- Escrever somente:
  - `00_scope.lock.md`
  - `10_change_plan.md`

RULES

- Executar pre-check:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`

PASSO 1 - VALIDACAO

- Confirmar existencia de:
  - `00_intake.md`
  - `20_findings.md`
  - `30_hypotheses.md`
  - `40_next_steps.md`

- Bloquear se:
  - hipoteses nao existirem
  - plano nao referenciar H[0-9]+

PASSO 2 - DEFINICAO DE ARQUIVOS (COM ONBOARDING)

- Usar onboarding para:

  - identificar arquivos corretos para modificacao
  - evitar arquivos irrelevantes
  - validar se existe implementacao reutilizavel

- Regras:

  - cada arquivo deve estar ligado a:
    - findings (evidencia)
    - hypothesis (causa)
    - next_steps (acao)

  - nunca incluir arquivo fora do fluxo real do problema
  - evitar modificar multiplos modulos sem necessidade

PASSO 3 - GERAR 10_change_plan.md

- Cada Step deve conter:

  - objetivo
  - tipo
  - arquivos envolvidos
  - justificativa (ligada a H[0-9]+)
  - validacao tecnica

- Todos os Steps devem:

  - ser determinísticos
  - ser testáveis
  - ser mínimos

PASSO 4 - GERAR 00_scope.lock.md

- Definir:

  - escopo fechado
  - hipoteses base
  - contexto

- ALLOWLIST (CRITICO):

  - deve ser MINIMA
  - deve ser FECHADA
  - deve conter apenas arquivos realmente necessarios
  - deve seguir onboarding (padrao de implementacao)

- Regras da allowlist:

  - cada arquivo:
    - aparece em um Step
    - tem justificativa clara
  - sem glob
  - sem paths genericos
  - sem arquivos fora de TARGET_REPOS

PASSO 5 - VALIDACOES

- Confirmar:

  - coerencia:
    - findings → hypotheses → plan → files
  - aderencia ao onboarding
  - nenhuma expansao de escopo
  - rollback definido

VALIDACOES FINAIS

- Validar:

  - `test -f "out/{{CARD}}/implementation/00_scope.lock.md"`
  - `test -f "out/{{CARD}}/implementation/10_change_plan.md"`

- Confirmar:

  - sem placeholders
  - allowlist sem glob
  - todos arquivos da allowlist estão no plano
  - nenhum arquivo fora da allowlist

FORBIDDEN
- Nao alterar codigo
- Nao expandir escopo
- Nao propor nova arquitetura
- Nao ignorar onboarding quando houver padrao existente

FAIL_CONDITIONS
- Falhar se pre-check falhar
- Falhar se artefatos obrigatorios nao existirem
- Falhar se allowlist for inconsistente
- Falhar se houver escrita fora da whitelist