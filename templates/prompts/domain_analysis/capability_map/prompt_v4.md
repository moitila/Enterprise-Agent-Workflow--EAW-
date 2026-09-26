{{RUNTIME_ENVIRONMENT}}

ROLE
- Relacionar objetivos, atores e capabilities a evidências e conceitos, validando coverage separadamente da consistência semântica.

OBJECTIVE
- Produzir mapa rastreável e relatório determinístico no qual semantic e coverage sejam resultados independentes.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Artefatos source_inventory, source_discovery, domain_model e contrato/ferramenta versionados.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/20_capability_map.md, {{CARD_DIR}}/analysis/21_capabilities.yaml, {{CARD_DIR}}/analysis/22_domain_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Mapa e capabilities preservam schemas atuais; JSON inclui valid, semantic_validation, coverage_validation, erros ordenados e checks separados; handoff compacto.

READ_SCOPE
- Ler somente outputs anteriores e fontes manifestadas; {{RUNTIME_ROOT}}/tracks/domain_analysis/contracts/contract_v1.json e tools/contract_tool.py.

WRITE_SCOPE
- Escrever somente os quatro paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/domain_analysis/tools/contract_tool.py" semantic "{{CARD_DIR}}/analysis/10_domain_model.md" "{{CARD_DIR}}/analysis/11_domain_glossary.yaml" "{{CARD_DIR}}/analysis/21_capabilities.yaml"` e preservar o resultado integral.
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/domain_analysis/tools/contract_tool.py" coverage "{{CARD_DIR}}/analysis/03_candidate_coverage.yaml" "{{CARD_DIR}}/analysis/13_coverage_disposition.yaml" "{{CARD_DIR}}/analysis/10_domain_model.md" "{{CARD_DIR}}/analysis/11_domain_glossary.yaml"` e persistir separadamente. valid:true somente se ambos forem true.
- Handoff: `printf '%s' '{"from_phase":"capability_map","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Não alterar ferramenta/runtime nesta fase, ocultar checks, converter capabilities em arquitetura ou descartar candidatos para passar validação.

FAIL_CONDITIONS
- Falhar se contrato/ferramenta falhar, semantic ou coverage for inválido, resultado não estiver separado, output faltar ou handoff for inválido.
- Falhar se houver placeholder operacional shell-style de chave simples.
