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
- EXCLUDED_REPOS:
{{EXCLUDED_REPOS}}
- WARNINGS:
{{WARNINGS_BLOCK}}
- REQUIRED_ARTIFACTS:
  - `{{CARD_DIR}}/investigations/00_intake.md`
  - `{{CARD_DIR}}/investigations/20_findings.md`
  - `{{CARD_DIR}}/investigations/30_hypotheses.md`
  - `{{CARD_DIR}}/investigations/40_next_steps.md`
- MODE: quando `EAW_WORKDIR` estiver vazio, saida em `OUT_DIR`; quando definido, saida isolada em `EAW_WORKDIR`.
- EXECUTION_STRUCTURE: `RUNTIME_ROOT` nunca deve ser modificado; `TARGET_REPOS` somente leitura; `CARD_DIR` e o limite unico de escrita da fase.

OUTPUT
- Escrever somente:
  - `out/{{CARD}}/implementation/00_scope.lock.md`
  - `out/{{CARD}}/implementation/10_change_plan.md`
- Confirmar arquivos criados, caminhos relativos, sucesso da escrita e que nenhum outro arquivo foi modificado.

OUTPUT_STRUCTURE
- `00_scope.lock.md` deve conter obrigatoriamente:
  - `# Scope Lock - Card {{CARD}}`
  - `## Base Obrigatoria`
  - `## Hipotese(s) Base`
  - `## Contexto`
  - `## In Scope`
  - `## Out of Scope`
  - `## Allowlist de Escrita`
  - `## Regra de Escrita`
- `10_change_plan.md` deve conter obrigatoriamente:
  - `# Change Plan - Card {{CARD}}`
  - `## Objetivo de Execucao`
  - `## Hipotese(s) Selecionada(s)`
  - `## Assuncoes Explicitas`
  - `## Steps`
  - `## Validacao Tecnica Obrigatoria`
  - `## Rollback`
- A allowlist de escrita deve ser fechada: paths absolutos, sem glob, sem alias.

READ_SCOPE
- Ler somente:
  - `{{CARD_DIR}}`
  - `{{CARD_DIR}}/investigations`
  - `{{CARD_DIR}}/context`
- Nao alterar codigo nesta fase.

WRITE_SCOPE
- Escrever somente:
  - `out/{{CARD}}/implementation/00_scope.lock.md`
  - `out/{{CARD}}/implementation/10_change_plan.md`
- A whitelist de escrita desta fase limita somente este agente de planning e nao define a allowlist soberana de implementacao.

RULES

- Executar pre-check em fail-fast:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`

- PASSO 1 - VALIDACAO DE ENTRADA:
  - Confirmar existencia dos artefatos obrigatorios; se qualquer um estiver ausente, bloquear.
  - Bloquear se `30_hypotheses.md` estiver ausente ou vazio.
  - Bloquear se `40_next_steps.md` estiver ausente ou vazio.
  - Bloquear se `40_next_steps.md` nao contiver referencia explicita a `H[0-9]+` ou nao indicar hipotese(s) selecionada(s).
  - Bloquear se houver inconsistencia entre hipoteses listadas e plano descrito.

- PASSO 2 - DEFINICAO DE ARQUIVOS (COM ONBOARDING):
  - Usar onboarding para:
    - identificar arquivos corretos para modificacao
    - evitar arquivos irrelevantes
    - validar se existe implementacao reutilizavel
    - restringir o escopo ao menor conjunto de alteracoes necessario
  - Regras:
    - cada arquivo deve estar ligado a:
      - findings (evidencia)
      - hypothesis (causa)
      - next_steps (acao)
    - para cada arquivo selecionado, identificar explicitamente:
      - caminho absoluto
      - funcao, metodo, bloco ou area alvo, quando aplicavel
      - Step correspondente em `40_next_steps.md`
      - hipotese(s) `H[0-9]+` que justificam a alteracao
    - nunca incluir arquivo fora do fluxo real do problema
    - evitar modificar multiplos modulos sem necessidade
    - bloquear qualquer arquivo sem rastreabilidade explicita para findings, hypotheses e next_steps

- PASSO 3 - GERAR 10_change_plan.md:
  - Incluir:
    - `# Change Plan - Card {{CARD}}`
    - `## Objetivo de Execucao`
    - `## Hipotese(s) Selecionada(s)`
    - `## Assuncoes Explicitas`
    - `## Steps`
    - `## Validacao Tecnica Obrigatoria`
    - `## Rollback`
  - Em cada Step numerado, incluir obrigatoriamente:
    - objetivo
    - tipo
    - arquivo(s) envolvidos com path absoluto
    - funcao, metodo, bloco ou area alvo, quando aplicavel
    - justificativa referenciando `40_next_steps.md`
    - hipotese(s) `H[0-9]+` cobertas
    - validacao tecnica obrigatoria
  - Todos os Steps devem:
    - ser deterministicos
    - ser testaveis
    - ser minimos
    - permitir validacao incremental e parcial quando aplicavel
  - Nenhum Step pode citar arquivo fora dos TARGET_REPOS.
  - Nenhum Step pode citar arquivo sem refletir exatamente o escopo do `40_next_steps.md`.

- PASSO 4 - GERAR 00_scope.lock.md:
  - Incluir:
    - `# Scope Lock - Card {{CARD}}`
    - `## Base Obrigatoria`
    - `## Hipotese(s) Base`
    - `## Contexto`
    - `## In Scope`
    - `## Out of Scope`
    - `## Allowlist de Escrita`
    - `## Regra de Escrita`
  - Preencher `## Allowlist de Escrita` com paths explicitos, fechados e sem glob dos arquivos reais em TARGET_REPOS autorizados para a implementacao.
  - Derivar a allowlist soberana exclusivamente de `40_next_steps.md` e dos `arquivo(s) envolvidos` definidos no `10_change_plan.md`.
  - A allowlist deve conter apenas o subconjunto minimo necessario de arquivos.
  - Nenhum path pode ser incluido na allowlist se nao estiver listado em `arquivo(s) envolvidos` no `10_change_plan.md`.
  - Cada path da allowlist deve:
    - aparecer explicitamente em pelo menos um Step do `10_change_plan.md`
    - corresponder a um unico arquivo real
    - ter justificativa rastreavel a `H[0-9]+`
  - Paths devem ser absolutos ou resolvidos dentro de TARGET_REPOS.
  - Nao permitir glob (`*`, `**`) na allowlist.
  - Nao incluir arquivos de `out/{{CARD}}/**` na allowlist soberana; estes artefatos pertencem apenas a fase planning.

- PASSO 5 - VALIDACOES:
  - Confirmar:
    - coerencia:
      - findings → hypotheses → plan → files
    - aderencia ao onboarding
    - nenhuma expansao de escopo
    - rollback definido
  - Confirmar que:
    - cada arquivo listado no `10_change_plan.md` aparece na allowlist
    - cada item da allowlist aparece em pelo menos um Step
    - nao existe arquivo sobrando no plan nem faltando na allowlist
    - nao existe ambiguidade entre Step, arquivo e alvo tecnico

- VALIDACOES FINAIS:
  - Garantir que os artefatos finais nao contenham placeholders literais de template como `<CARD>`, `{{CARD}}`, `{{TYPE}}`, `{{OUT_DIR}}` ou equivalentes.
  - Substituir referencias genericas ao diretorio do card pelo path concreto do card atual sempre que elas aparecerem no conteudo final.
  - Confirmar que `00_scope.lock.md` contem `Hipotese(s) Base`.
  - Confirmar que `10_change_plan.md` contem `Hipotese(s) Selecionada(s)`.
  - Confirmar que a allowlist e fechada sem glob.
  - Confirmar que cada item da allowlist aparece em `arquivo(s) envolvidos` do `10_change_plan.md`.
  - Confirmar que nenhum arquivo listado em `arquivo(s) envolvidos` do `10_change_plan.md` ficou fora da allowlist.
  - Confirmar que todos os arquivos da allowlist pertencem a TARGET_REPOS.
  - Confirmar que rollback esta presente.
  - Validar:
    - `rg -n '<CARD>|\\{\\{CARD\\}\\}|\\{\\{TYPE\\}\\}|\\{\\{OUT_DIR\\}\\}' "out/{{CARD}}/implementation/00_scope.lock.md" "out/{{CARD}}/implementation/10_change_plan.md"`
      - resultado esperado: vazio
    - `test -f "out/{{CARD}}/implementation/00_scope.lock.md"`
    - `test -f "out/{{CARD}}/implementation/10_change_plan.md"`

FORBIDDEN
- Nao alterar codigo.
- Nao expandir escopo.
- Nao propor nova solucao.
- Nao violar a fronteira operacional da fase (detalhada em FAIL_CONDITIONS).
- Nao produzir patch ou codigo nesta fase.
- Nao ignorar onboarding quando houver padrao existente.
- Nao incluir arquivo sem rastreabilidade explicita.
- Nao permitir ambiguidades entre Step, arquivo e alvo tecnico.

FAIL_CONDITIONS
- Falhar em qualquer erro de pre-check ou comando critico (fail-fast).
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `40_next_steps.md` nao referenciar hipoteses no formato `H[0-9]+`.
- Falhar se qualquer verificacao de consistencia entre allowlist e `arquivo(s) envolvidos` falhar.
- Falhar se houver arquivo sem funcao, metodo, bloco ou area alvo claramente identificada quando aplicavel.
- Falhar em qualquer tentativa de leitura fora de `{{CARD_DIR}}`, `{{CARD_DIR}}/investigations` e `{{CARD_DIR}}/context`.
- Falhar em qualquer tentativa de escrita fora de `out/{{CARD}}/implementation/00_scope.lock.md` e `out/{{CARD}}/implementation/10_change_plan.md`.
- Falhar se `out/{{CARD}}/implementation/00_scope.lock.md` nao existir ao final.
- Falhar se `out/{{CARD}}/implementation/10_change_plan.md` nao existir ao final.