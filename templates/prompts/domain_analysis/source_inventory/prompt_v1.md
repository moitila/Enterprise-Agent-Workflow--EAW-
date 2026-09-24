{{RUNTIME_ENVIRONMENT}}

ROLE
- Inventariar fontes e a publicacao autoritativa da system_analysis.

OBJECTIVE
- Verificar identidade, autoridade, revisao e digest do pacote upstream antes da analise de dominio.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Locators explicitos do card para consumption/downstream_manifest.yaml, consumption/consumption_receipt.json e quatro documentos publicados da system_analysis.
- TARGET_REPOSITORIES e READ_SOURCES do ambiente; {{CARD_DIR}}/ingest/ apenas quando declarado e existente.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/00_source_manifest.yaml, 01_source_gaps.md e 02_upstream_validation.json.
- Escrever {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- 00_source_manifest.yaml: contract_version: 1; fontes ordenadas por source_id, locator, disponibilidade, proveniencia, precedencia, certeza e binding upstream.
- 01_source_gaps.md: ausencias, impacto, conflitos e divergencias com decisoes vigentes.
- 02_upstream_validation.json: contract_version, valid, errors, locators, repo key, revisao e digest observados.
- 20_handoff.json: envelope compacto com from_phase, status, messages, codes; em espera, blocker concreto.

READ_SCOPE
- Ler {{CONFIG_SOURCE}}, locators upstream declarados, metadados read-only dos TARGET_REPOSITORIES e fontes opcionais declaradas.
- Reler na revisao upstream os quatro paths docs/system/system-analysis.md, docs/system/repository-topology.md, docs/system/repositories.yaml e docs/system/system-analysis.manifest.json do repositorio indicado pelo handoff.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/analysis/00_source_manifest.yaml, {{CARD_DIR}}/analysis/01_source_gaps.md, {{CARD_DIR}}/analysis/02_upstream_validation.json e {{CARD_DIR}}/investigations/20_handoff.json.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir locators explicitos, verificar paths, hashes e digest do manifesto e receipt upstream contra bytes da revisao declarada; a ordem de TARGET_REPOSITORIES nao define autoridade.
- Fontes opcionais ausentes geram lacunas; decisoes vigentes prevalecem e divergencias ficam explicitas.
- Sem pacote indispensavel consistente: valid:false e handoff waiting com codes:["WAITING"] e blocker com locators; nao inferir conteudo.
- Serializar handoff em JSON compacto de uma linha e gravar com `printf '%s' "$handoff_json" > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Nao buscar cards por heuristica, escolher autoridade por ordem, inventar fonte ausente ou alterar repositorios.

FAIL_CONDITIONS
- Falhar se pre-check falhar, output estiver ausente/vazio, ou completed for emitido sem upstream valid:true.
- Falhar se handoff nao for JSON compacto de uma linha, sem codes ou sem blocker em waiting.
