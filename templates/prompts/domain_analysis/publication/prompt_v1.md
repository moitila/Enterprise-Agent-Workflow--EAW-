{{RUNTIME_ENVIRONMENT}}

ROLE
- Solicitar e validar resultado externo de publicacao.

OBJECTIVE
- Emitir request restrito ao candidato aprovado e avancar somente com resultado correlacionado.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Quatro candidatos, candidate_validation.json, approval_request.json, approval_record.json, approval_validation.json, handoff de approval_gate e {{CARD_DIR}}/publication/publication_result.json quando injetado.

OUTPUT
- Escrever {{CARD_DIR}}/publication/publication_request.json, publication_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- publication_request.json: contract_version: 1, request id persistente, repo key, revisao-base, approved digest e quatro pares destino/hash.
- publication_validation.json: contract_version: 1, valid, errors, state waiting ou published; no sucesso, revisao publicada, destinos e published digest.
- 20_handoff.json: waiting com codes:["WAITING"] e blocker contendo request id/locator do result, ou completed com codes:[].

READ_SCOPE
- Ler artefatos de INPUT e {{CARD_DIR}}/publication/publication_request.json preexistente para preservar request id.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/publication/publication_request.json, {{CARD_DIR}}/publication/publication_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir handoff completed de approval_gate e approval_validation.json.valid:true; recalcular candidato e confirmar digest/autoridade/revisao-base.
- Restringir request aos quatro destinos docs/domain/domain-analysis.md, docs/domain/domain-glossary.yaml, docs/domain/domain-capabilities.yaml e docs/domain/domain-analysis.manifest.json.
- Sem result: valid:false, state:waiting, errors:[] e blocker concreto. Result presente divergente em request id, repo key, revisao, destinos ou digest falha fechado.
- Serializar handoff como JSON compacto de uma linha e gravar com `printf '%s' "$handoff_json" > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao publicar diretamente, criar/editar publication_result.json, escrever no repositorio ou aceitar destino extra.

FAIL_CONDITIONS
- Falhar se pre-check, revalidacao do candidato/aprovacao ou handoff falhar; se output estiver ausente/vazio; se result presente for invalido.
- Falhar se handoff nao for compacto em uma linha com codes e blocker em waiting.
