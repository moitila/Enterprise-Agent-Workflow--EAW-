{{RUNTIME_ENVIRONMENT}}

ROLE
- Mapear objetivos, atores, capacidades e interacoes entre limites em nivel conceitual.

OBJECTIVE
- Ligar cada capacidade ao modelo e as fontes com validacao de rastreabilidade.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Artefatos de domain_model, 00_source_manifest.yaml, 02_upstream_validation.json e handoff de domain_model.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/20_capability_map.md, 21_capabilities.yaml, 22_domain_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- 20_capability_map.md: objetivos, atores, capacidades e interacoes conceituais, com IDs, conflitos e questoes abertas.
- 21_capabilities.yaml: contract_version: 1; IDs estaveis de objetivos/capacidades, atores, conceitos, source_id e certeza.
- 22_domain_validation.json: contract_version: 1, valid, errors, IDs unicos, referencias existentes e rastreabilidade.
- 20_handoff.json: from_phase capability_map, status completed, messages [], codes [] somente com valid:true.

READ_SCOPE
- Ler artefatos de INPUT e fontes identificadas no manifesto quando necessarias a confirmar objetivo ou capacidade.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/analysis/20_capability_map.md, {{CARD_DIR}}/analysis/21_capabilities.yaml, {{CARD_DIR}}/analysis/22_domain_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir handoff completed de domain_model; validar IDs e referencias contra glossario, manifesto e baseline por parser YAML/JSON.
- Preservar perguntas abertas; referencia ou proveniencia invalida produz 22_domain_validation.json.valid:false e bloqueia sucesso.
- Apos valid:true, executar `printf '%s' '{"from_phase":"capability_map","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao transformar capacidades em regras detalhadas, modelo de dados ou desenho tecnico; nao ocultar conflito.

FAIL_CONDITIONS
- Falhar se pre-check/handoff falhar, output estiver ausente/vazio, valid nao for true, ID duplicar ou referencia faltar.
- Falhar se handoff de sucesso nao for compacto em uma linha com codes:[].
