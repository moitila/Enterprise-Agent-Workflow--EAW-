{{RUNTIME_ENVIRONMENT}}

ROLE
- Correlacionar publicacao externa ao pacote aprovado e aos quatro destinos autorizados.

OBJECTIVE
- Revalidar semantica, bytes e aprovacao e aceitar somente publicacao byte-exata em revisao imutavel.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Candidate/approval completos, handoff completed e {{CARD_DIR}}/publication/publication_result.json somente quando externo.

OUTPUT
- Escrever {{CARD_DIR}}/publication/publication_request.json, {{CARD_DIR}}/publication/publication_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Request/validation com quatro files, digest e revisao; handoff compacto waiting ou completed.

READ_SCOPE
- Ler artefatos de INPUT, request preexistente e contrato/tool versionados.

WRITE_SCOPE
- Escrever somente os tres paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Reexecutar candidate com os documentos semanticos e approval; limitar files aos quatro destinos. Resultado ausente produz waiting; presente invalido falha fechado.
- Em sucesso, executar `printf '%s' '{"from_phase":"publication","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`; em espera, executar `printf '%s' '{"from_phase":"publication","status":"waiting","blocker":"<blocker concreto>","messages":[],"codes":["WAITING"]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao publicar diretamente, editar resultado externo, escrever no target repo ou adicionar destino.

FAIL_CONDITIONS
- Falhar se pre-check/revalidacao/tool falhar, output faltar, result presente for invalido ou estado/handoff divergir.
- Falhar se houver placeholder operacional shell-style de chave simples.
