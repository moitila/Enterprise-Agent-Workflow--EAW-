{{RUNTIME_ENVIRONMENT}}

ROLE
- Revalidar e congelar o pacote documental e coverage byte-exato para aprovação.

OBJECTIVE
- Preservar identidades semânticas, reconciliar o ledger e congelar cinco destinos com hashes/digest reproduzíveis.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Artefatos analysis, semantic_validation e coverage_validation válidos, handoff completed de capability_map e contrato versionado.

OUTPUT
- Escrever {{CARD_DIR}}/candidate/domain-analysis.md, {{CARD_DIR}}/candidate/domain-glossary.yaml, {{CARD_DIR}}/candidate/domain-capabilities.yaml, {{CARD_DIR}}/candidate/domain-analysis-coverage.yaml, {{CARD_DIR}}/candidate/domain-analysis.manifest.json, {{CARD_DIR}}/candidate/candidate_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Quatro documentos: modelo, glossário, capabilities e snapshot coverage ordenado por candidate_id sem perda de evidência/disposição/upstream status.
- Manifest lista os cinco destinos permanentes e hashes; digest SHA-256 conforme contrato; validation separa semantic e coverage; handoff compacto.

READ_SCOPE
- Ler todos os artefatos de INPUT, outputs candidate e {{RUNTIME_ROOT}}/tracks/domain_analysis/contracts/contract_v1.json e tools/contract_tool.py.

WRITE_SCOPE
- Escrever somente sete outputs declarados.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Reexecutar semantic e coverage; preservar os conjuntos completos de IDs e tipos e estados. Comparar snapshot ao ledger/dispositions normalizados antes de calcular os cinco hashes/digest.
- Handoff: `printf '%s' '{"from_phase":"candidate_freeze","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Não publicar, aprovar, adicionar destinos, mudar binding/autoridade/estado/identidade ou omitir candidato validado.

FAIL_CONDITIONS
- Falhar se semantic/coverage, paridade, hash/digest ou handoff falhar; se algum dos sete outputs faltar; ou se snapshot diferir do conjunto descoberto.
- Falhar se houver placeholder operacional shell-style de chave simples.
