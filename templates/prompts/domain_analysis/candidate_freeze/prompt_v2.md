{{RUNTIME_ENVIRONMENT}}

ROLE
- Montar e congelar o pacote documental byte-exato para aprovacao.

OBJECTIVE
- Transportar conceitos validados e congelar exatamente quatro destinos, hashes e digest reproduzivel.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Todos os artefatos analysis, validations upstream/domain e handoff de capability_map.

OUTPUT
- Escrever {{CARD_DIR}}/candidate/domain-analysis.md, {{CARD_DIR}}/candidate/domain-glossary.yaml, {{CARD_DIR}}/candidate/domain-capabilities.yaml, {{CARD_DIR}}/candidate/domain-analysis.manifest.json, {{CARD_DIR}}/candidate/candidate_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Tres documentos de conteudo preservando IDs conceituais, source_id, certainty e qualification.
- domain-analysis.manifest.json: contract_version, repo_key, base_revision, upstream binding e quatro destinos/hashes, sem hash autorreferente.
- candidate_validation.json: contract_version: 1, repo_key, base_revision, files em ordem canonica, candidate_digest, valid e errors.
- 20_handoff.json: from_phase candidate_freeze, status completed, messages [], codes [].

READ_SCOPE
- Ler artefatos de INPUT, quatro candidatos durante validacao e {{RUNTIME_ROOT}}/tracks/domain_analysis/contracts/contract_v1.json.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/candidate/domain-analysis.md, {{CARD_DIR}}/candidate/domain-glossary.yaml, {{CARD_DIR}}/candidate/domain-capabilities.yaml, {{CARD_DIR}}/candidate/domain-analysis.manifest.json, {{CARD_DIR}}/candidate/candidate_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir upstream/domain valid:true e handoff completed. Preservar bindings e os quatro destinos exatos do contrato.
- Calcular SHA-256 lowercase dos bytes; agregar destinos lexicograficos como destination + NUL + hash + LF.
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/domain_analysis/tools/contract_tool.py" candidate "{{CARD_DIR}}/candidate/candidate_validation.json"` e exigir valid:true.
- Executar `printf '%s' '{"from_phase":"candidate_freeze","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"` e validar com o comando handoff.

FORBIDDEN
- Nao publicar, aprovar, adicionar destino, mudar binding, escrever no repositorio ou omitir classificacao conceitual validada.

FAIL_CONDITIONS
- Falhar se pre-check/input/tool falhar, se output faltar ou autoridade, revisao, destino, hash ou digest divergir.
- Falhar se houver referencia operacional shell-style de chave simples ou handoff nao compacto com codes:[].
