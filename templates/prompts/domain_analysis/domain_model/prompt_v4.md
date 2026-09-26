{{RUNTIME_ENVIRONMENT}}

ROLE
- Consolidar seletivamente o modelo/glossário e reconciliar cada candidato descoberto com disposição explícita.

OBJECTIVE
- Preservar a consistência semântica e provar que nenhum candidato desaparece entre discovery e modelo consolidado.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Inventário, analysis/03_candidate_coverage.yaml, analysis/04_discovery_coverage_report.md e contrato versionado.

OUTPUT
- Escrever {{CARD_DIR}}/analysis/10_domain_model.md, {{CARD_DIR}}/analysis/11_domain_glossary.yaml, {{CARD_DIR}}/analysis/12_domain_questions.md, {{CARD_DIR}}/analysis/13_coverage_disposition.yaml e {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- Preservar marcadores narrativos `<!-- concept: {"concept_id":"...","type":"..."} -->` e schema do glossário.
- Preservar os campos `canonicalization` e checks de qualificação do glossário existentes.
- dispositions[] possui uma entrada para cada candidate_id, disposition do enum fechado, rationale exigida, canonical_concept_id quando CANONICAL, deferred_to quando DEFERRED, relações explícitas de equivalência/substituição e upstream_status original.

READ_SCOPE
- Ler artefatos anteriores em {{CARD_DIR}}/analysis/, fontes do manifesto e {{RUNTIME_ROOT}}/tracks/domain_analysis/contracts/contract_v1.json.

WRITE_SCOPE
- Escrever somente os cinco paths declarados em OUTPUT.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Enum: CANONICAL, CANDIDATE, HYPOTHESIS, NON_CANONICAL, DEFERRED, OUT_OF_SCOPE, CONFLICT, TBD. Não canonizar por cobertura; manter cada ID e justificar qualquer relação/fusão.
- Comparar IDs de discovery e dispositions nos dois sentidos. CANONICAL deve estar no modelo e glossário; NON_CANONICAL, DEFERRED, OUT_OF_SCOPE, CONFLICT e TBD requerem rationale; DEFERRED requer deferred_to.
- Preservar exatamente upstream_status; PROPOSED, TBD, SIMULATED, OUT_OF_SCOPE e SUPERSEDED não podem ser promovidos. Tipos táticos são condicionais à evidência.
- Manter os checks semânticos existentes. Handoff: `printf '%s' '{"from_phase":"domain_model","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.

FORBIDDEN
- Não canonizar todos, inventar conceitos, eliminar item sem motivo, promover autoridade, projetar regras operacionais, banco, APIs, frontend ou arquitetura técnica.

FAIL_CONDITIONS
- Falhar se faltar artifact, ID não reconciliar, disposição inválida, canônico sem correspondente, justificativa/destino ausente, estado upstream promovido, semantic checks enfraquecidos ou handoff inválido.
- Falhar se houver placeholder operacional shell-style de chave simples.
