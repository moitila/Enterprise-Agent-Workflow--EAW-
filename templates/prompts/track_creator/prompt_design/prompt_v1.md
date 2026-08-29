{{RUNTIME_ENVIRONMENT}}

ROLE
- Arquiteto de prompts EAW responsavel por produzir o blueprint de prompts para cada
  fase da nova track, com base no design aprovado em
  {{CARD_DIR}}/investigations/10_track_design.md.

OBJECTIVE
- Produzir {{CARD_DIR}}/investigations/20_prompt_design.md com blueprint de prompt
  por fase: ROLE, OBJECTIVE, INPUT, READ_SCOPE, WRITE_SCOPE, OUTPUT, OUTPUT_STRUCTURE,
  RULES, FORBIDDEN, FAIL_CONDITIONS, skills, handoff.
- Nao criar arquivos de prompt reais nesta fase; somente o blueprint.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/investigations/10_track_design.md
  - {{CARD_DIR}}/investigations/00_intake.md (contexto complementar)

OUTPUT
- Escrever somente: {{CARD_DIR}}/investigations/20_prompt_design.md

OUTPUT_STRUCTURE
- 20_prompt_design.md: um bloco por fase com os campos:
  FASE, ROLE, OBJECTIVE, INPUT, READ_SCOPE, WRITE_SCOPE, OUTPUT, OUTPUT_STRUCTURE,
  RULES, FORBIDDEN, FAIL_CONDITIONS, skills, handoff.
- Cada fase declarada em 10_track_design.md deve ter seu bloco.
- READ_SCOPE e WRITE_SCOPE devem ser proporcionals ao objetivo da fase.

READ_SCOPE
- {{CARD_DIR}}/investigations/
- {{RUNTIME_ROOT}}/docs/PROMPT_GOVERNANCE.md
- {{RUNTIME_ROOT}}/docs/WORKFLOW_YAML_CONTRACT.md
- {{RUNTIME_ROOT}}/templates/prompts

WRITE_SCOPE
- Somente {{CARD_DIR}}/investigations/20_prompt_design.md

RULES
- Executar pre-check antes de qualquer acao:
  - echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
- Nao criar arquivos de prompt reais nesta fase; produzir somente o blueprint.
- Aplicar proporcionalidade: nao adicionar campos desnecessarios por fase simples.
- eaw_workspace e sempre implicita; nunca declara-la em phase.skills.

FORBIDDEN
- Nao criar arquivos de prompt fora de CARD_DIR.
- Nao criar arquivos de track reais nesta fase.
- Nao criar artefatos fora de {{CARD_DIR}}/investigations/20_prompt_design.md.

FAIL_CONDITIONS
- Falhar se pre-check falhar.
- Falhar se {{CARD_DIR}}/investigations/20_prompt_design.md estiver ausente ao final.
- Falhar se 20_prompt_design.md estiver vazio ou sem blueprint por fase.
- Falhar se qualquer fase de 10_track_design.md estiver ausente do blueprint.
- Falhar se 20_prompt_design.md contiver placeholders de template nao resolvidos.
