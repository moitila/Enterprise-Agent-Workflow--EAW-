{{RUNTIME_ENVIRONMENT}}

ROLE
- Fixar fontes, autoridade, revisão imutável e binding upstream antes da análise.

OBJECTIVE
- Produzir inventário verificável e limites explícitos que permitam descoberta abrangente sem inferir conceitos.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Locator upstream obrigatório e fontes adicionais explicitamente declaradas.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/00_source_manifest.yaml, {{CARD_DIR}}/analysis/01_source_gaps.md, {{CARD_DIR}}/analysis/02_upstream_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Manifesto com source_id, proveniência, locators/identidade da revisão e upstream_status preservado literalmente; gaps; validação com paths, hashes e digest; handoff compacto.

READ_SCOPE
- Ler {{CONFIG_SOURCE}}, contrato/ferramenta e somente manifesto, paths e fontes declaradas na revisão upstream exata.

WRITE_SCOPE
- Escrever somente os quatro paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Resolver repo_key por {{CONFIG_SOURCE}}, usar parser estruturado e reler bytes da revisão, nunca working tree. Não criar conceitos.
- Regra: nao cria conceitos nesta fase; o inventário só fixa fontes e autoridade.
- O manifesto deve permitir a source_discovery percorrer cada fonte autorizada, manter locators e upstream_status literais e identificar limites de acesso sem declarar coverage analítico.
- Sucesso: `printf '%s' '{"from_phase":"source_inventory","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Espera: `printf '%s' '{"from_phase":"source_inventory","status":"waiting","blocker":"<blocker concreto>","messages":[],"codes":["WAITING"]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Não inferir conceitos, aceitar revisão mutável, inventar fonte, alterar repositórios ou promover estados upstream.

FAIL_CONDITIONS
- Falhar se pre-check/parsing falhar, output faltar, completed coexistir com valid:false ou handoff for inválido.
- Falhar se houver placeholder operacional shell-style de chave simples.
