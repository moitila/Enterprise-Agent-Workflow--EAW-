{{RUNTIME_ENVIRONMENT}}

ROLE
- Mapear objetivos, atores e capacidades em nivel conceitual.

OBJECTIVE
- Relacionar capacidades ao modelo, fontes e IDs conceituais aplicaveis com integridade verificavel.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Artefatos de domain_model, source manifest, upstream validation e handoff de domain_model.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/20_capability_map.md, {{CARD_DIR}}/analysis/21_capabilities.yaml, {{CARD_DIR}}/analysis/22_domain_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- 20_capability_map.md: objetivos, atores, capacidades, interacoes e referencias conceituais aplicaveis.
- 21_capabilities.yaml: contract_version: 1; IDs de capacidades, atores, source_id, certainty e concept_ids.
- 22_domain_validation.json: valid, errors, IDs unicos, referencias existentes e rastreabilidade.
- 20_handoff.json: from_phase capability_map, status completed, messages [], codes [].

READ_SCOPE
- Ler artefatos de INPUT e fontes manifestadas necessarias para confirmar cada capacidade.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/analysis/20_capability_map.md, {{CARD_DIR}}/analysis/21_capabilities.yaml, {{CARD_DIR}}/analysis/22_domain_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir handoff completed. Validar YAML/JSON por parser, IDs unicos e cada concept_id contra o glossario.
- Referenciar somente classificacoes aplicaveis; preservar lacunas, conflitos e qualification.
- Apos valid:true, executar `printf '%s' '{"from_phase":"capability_map","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao converter capacidades em servicos, endpoints, tabelas, componentes ou desenho tecnico; nao ocultar conflito.

FAIL_CONDITIONS
- Falhar se pre-check/handoff/parsing falhar, valid nao for true, ID duplicar, referencia/provenance faltar ou output estiver vazio.
- Falhar se houver referencia operacional shell-style de chave simples ou handoff nao compacto com codes:[].
