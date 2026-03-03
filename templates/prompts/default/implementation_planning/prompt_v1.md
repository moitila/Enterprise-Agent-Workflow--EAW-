ROLE
- Engenheiro do EAW responsavel pela fase de implementation planning do card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Converter o plano aprovado em `00_scope.lock.md` e `10_change_plan.md`.
- Nao alterar escopo, nao propor nova solucao e nao expandir arquitetura.

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
  - `out/{{CARD}}/investigations/00_intake.md`
  - `out/{{CARD}}/investigations/20_findings.md`
  - `out/{{CARD}}/investigations/30_hypotheses.md`
  - `out/{{CARD}}/investigations/40_next_steps.md`
  - `out/{{CARD}}/context/**`

OUTPUT
- Escrever somente `out/{{CARD}}/implementation/00_scope.lock.md`.
- Escrever somente `out/{{CARD}}/implementation/10_change_plan.md`.
- Confirmar arquivos criados, caminhos relativos, sucesso da escrita e que nenhum outro arquivo foi modificado.

READ_SCOPE
- Ler somente `{{CARD_DIR}}`, `{{CARD_DIR}}/investigations` e `{{CARD_DIR}}/context`.
- Nao alterar codigo nesta fase.

WRITE_SCOPE
- Escrever somente `out/{{CARD}}/implementation/00_scope.lock.md`.
- Escrever somente `out/{{CARD}}/implementation/10_change_plan.md`.

RULES
- Executar o pre-check: `cd "{{RUNTIME_ROOT}}"`, `test -f ./scripts/eaw` e `test -f "{{CONFIG_SOURCE}}"`.
- Confirmar existencia dos artefatos obrigatorios; se qualquer um estiver ausente, bloquear.
- Bloquear se `30_hypotheses.md` estiver ausente ou vazio.
- Bloquear se `40_next_steps.md` estiver ausente ou vazio.
- Bloquear se `40_next_steps.md` nao contiver referencia explicita a H# ou nao indicar hipotese(s) selecionada(s).
- Bloquear se houver inconsistencia entre hipoteses listadas e plano descrito.
- Em `00_scope.lock.md`, incluir `# Scope Lock - Card {{CARD}}`, `## Base Obrigatoria`, `## Hipotese(s) Base`, `## Contexto`, `## In Scope`, `## Out of Scope`, `## Allowlist de Escrita` e `## Regra de Escrita`.
- Em `10_change_plan.md`, incluir `# Change Plan - Card {{CARD}}`, `## Objetivo de Execucao`, `## Hipotese(s) Selecionada(s)`, `## Assuncoes Explicitas`, `## Steps`, `## Validacao Tecnica Obrigatoria` e `## Rollback`.
- Em cada Step numerado, incluir objetivo, tipo, arquivos envolvidos, justificativa referenciando `40_next_steps.md` e H#, e validacao tecnica obrigatoria.
- Validar ao final que `00_scope.lock.md` contem `Hipotese(s) Base`, que `10_change_plan.md` contem `Hipotese(s) Selecionada(s)`, que a allowlist e fechada sem glob e que rollback esta presente.

FORBIDDEN
- Nao alterar codigo.
- Nao expandir escopo.
- Nao propor nova solucao.
- Nao escrever fora de `out/{{CARD}}/implementation/00_scope.lock.md` e `out/{{CARD}}/implementation/10_change_plan.md`.
- Nao produzir patch ou codigo nesta fase.

FAIL_CONDITIONS
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `40_next_steps.md` nao referenciar H#.
- Falhar se `out/{{CARD}}/implementation/00_scope.lock.md` nao existir ao final.
- Falhar se `out/{{CARD}}/implementation/10_change_plan.md` nao existir ao final.
