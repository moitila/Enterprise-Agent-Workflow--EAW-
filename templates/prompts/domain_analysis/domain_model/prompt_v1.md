{{RUNTIME_ENVIRONMENT}}

ROLE
- Analisar linguagem, conceitos, atores, relacoes e limites conceituais do dominio.

OBJECTIVE
- Produzir modelo com evidencia e incertezas consumivel pelo mapa de capacidades.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- {{CARD_DIR}}/analysis/00_source_manifest.yaml, 01_source_gaps.md, 02_upstream_validation.json e handoff de source_inventory.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/10_domain_model.md, 11_domain_glossary.yaml, 12_domain_questions.md e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- 10_domain_model.md: conceitos, sinonimos, atores, relacoes e limites com IDs, evidencia, conflito e certeza observado/declarado/inferido.
- 11_domain_glossary.yaml: contract_version: 1; ID, termo, definicao, sinonimos, source_id, confianca e conceitos relacionados.
- 12_domain_questions.md: questoes, evidencia faltante, conflito e impacto.
- 20_handoff.json: from_phase domain_model, status completed, messages [], codes [].

READ_SCOPE
- Ler somente artefatos de INPUT e fontes disponiveis identificadas por source_id/locator no manifesto, incluindo upstream na revisao validada.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/analysis/10_domain_model.md, {{CARD_DIR}}/analysis/11_domain_glossary.yaml, {{CARD_DIR}}/analysis/12_domain_questions.md e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir handoff completed de source_inventory e 02_upstream_validation.json.valid:true.
- Vincular cada afirmacao a source_id ou qualificacao explicita de inferencia; preservar decisoes vigentes, conflitos e limites.
- Apos validar outputs, executar `printf '%s' '{"from_phase":"domain_model","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao detalhar regras de negocio, banco, APIs, frontend, infraestrutura ou arquitetura tecnica; nao promover conflito a decisao vigente.

FAIL_CONDITIONS
- Falhar se pre-check, handoff ou upstream validado falhar; se output estiver ausente/vazio; se ID/evidencia ou qualificacao de inferencia faltar.
- Falhar se handoff nao for compacto em uma linha com codes:[].
