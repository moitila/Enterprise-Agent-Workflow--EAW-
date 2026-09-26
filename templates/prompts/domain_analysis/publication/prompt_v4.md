{{RUNTIME_ENVIRONMENT}}

ROLE
- Verificar publicação externa imutável do pacote aprovado, incluindo snapshot de coverage.

OBJECTIVE
- Solicitar ou validar publicação que corresponda ao digest aprovado dos cinco destinos.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Candidate, validação semântica e coverage, aprovação do mesmo digest e resultado externo se fornecido.
- O snapshot `candidate/domain-analysis-coverage.yaml`, que deve corresponder byte a byte ao destino publicado `docs/domain/domain-analysis-coverage.yaml`.

OUTPUT
- Escrever {{CARD_DIR}}/publication/publication_request.json, {{CARD_DIR}}/publication/publication_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Request/validation listam os cinco destinos — incluindo `docs/domain/domain-analysis-coverage.yaml` —, hashes/digest e revisão imutável observada; handoff completed ou waiting com blocker não vazio.

READ_SCOPE
- Ler candidate, aprovação, resultados anteriores, registro externo fornecido e contrato/ferramenta. Não acessar destino externo.

WRITE_SCOPE
- Escrever somente os três paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Revalidar candidate, approval, semantic e coverage, comparando `candidate/domain-analysis-coverage.yaml` com `docs/domain/domain-analysis-coverage.yaml`; exigir resultado que prove identidade e digest dos cinco destinos. Ausência/pendência externa gera waiting.
- Completed: `printf '%s' '{"from_phase":"publication","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Waiting: `printf '%s' '{"from_phase":"publication","status":"waiting","blocker":"<publicação externa pendente, detalhe objetivo>","messages":[],"codes":["WAITING"]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Não publicar diretamente, editar resultado externo, adicionar/remover destinos ou declarar publicação não comprovada como consumível.

FAIL_CONDITIONS
- Falhar se aprovação, coverage, resultado, hashes/digest ou handoff divergir; falhar se houver placeholder operacional shell-style de chave simples.
