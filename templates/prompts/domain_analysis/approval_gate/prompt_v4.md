{{RUNTIME_ENVIRONMENT}}

ROLE
- Vincular a aprovação externa à identidade e digest exatos do pacote candidato de cinco destinos.

OBJECTIVE
- Revalidar semantic e coverage e avançar apenas com registro externo que prove aprovação do digest exato.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Candidate completo, manifest, validações e approval_record.json se fornecido externamente.
- O snapshot candidate `candidate/domain-analysis-coverage.yaml`, que integra os cinco destinos aprovados.

OUTPUT
- Escrever {{CARD_DIR}}/approval/approval_request.json, {{CARD_DIR}}/approval/approval_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Request e validation identificam os cinco arquivos — incluindo `domain-analysis-coverage.yaml` —, hashes, digest e decisão observada; handoff completed ou waiting conforme contrato.

READ_SCOPE
- Ler candidate, validações, registro externo fornecido e contrato/ferramenta versionados. Não buscar/criar aprovação externa.

WRITE_SCOPE
- Escrever somente os três paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Revalidar semantic, coverage e o snapshot `candidate/domain-analysis-coverage.yaml`, além de hashes e digest dos cinco destinos, antes de solicitar/validar. Ausência de registro gera waiting sem criar record; qualquer divergence falha fechado.
- Handoff completed: `printf '%s' '{"from_phase":"approval_gate","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Handoff waiting: `printf '%s' '{"from_phase":"approval_gate","status":"waiting","blocker":"<aprovação externa pendente, detalhe objetivo>","messages":[],"codes":["WAITING"]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Não autoaprovar, criar/editar registro externo, alterar pacote/digest ou aceitar aprovação de outra revisão.

FAIL_CONDITIONS
- Falhar se revalidação/output falhar, registro presente divergir ou handoff não refletir o estado observado.
- Falhar se houver placeholder operacional shell-style de chave simples.
