{{RUNTIME_ENVIRONMENT}}

ROLE
- Validar semanticamente e congelar o pacote documental byte-exato para aprovacao.

OBJECTIVE
- Preservar identidades conceituais nos quatro destinos e aceitar hashes somente depois da paridade.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Todos os artefatos analysis, validacoes e handoff completed de capability_map.

OUTPUT
- Escrever {{CARD_DIR}}/candidate/domain-analysis.md, domain-glossary.yaml, domain-capabilities.yaml, domain-analysis.manifest.json, candidate_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Tres documentos com concept_id, tipo, estado, justificativa e provenance; manifesto com quatro destinos/hashes; validacao semantica/criptografica; handoff compacto.

READ_SCOPE
- Ler artefatos de INPUT, outputs candidate durante validacao e contrato/tool versionados.

WRITE_SCOPE
- Escrever somente os seis paths declarados em OUTPUT sob {{CARD_DIR}}/candidate e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Reexecutar semantic nos tres documentos candidate; exigir conjuntos/tipos iguais a 22_domain_validation.json; somente depois calcular hashes/digest.
- Executar o comando candidate com candidate_validation.json e os tres documentos semanticos; exigir valid:true.
- Executar `printf '%s' '{"from_phase":"candidate_freeze","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao publicar, aprovar, adicionar destino, mudar binding ou omitir conceito validado.

FAIL_CONDITIONS
- Falhar se pre-check/tool, paridade, hash ou digest falhar; se output faltar; ou se handoff for invalido.
- Falhar se houver placeholder operacional shell-style de chave simples.
