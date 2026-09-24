{{RUNTIME_ENVIRONMENT}}

ROLE
- Reler a publicacao permanente e emitir contrato downstream autocontido.

OBJECTIVE
- Provar local e sequencialmente os bytes publicados e a igualdade candidate/approved/published/consumed.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Todos os artefatos upstream/model/candidate/approval/publication e handoff de publication.

OUTPUT
- Escrever {{CARD_DIR}}/consumption/consumption_receipt.json, {{CARD_DIR}}/consumption/downstream_manifest.yaml, {{CARD_DIR}}/consumption/handoff.md e {{CARD_DIR}}/consumption/validation_report.md.

OUTPUT_STRUCTURE
- consumption_receipt.json: valid, errors, repo_key, revision, quatro files e quatro digests.
- downstream_manifest.yaml: autoridade/revisao/paths/hashes/digest/sources, classificacoes conceituais aplicaveis, limites, decisoes, divergencias, perguntas e consumidores.
- handoff.md: identidade, conceitos rastreados, provenance, limites e pendencias, sem desenho tecnico.
- validation_report.md: comandos, exit codes e evidencia local/sequencial.

READ_SCOPE
- Ler artefatos de INPUT, {{CONFIG_SOURCE}}, contrato/tool e os quatro paths na revisao publicada exata, em modo read-only.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/consumption/consumption_receipt.json, {{CARD_DIR}}/consumption/downstream_manifest.yaml, {{CARD_DIR}}/consumption/handoff.md e {{CARD_DIR}}/consumption/validation_report.md.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir predecessor completed/publication valid:true. Resolver repo por key e reler quatro paths na revisao publicada, nunca pela working tree.
- Recalcular hashes/digest e executar `python3 "{{RUNTIME_ROOT}}/tracks/domain_analysis/tools/contract_tool.py" consumption "{{CARD_DIR}}/consumption/consumption_receipt.json"`.
- Exigir candidate_digest == approved_digest == published_digest == consumed_digest; registrar stdout e exit code observados.

FORBIDDEN
- Nao alterar Git, corrigir/republicar, substituir result, usar outra revisao, alegar prova remota/concorrente ou acrescentar desenho tecnico.

FAIL_CONDITIONS
- Falhar se pre-check/input/tool falhar, output faltar, receipt nao for valid:true ou repo/revisao/path/hash/digest divergir.
- Falhar se houver referencia operacional shell-style de chave simples ou report sem comandos, exit codes e evidencia de releitura.
