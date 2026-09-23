{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de decisao `authority_resolution`, resolvendo uma autoridade explicita ou aguardando bootstrap/decisao externa correlacionada.

OBJECTIVE
- Resolver exatamente um binding de autoridade com repo key, raiz de publicacao e fonte explicita.
- Quando a evidencia externa necessaria estiver ausente, emitir request persistente e handoff waiting sem fabricar resultado.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: outputs de topologia, `{{CARD_DIR}}/analysis/22_topology_validation.json` e handoff completed de `repository_topology`.
- Entrada externa opcional e reservada: `{{CARD_DIR}}/analysis/32_bootstrap_result.json`, somente se ja tiver sido injetada.

OUTPUT
- Escrever `{{CARD_DIR}}/analysis/30_authority_resolution.yaml`.
- Escrever `{{CARD_DIR}}/analysis/31_bootstrap_request.json`.
- Escrever `{{CARD_DIR}}/analysis/33_authority_validation.json`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.
- Nao escrever `{{CARD_DIR}}/analysis/32_bootstrap_result.json`; esse resultado e externo.

OUTPUT_STRUCTURE
- `30_authority_resolution.yaml`: JSON compativel com YAML; em resolved contem `contract_version: 1`, `state: resolved` e um unico `binding` com `repo_key`, `publication_root`, `source`; em waiting contem binding nulo e request id nao vazio.
- `31_bootstrap_request.json`: request id persistente, cenario, necessidade, destinos permitidos e correlacao; quando bootstrap nao for necessario, registrar estado `not_required` sem alegar execucao.
- `33_authority_validation.json`: receipt do validador com `contract_version: 1`, `valid` booleano e `errors`; waiting usa `valid: false`, `state: waiting`, `errors: []`.
- `20_handoff.json`: envelope compacto completed/codes vazio ou waiting/codes WAITING.

READ_SCOPE
- Ler os REQUIRED_ARTIFACTS, `{{CONFIG_SOURCE}}` e TARGET_REPOSITORIES declarados.
- Ler `{{CARD_DIR}}/analysis/32_bootstrap_result.json` somente se existir.
- Ler o contrato e a ferramenta sob `{{RUNTIME_ROOT}}/tracks/system_analysis/`.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/analysis/30_authority_resolution.yaml`.
- Escrever somente `{{CARD_DIR}}/analysis/31_bootstrap_request.json`.
- Escrever somente `{{CARD_DIR}}/analysis/33_authority_validation.json`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Validar o handoff consumido como completed de `repository_topology` e validar novamente o receipt de topologia.
- Preservar o mesmo request id enquanto necessidade, cenario e destinos permitidos nao mudarem.
- Se a decisao explicita ou resultado externo estiver ausente, escrever estado waiting, executar o validador de authority e emitir o envelope waiting.
- Se `32_bootstrap_result.json` existir, exigir request id, repo key, destino e autorizacao correlacionados; resultado presente invalido falha fechado.
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" authority "{{CARD_DIR}}/analysis/30_authority_resolution.yaml" > "{{CARD_DIR}}/analysis/33_authority_validation.json"` e exigir exit 0.
- No estado resolved, executar `printf '%s' '{"from_phase":"authority_resolution","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- No estado waiting, carregar o request id validado em `request_id` e executar `printf '{"from_phase":"authority_resolution","status":"waiting","messages":["request_id=%s;inject={{CARD_DIR}}/analysis/32_bootstrap_result.json"],"codes":["WAITING"]}' "$request_id" > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `contract_tool.py handoff`, usando status igual ao estado emitido.

FORBIDDEN
- Nao executar bootstrap, criar repositorio, executar Git mutavel ou fabricar `32_bootstrap_result.json`.
- Nao escolher o primeiro target nem aceitar zero ou multiplos bindings como resolved.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check, handoff de entrada ou validacao de topologia falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se houver zero ou multiplos bindings no estado resolved, ou binding sem source explicita.
- Falhar se resultado externo presente tiver correlacao, destino, repo key ou autorizacao invalida.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff nao tiver `codes`, nao estiver em uma linha ou divergir de completed/waiting validado.
