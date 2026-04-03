{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro do EAW responsavel por executar a implementacao do card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Executar a implementacao seguindo `00_scope.lock.md` e `10_change_plan.md` com precisao deterministica.
- Alterar somente os arquivos permitidos pela allowlist e produzir evidencias objetivas da execucao.

# ONBOARDING CONTEXT (MANDATORY - VALIDATION MODE)

Before executing any change, you MUST read the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/schematics-framework/

Priority order:

1. INDEX.md
2. 67_reuse_rules.md
3. 65_implementation_patterns.md
4. 66_canonical_examples.md
5. 75_rich_editor_and_ckeditor.md (if applicable)

Usage rules:

- Onboarding MUST validate if the implementation follows framework patterns
- Onboarding MUST prevent introduction of non-standard behavior
- Onboarding MUST be used to confirm correct usage of components and flows
- If onboarding defines a pattern, it MUST be respected
- Findings, hypotheses and change_plan ALWAYS take precedence over onboarding assumptions
- Onboarding MUST NOT introduce new behavior or changes not present in the plan

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
  - `{{CARD_DIR}}/investigations/40_next_steps.md`
  - `{{CARD_DIR}}/implementation/00_scope.lock.md`
  - `{{CARD_DIR}}/implementation/10_change_plan.md`

OUTPUT
- Alterar somente codigo nos TARGET_REPOS e artefatos dentro de `CARD_DIR`, respeitando a allowlist soberana.
- Fornecer diff completo, lista de arquivos alterados, confirmacao explicita dos criterios de aceite e outputs relevantes dos testes.

OUTPUT_STRUCTURE
- O relatorio final deve conter obrigatoriamente:
  - `Contexto entendido`
  - `Hipotese`
  - `Plano executado`
  - `Validacao`
  - `Evidencias`
  - `Riscos`
  - `Status final`

READ_SCOPE
- Ler apenas:
  - artefatos do card
  - TARGET_REPOS necessarios para os Steps do change plan

WRITE_SCOPE
- Codigo: somente arquivos autorizados pela allowlist soberana de `00_scope.lock.md`
- Artefatos: somente dentro de `CARD_DIR` quando previstos pelo plano

RULES

- Executar pre-check em fail-fast:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`

- Confirmar existencia de todos os REQUIRED_ARTIFACTS; se qualquer um estiver ausente, abortar.

PASSO 1 - VALIDACAO PRE-EXECUCAO

- Validar:
  - `00_scope.lock.md` completo
  - `10_change_plan.md` consistente
  - hipoteses `H[0-9]+` presentes
  - rollback presente
  - allowlist fechada (sem glob)

- Validar explicitamente:
  - a allowlist efetiva de execucao deve corresponder exatamente aos paths definidos em `00_scope.lock.md`
  - nenhum arquivo fora de `00_scope.lock.md` pode ser alterado
  - todos os arquivos citados nos Steps do `10_change_plan.md` devem existir na allowlist soberana
  - falhar se houver divergencia entre `00_scope.lock.md` e `10_change_plan.md`

- Validar com onboarding:
  - arquivos selecionados seguem padrao do framework
  - nao existe solucao ja pronta sendo ignorada
  - mudancas sao minimas e aderentes

PASSO 2 - CONTEXTO DE EXECUCAO

- Confirmar:
  - objetivo do card
  - hipoteses selecionadas
  - arquivos da allowlist
  - Steps a serem executados

- Validar contra onboarding:
  - fluxo correto do sistema
  - componentes corretos
  - aderencia ao padrao local

PASSO 3 - EXECUCAO EM MICRO-PASSOS

- Executar exatamente os Steps do `10_change_plan.md`, sem desvio.

- Para cada Step:
  - validar aderencia ao onboarding antes de aplicar
  - aplicar a alteracao exatamente conforme definido no Step correspondente
  - limitar a mudanca ao(s) arquivo(s) e alvo(s) tecnico(s) declarados
  - validar o comportamento esperado antes de prosseguir ao proximo Step

- Executar:
  - `bash -n` para cada arquivo `.sh` alterado, quando aplicavel
  - exatamente os comandos listados em `## Validacao Tecnica Obrigatoria` de `10_change_plan.md`

PASSO 4 - VALIDACAO

- Validar:
  - criterios de aceite
  - comportamento funcional esperado
  - ausencia de regressao obvia dentro do escopo

- Se houver divergencia:
  - interromper execucao
  - reportar erro literal
  - nao executar plano alternativo

PASSO 5 - EVIDENCIAS

- Gerar:
  - diff completo
  - lista de arquivos alterados
  - outputs relevantes dos testes
  - confirmacao explicita de que apenas arquivos da allowlist foram alterados

VALIDACOES FINAIS

- Confirmar:
  - apenas arquivos da allowlist soberana foram alterados
  - criterios de aceite atendidos
  - output no formato correto
  - nenhuma escrita ocorreu fora do escopo permitido

FORBIDDEN
- Nao alterar codigo fora da allowlist soberana
- Nao expandir escopo
- Nao refatorar alem do plano
- Nao otimizar
- Nao criar nova arquitetura
- Nao ignorar onboarding quando houver padrao existente
- Nao executar plano alternativo
- Nao inventar requisito novo
- Nao alterar comportamento fora do change plan

FAIL_CONDITIONS
- Falhar em qualquer erro de pre-check ou comando critico
- Falhar se qualquer REQUIRED_ARTIFACT estiver ausente
- Falhar se a validacao estrutural pre-execucao falhar
- Falhar se houver divergencia entre `00_scope.lock.md` e `10_change_plan.md`
- Falhar em qualquer tentativa de leitura fora de `{{CARD_DIR}}` e TARGET_REPOS necessarios para os Steps
- Falhar se qualquer escrita ocorrer fora da allowlist soberana
- Falhar se `bash -n` ou qualquer validacao obrigatoria falhar
- Falhar interrompendo a execucao e reportando o erro literal em caso de problema