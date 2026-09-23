{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de ingestao `source_inventory`, inventariando fontes sem interpretar o sistema.

OBJECTIVE
- Congelar identidade, disponibilidade, provenance e precedencia declarada de cada fonte autorizada.
- Produzir um inventario rastreavel que a baseline possa consumir sem conhecimento implicito.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- TARGET_REPOSITORIES e READ_SOURCES fornecidos em RUNTIME_ENVIRONMENT.
- Se `{{CARD_DIR}}/ingest/` existir e nao estiver vazio, seu conteudo e fonte candidata.

OUTPUT
- Escrever `{{CARD_DIR}}/analysis/00_source_manifest.yaml`.
- Escrever `{{CARD_DIR}}/analysis/01_source_gaps.md`.
- Escrever `{{CARD_DIR}}/analysis/02_source_provenance.md`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.

OUTPUT_STRUCTURE
- `00_source_manifest.yaml`: `contract_version: 1` e fontes ordenadas por `source_id`, cada uma com identidade, locator, disponibilidade, provenance, precedencia declarada e classificacao observado/declarado/inferido.
- `01_source_gaps.md`: fontes ausentes, inacessiveis ou incompletas, com impacto observavel e sem preencher lacunas por suposicao.
- `02_source_provenance.md`: cadeia entre cada `source_id`, sua origem e a evidencia usada para classifica-la.
- `20_handoff.json`: JSON compacto com `from_phase`, `status`, `messages` e `codes`.

READ_SCOPE
- Ler `{{CONFIG_SOURCE}}`.
- Ler somente TARGET_REPOSITORIES e READ_SOURCES declarados em RUNTIME_ENVIRONMENT.
- Ler `{{CARD_DIR}}/ingest/` somente se existir e nao estiver vazio.
- Ler `{{RUNTIME_ROOT}}/tracks/system_analysis/contracts/contract_v1.json` e a ferramenta local de contrato.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/analysis/00_source_manifest.yaml`.
- Escrever somente `{{CARD_DIR}}/analysis/01_source_gaps.md`.
- Escrever somente `{{CARD_DIR}}/analysis/02_source_provenance.md`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Aplicar o READ_SCOPE antes de abrir qualquer fonte e registrar fontes inacessiveis como lacunas.
- Distinguir fatos observados, declaracoes das fontes e inferencias; toda inferencia deve ser qualificada.
- Nao usar ordem de TARGET_REPOSITORIES ou de `repos.conf` como precedencia documental.
- Ordenar o manifesto por `source_id` estavel.
- Depois de validar os tres artefatos, executar `printf '%s' '{"from_phase":"source_inventory","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" handoff "{{CARD_DIR}}/investigations/20_handoff.json" source_inventory completed`.

FORBIDDEN
- Nao consolidar baseline, desenhar topologia, escolher autoridade ou mutar repositorios.
- Nao ler paths fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.
- Nao inventar conteudo de fonte ausente ou inacessivel.

FAIL_CONDITIONS
- Falhar se o pre-check falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se o manifesto nao usar `contract_version: 1`, nao estiver ordenado por `source_id` ou omitir provenance e disponibilidade.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff nao for compacto, nao contiver `codes` ou falhar no validador local.
