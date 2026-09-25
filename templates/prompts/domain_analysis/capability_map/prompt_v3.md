{{RUNTIME_ENVIRONMENT}}

ROLE
- Relacionar capacidades a identidades conceituais e validar paridade global.

OBJECTIVE
- Produzir capacidades rastreaveis e validacao deterministica valid:true antes do freeze.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Artefatos de source_inventory/domain_model e contrato/tool versionados.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/20_capability_map.md, {{CARD_DIR}}/analysis/21_capabilities.yaml, {{CARD_DIR}}/analysis/22_domain_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Mapa narrativo; YAML com concept_ids e applicable_concept_ids; JSON com valid, errors ordenados, checks booleanos e conjuntos normalizados; handoff compacto.

READ_SCOPE
- Ler somente artefatos de INPUT e fontes manifestadas necessarias.

WRITE_SCOPE
- Escrever somente os quatro paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/domain_analysis/tools/contract_tool.py" semantic "{{CARD_DIR}}/analysis/10_domain_model.md" "{{CARD_DIR}}/analysis/11_domain_glossary.yaml" "{{CARD_DIR}}/analysis/21_capabilities.yaml"` e persistir exatamente o JSON em 22_domain_validation.json.
- Exigir valid:true, paridade de IDs/tipos, referencias validas, cobertura aplicavel e qualificacao.
- Executar `printf '%s' '{"from_phase":"capability_map","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao converter capacidades em arquitetura tecnica nem ocultar erro ou conflito.

FAIL_CONDITIONS
- Falhar se pre-check/tool falhar, valid nao for true, output faltar ou handoff for invalido.
- Falhar se houver placeholder operacional shell-style de chave simples.
