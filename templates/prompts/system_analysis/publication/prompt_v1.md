{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de validacao `publication`, solicitando publicacao externa e validando seu resultado sem mutar repositorios.

OBJECTIVE
- Emitir request restrito aos quatro destinos, candidate aprovado, autoridade e revisao-base.
- Aguardar executor externo quando ausente ou validar mecanicamente o resultado publicado.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: candidate completo, autoridade, approval request/record/validation e handoff completed de `approval_gate`.
- Entrada externa opcional e reservada: `{{CARD_DIR}}/publication/publication_result.json`, somente se ja tiver sido injetada.

OUTPUT
- Escrever `{{CARD_DIR}}/publication/publication_request.json`.
- Escrever `{{CARD_DIR}}/publication/publication_validation.json`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.
- Nao escrever `{{CARD_DIR}}/publication/publication_result.json`; esse resultado e externo.
- Os quatro documentos permanentes sao saida futura do executor externo, nao desta fase.

OUTPUT_STRUCTURE
- `publication_request.json`: `contract_version: 1`, request id, repo key, base revision, approved digest e lista canonica dos quatro paths.
- `publication_validation.json`: receipt com `contract_version: 1`, `valid` booleano e `errors`; waiting usa `valid: false`, `state: waiting`, `errors: []`; sucesso usa state published, revision e published digest.
- `20_handoff.json`: envelope compacto completed/codes vazio ou waiting/codes WAITING.

READ_SCOPE
- Ler os REQUIRED_ARTIFACTS e revalidar candidate, approval, autoridade e revisao-base.
- Ler `{{CARD_DIR}}/publication/publication_result.json` somente se existir.
- Ler o contrato e a ferramenta sob `{{RUNTIME_ROOT}}/tracks/system_analysis/`.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/publication/publication_request.json`.
- Escrever somente `{{CARD_DIR}}/publication/publication_validation.json`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Validar o handoff de entrada como completed de `approval_gate` e exigir approval validation `valid: true`.
- Recalcular o candidate e confirmar autoridade, base revision e approved digest imediatamente antes do request.
- Restringir paths exatamente a `docs/system/repository-topology.md`, `docs/system/repositories.yaml`, `docs/system/system-analysis.manifest.json` e `docs/system/system-analysis.md`.
- Se o result externo estiver ausente, executar `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" publication "{{CARD_DIR}}/publication/publication_request.json" - > "{{CARD_DIR}}/publication/publication_validation.json"`.
- Se o result existir, executar o mesmo comando com `{{CARD_DIR}}/publication/publication_result.json`; resultado presente invalido falha fechado.
- No estado published, executar `printf '%s' '{"from_phase":"publication","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- No estado waiting, carregar o request id validado em `request_id` e executar `printf '{"from_phase":"publication","status":"waiting","messages":["request_id=%s;inject={{CARD_DIR}}/publication/publication_result.json"],"codes":["WAITING"]}' "$request_id" > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `contract_tool.py handoff`, usando status igual ao estado emitido.

FORBIDDEN
- Nao executar Git mutavel, escrever no repositorio autoritativo ou fabricar `publication_result.json`.
- Nao aceitar path extra, request id divergente, repo key divergente, base revision divergente ou published digest diferente do approved digest.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check, revalidacoes ou handoff de entrada falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se result presente tiver correlacao, repositorio, revisao, destinos ou digest invalidos.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff nao tiver `codes`, nao estiver em uma linha ou divergir de published/waiting validado.
