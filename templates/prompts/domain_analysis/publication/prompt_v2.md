{{RUNTIME_ENVIRONMENT}}

ROLE
- Emitir request restrito e validar resultado externo de publicacao.

OBJECTIVE
- Revalidar candidato/aprovacao e aceitar somente resultado correlacionado aos quatro destinos.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Candidate e approval completos, handoff de approval_gate e {{CARD_DIR}}/publication/publication_result.json somente se externo.

OUTPUT
- Escrever {{CARD_DIR}}/publication/publication_request.json, {{CARD_DIR}}/publication/publication_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- publication_request.json: contract_version, request_id, repo_key, base_revision, approved_digest e quatro files.
- publication_validation.json: valid, errors, state waiting/published, revision, files e published_digest.
- 20_handoff.json: waiting com codes:["WAITING"] e blocker, ou completed com codes:[].

READ_SCOPE
- Ler artefatos de INPUT, request preexistente e contrato/tool de domain_analysis.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/publication/publication_request.json, {{CARD_DIR}}/publication/publication_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir predecessor completed e approval valid:true; reexecutar candidate e approval antes do request/result.
- Limitar files aos quatro destinos do contrato. Executar publication com result ou `-`; ausente produz waiting, presente invalido falha fechado.
- Serializar envelope compacto e executar `printf '%s' "$handoff_json" > "{{CARD_DIR}}/investigations/20_handoff.json"`; validar com o comando handoff.

FORBIDDEN
- Nao publicar, criar/editar publication_result.json, escrever no repositorio, adicionar destino ou aceitar outro candidato/aprovacao.

FAIL_CONDITIONS
- Falhar se pre-check/revalidacao/tool falhar, output faltar, result presente for invalido ou estado/handoff divergir.
- Falhar se houver referencia operacional shell-style de chave simples ou handoff nao compacto/campos ausentes.
