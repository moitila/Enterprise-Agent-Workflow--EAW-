{{RUNTIME_ENVIRONMENT}}

ROLE
- Montar e validar o pacote documental byte-exato para aprovacao.

OBJECTIVE
- Congelar quatro candidatos, autoridade, revisao-base e digest agregado reproduzivel.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Todos os artefatos analysis/ das tres fases anteriores, 02_upstream_validation.json, 22_domain_validation.json e handoff de capability_map.

OUTPUT
- Escrever {{CARD_DIR}}/candidate/domain-analysis.md, domain-glossary.yaml, domain-capabilities.yaml, domain-analysis.manifest.json, candidate_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- domain-analysis.md: conceitos, atores, relacoes, objetivos, capacidades, limites, divergencias e questoes com proveniencia.
- domain-glossary.yaml: glossario canonico derivado de 11_domain_glossary.yaml, com IDs e source_id.
- domain-capabilities.yaml: capacidades canonicas derivadas de 21_capabilities.yaml, com objetivos, atores, conceitos e source_id.
- domain-analysis.manifest.json: contract_version: 1, autoridade, revisao-base, digest upstream, source_id e quatro destinos; hashes dos tres documentos de conteudo, sem hash autorreferente.
- candidate_validation.json: contract_version: 1, valid, errors, repo key, revisao-base, quatro pares destino/hash e candidate_digest.
- 20_handoff.json: from_phase candidate_freeze, status completed, messages [], codes [].

READ_SCOPE
- Ler artefatos de INPUT, quatro candidatos durante validacao e metadados read-only da autoridade na revisao-base vinculada.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/candidate/domain-analysis.md, {{CARD_DIR}}/candidate/domain-glossary.yaml, {{CARD_DIR}}/candidate/domain-capabilities.yaml, {{CARD_DIR}}/candidate/domain-analysis.manifest.json, {{CARD_DIR}}/candidate/candidate_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir valid:true em upstream e domain validation, mais handoff completed de capability_map; preservar autoridade/revisao-base vinculadas.
- Destinos exatos: docs/domain/domain-analysis.md, docs/domain/domain-glossary.yaml, docs/domain/domain-capabilities.yaml, docs/domain/domain-analysis.manifest.json.
- Calcular SHA-256 lowercase dos bytes finais de cada candidato. Para destinos em ordem lexicografica, concatenar destination + NUL + hash lowercase + LF e calcular SHA-256 desse fluxo. Recalcular e comparar com candidate_validation.json antes do handoff.
- Qualquer mudanca posterior nos quatro bytes invalida a identidade e requer nova aprovacao.
- Apos valid:true, executar `printf '%s' '{"from_phase":"candidate_freeze","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao publicar, solicitar aprovacao antes da validacao, escrever no repositorio de autoridade, adicionar destinos ou mudar o binding upstream.

FAIL_CONDITIONS
- Falhar se pre-check, validacoes de entrada ou handoff falhar; se output estiver ausente/vazio; se autoridade, revisao, destino, hash ou digest divergir.
- Falhar se handoff nao for compacto em uma linha com codes:[].
