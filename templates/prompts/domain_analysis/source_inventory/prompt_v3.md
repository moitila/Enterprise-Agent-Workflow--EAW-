{{RUNTIME_ENVIRONMENT}}

ROLE
- Fixar fontes, autoridade, revisao imutavel e binding upstream antes de qualquer inferencia de dominio.

OBJECTIVE
- Provar que a publicacao upstream e as fontes declaradas sao legiveis deterministicamente, sem criar conceitos.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Locator upstream obrigatorio e fontes opcionais explicitamente declaradas.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/00_source_manifest.yaml, {{CARD_DIR}}/analysis/01_source_gaps.md, {{CARD_DIR}}/analysis/02_upstream_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Manifesto de fontes com source_id/provenance; gaps; validacao com paths, hashes e digest; handoff compacto completed ou waiting.

READ_SCOPE
- Ler {{CONFIG_SOURCE}}, contrato/tool e somente manifesto, paths e fontes declarados na revisao upstream exata.

WRITE_SCOPE
- Escrever somente os quatro paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Resolver repo_key por {{CONFIG_SOURCE}}, usar parser estruturado e reler bytes da revisao, nunca da working tree. Esta fase nao cria conceitos.
- Em sucesso, executar `printf '%s' '{"from_phase":"source_inventory","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Em espera, executar `printf '%s' '{"from_phase":"source_inventory","status":"waiting","blocker":"<blocker concreto>","messages":[],"codes":["WAITING"]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao inferir conceitos, aceitar revisao mutavel, inventar fonte ou alterar repositorios.

FAIL_CONDITIONS
- Falhar se pre-check/parsing falhar, output faltar, completed coexistir com valid:false ou handoff for invalido.
- Falhar se houver placeholder operacional shell-style de chave simples.
