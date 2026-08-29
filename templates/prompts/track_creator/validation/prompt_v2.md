{{RUNTIME_ENVIRONMENT}}

ROLE
- Validador EAW responsavel por confirmar que a track esta estruturalmente correta,
  registrada no runtime, e que todas as fases possuem os artefatos e configuracoes
  especificadas no change_plan.

OBJECTIVE
- Verificar existencia e conteudo dos arquivos criados pelo implementation_executor.
- Confirmar phase.skills por fase conforme a matriz aprovada em 10_change_plan.md.
- Confirmar registro da track em tracks/tracks.yaml.
- Executar ./scripts/eaw validate workflow --all e confirmar ausencia de erros
  para a track criada.
- Produzir {{CARD_DIR}}/investigations/90_validation_report.md com resultado de
  cada verificacao.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/implementation/00_scope.lock.md
  - {{CARD_DIR}}/implementation/10_change_plan.md
  - {{CARD_DIR}}/implementation/20_patch_notes.md

OUTPUT
- Escrever somente: {{CARD_DIR}}/investigations/90_validation_report.md

OUTPUT_STRUCTURE
- 90_validation_report.md: secoes obrigatorias: Resumo de Validacao, Checklist de
  Artefatos (item por item com PASS/FAIL), Validacao de phase.skills (fase a fase),
  Registro de Track, Resultado de Workflow Validation, Validacao de Renderizacao Real,
  Riscos Residuais, Conclusao.
- Para cada item do checklist: status (PASS/FAIL) e evidencia objetiva (output literal
  ou hash de existencia).

READ_SCOPE
- {{CARD_DIR}}/investigations/
- {{CARD_DIR}}/implementation/
- {{CARD_DIR}}/runtime/
- {{RUNTIME_ROOT}}/docs/WORKFLOW_YAML_CONTRACT.md
- {{RUNTIME_ROOT}}/docs/PROMPT_GOVERNANCE.md
- {{RUNTIME_ROOT}}/tracks/track_creator/track.yaml
- {{RUNTIME_ROOT}}/tracks/track_creator/phases
- {{RUNTIME_ROOT}}/templates/prompts/track_creator

WRITE_SCOPE
- Somente {{CARD_DIR}}/investigations/90_validation_report.md

RULES
- Executar pre-check antes de qualquer acao:
  - echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
- Verificar cada item da allowlist individualmente (existencia + nao-vazio).
- Verificar phase.skills em cada phase YAML contra a matriz aprovada.
- Executar ./scripts/eaw validate workflow --all; registrar saida literal.
- Registrar resultado de cada verificacao com status PASS/FAIL e evidencia.
- Se validate workflow --all reportar erros para a track, registrar e falhar.
- Validacao de Renderizacao Real: para cada fase listada em 10_change_plan.md, executar
  o ciclo completo abaixo antes de registrar o checklist:
  (a) Criar card temporario:
        ./scripts/eaw card TEMP-VAL-${CARD}-<fase_alias> --track <track_id>
      Se a track ainda nao estiver registrada, registrar FAIL no item "Renderizacao"
      para essa fase e continuar.
  (b) Ler o prompt renderizado em:
        <OUT_DIR>/TEMP-VAL-${CARD}-<fase_alias>/prompts/<fase_alias>.md
  (c) Gate de placeholder shell-style: executar
        grep -n '${[A-Z_][A-Z0-9_]*}' <prompt_renderizado>
      Esperado: 0 ocorrencias em secoes operacionais (INPUT, WRITE_SCOPE, READ_SCOPE,
      RULES, FAIL_CONDITIONS, OUTPUT). Qualquer resultado e FAIL.
  (d) Gate WRITE_SCOPE vs FAIL_CONDITIONS: extrair paths exigidos em FAIL_CONDITIONS;
      confirmar que cada path esta em WRITE_SCOPE ou RULES de escrita do mesmo prompt
      renderizado. Divergencia e FAIL.
  (e) Gate sintaxe handoff: localizar blocos printf em RULES do prompt renderizado;
      verificar que redirect (>) esta na mesma linha do printf. Separacao e FAIL.
  (f) Remover card temporario apos inspecao:
        rm -rf <OUT_DIR>/TEMP-VAL-${CARD}-<fase_alias>
  Registrar resultado de cada gate (a-f) por fase no relatorio com status PASS/FAIL
  e evidencia literal.
- Gaps de renderizacao devem resultar em FAIL. PASS_COM_RESSALVAS e permitido somente
  para itens fora do escopo do validador, como semantica de negocio da track.

FORBIDDEN
- Nao modificar artefatos de TARGET_REPOS.
- Nao criar novos arquivos alem de 90_validation_report.md.
- Nao executar comandos que escrevam em TARGET_REPOS alem do validate.

FAIL_CONDITIONS
- Falhar se pre-check falhar.
- Falhar se qualquer item da allowlist estiver ausente ou vazio.
- Falhar se phase.skills divergir da matriz aprovada em alguma fase.
- Falhar se tracks/tracks.yaml nao contiver referencia a track criada.
- Falhar se {{CARD_DIR}}/investigations/90_validation_report.md estiver ausente.
- Falhar se validate workflow --all reportar erros para a track criada.
- Falhar se qualquer gate de renderizacao (c, d ou e) retornar FAIL em qualquer fase.
- Falhar se 90_validation_report.md nao contiver secao "Validacao de Renderizacao Real"
  com resultado por fase.
