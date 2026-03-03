ROLE
- Agente responsavel pela fase PLANNING do card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Gerar `40_next_steps.md` transformando hipoteses formais em plano executavel minimo.
- Nao criar hipotese nova, nao alterar findings e nao propor arquitetura nova.

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
- Escrever `{{CARD_DIR}}/investigations/_warnings.md` somente se necessario.
- Incluir hipoteses selecionadas H#, objetivo da iteracao, estrategia, plano atomico, criterios de aceite, riscos e mitigacao e rollback.

READ_SCOPE
- Ler `{{CARD_DIR}}`.
- Ler TARGET_REPOS somente em modo read-only quando estritamente necessario para checagens factuais.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/40_next_steps.md`.
- Escrever somente `{{CARD_DIR}}/investigations/_warnings.md` se necessario.

RULES
- Executar o pre-check: `cd "{{RUNTIME_ROOT}}"`, `test -f ./scripts/eaw` e `test -f "{{CONFIG_SOURCE}}"`.
- Confirmar existencia de `00_intake.md`, `20_findings.md` e `30_hypotheses.md`; se qualquer um estiver ausente, bloquear.
- Produzir `40_next_steps.md` com as secoes `# 40_next_steps`, `## Hipotese(s) Selecionada(s)`, `## Objetivo da Iteracao`, `## Estrategia`, `## Plano Atomico`, `## Criterios de Aceite`, `## Riscos e Mitigacao` e `## Rollback`.
- Em `Hipotese(s) Selecionada(s)`, listar explicitamente H# extraidas de `30_hypotheses.md`.
- Garantir que cada passo do plano atomico seja deterministico, executavel e reversivel quando aplicavel.
- Garantir que os criterios de aceite tenham comandos verificaveis, exit codes esperados, artefatos esperados e prefixos textuais quando aplicavel.
- Retornar lista de H# selecionadas, confirmacao de escrita unica e saida literal dos testes.

FORBIDDEN
- Nao alterar codigo.
- Nao commitar.
- Nao escrever fora da whitelist.
- Nao criar hipotese nova.
- Nao alterar findings.
- Nao propor arquitetura nova.

FAIL_CONDITIONS
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `40_next_steps.md` nao contiver secao `Hipotese(s) Selecionada(s)`.
- Falhar se nao houver pelo menos uma H# explicita.
- Falhar se o plano nao estiver numerado.
- Falhar se `{{CARD_DIR}}/investigations/40_next_steps.md` nao existir ao final.
