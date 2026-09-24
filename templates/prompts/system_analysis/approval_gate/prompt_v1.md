{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de validacao `approval_gate`, solicitando approval externo e validando sua ligacao ao candidate congelado.

OBJECTIVE
- Emitir request persistente para a identidade exata do candidate, autoridade e revisao-base.
- Aguardar record externo quando ausente ou validar approval autenticamente fornecido sem autoaprovar.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: pacote candidate completo, candidate validation, authority resolution e handoff completed de `candidate_freeze`.
- Entrada externa opcional e reservada: `{{CARD_DIR}}/approval/approval_record.json`, somente se ja tiver sido injetada.

OUTPUT
- Escrever `{{CARD_DIR}}/approval/approval_request.json`.
- Escrever `{{CARD_DIR}}/approval/approval_validation.json`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.
- Nao escrever `{{CARD_DIR}}/approval/approval_record.json`; esse record e externo.

OUTPUT_STRUCTURE
- `approval_request.json`: `contract_version: 1`, request id persistente, candidate identity, candidate digest, authority completa e base revision.
- `approval_validation.json`: receipt com `contract_version: 1`, `valid` booleano e `errors`; waiting usa `valid: false`, `state: waiting`, `errors: []`; sucesso usa state approved e approved digest.
- `20_handoff.json`: envelope compacto completed/codes vazio ou waiting/codes WAITING.

READ_SCOPE
- Ler os REQUIRED_ARTIFACTS e recalcular o candidate a partir dos quatro arquivos.
- Ler `{{CARD_DIR}}/approval/approval_record.json` somente se existir.
- Ler o contrato e a ferramenta sob `{{RUNTIME_ROOT}}/tracks/system_analysis/`.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/approval/approval_request.json`.
- Escrever somente `{{CARD_DIR}}/approval/approval_validation.json`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Validar o handoff de entrada como completed de `candidate_freeze` e executar novamente `contract_tool.py candidate`.
- Preservar o request id enquanto candidate identity, digest, autoridade e revisao-base permanecerem identicos.
- Se o record externo estiver ausente, executar `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" approval "{{CARD_DIR}}/approval/approval_request.json" - > "{{CARD_DIR}}/approval/approval_validation.json"`.
- Se o record existir, executar o mesmo comando com `{{CARD_DIR}}/approval/approval_record.json`; resultado presente rejeitado ou invalido falha fechado.
- No estado approved, executar `printf '%s' '{"from_phase":"approval_gate","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- No estado waiting, carregar o request id validado em `request_id` e executar `printf '{"from_phase":"approval_gate","status":"waiting","blocker":"Aguardando approval externo para request_id=%s;inject={{CARD_DIR}}/approval/approval_record.json","messages":[],"codes":["WAITING"]}' "$request_id" > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `contract_tool.py handoff`, usando status igual ao estado emitido.

FORBIDDEN
- Nao autoaprovar, fabricar, editar ou substituir `approval_record.json`.
- Nao aceitar record rejeitado, aprovador vazio ou divergencia de request, candidate, autoridade ou revisao-base.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check, candidate revalidation ou handoff de entrada falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se record presente for rejeitado ou divergir de request id, candidate identity/digest, autoridade, base revision ou aprovador.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff nao tiver `codes`, nao estiver em uma linha ou divergir de approved/waiting validado.
