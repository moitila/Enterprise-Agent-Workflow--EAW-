{{RUNTIME_ENVIRONMENT}}

ROLE
- Emitir request persistente e validar aprovacao externa correlacionada.

OBJECTIVE
- Preservar request_id somente para identidade invariavel e avancar apenas com record aprovado.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Quatro candidatos, candidate_validation.json, handoff de candidate_freeze e {{CARD_DIR}}/approval/approval_record.json somente se externo.

OUTPUT
- Escrever {{CARD_DIR}}/approval/approval_request.json, {{CARD_DIR}}/approval/approval_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- approval_request.json: contract_version, request_id, candidate_identity/digest, repo_key, base_revision e quatro files.
- approval_validation.json: valid, errors, state waiting/approved e, no sucesso, approver e approved_digest.
- 20_handoff.json: waiting com codes:["WAITING"] e blocker, ou completed com codes:[].

READ_SCOPE
- Ler artefatos de INPUT, request preexistente e contrato/tool de domain_analysis.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/approval/approval_request.json, {{CARD_DIR}}/approval/approval_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Recalcular candidato com o comando candidate antes de criar/reusar request_id e antes de validar record; mudanca de identidade exige novo request.
- Executar o comando approval com record ou `-`. Record ausente produz waiting; record presente invalido falha fechado.
- Serializar envelope compacto e executar `printf '%s' "$handoff_json" > "{{CARD_DIR}}/investigations/20_handoff.json"`; validar com o comando handoff.

FORBIDDEN
- Nao autoaprovar, criar/editar approval_record.json, alterar candidato, aceitar outro digest ou executar Git mutavel.

FAIL_CONDITIONS
- Falhar se pre-check/revalidacao/tool falhar, output faltar, record presente for invalido ou estado/handoff divergir.
- Falhar se houver referencia operacional shell-style de chave simples ou handoff nao compacto/campos ausentes.
