{{RUNTIME_ENVIRONMENT}}

ROLE
- Verificar a publicacao e emitir o contrato de consumo downstream.

OBJECTIVE
- Reler quatro documentos na revisao publicada e provar igualdade dos digests candidato, aprovado, publicado e consumido.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Inventario/upstream, modelo, capacidades, candidato/validation, approval request/record/validation, publication request/result/validation e handoff de publication.

OUTPUT
- Escrever {{CARD_DIR}}/consumption/consumption_receipt.json, downstream_manifest.yaml, handoff.md e validation_report.md.

OUTPUT_STRUCTURE
- consumption_receipt.json: contract_version: 1, valid, errors, repo key, revisao publicada, quatro destinos/hashes e quatro digests nao vazios.
- downstream_manifest.yaml: contract_version: 1, autoridade, revisao, paths/hashes, digest, source_id, limites, decisoes vigentes, divergencias, questoes e consumidores business_rules_analysis, data_model_analysis, backend_architecture.
- handoff.md: identidade, proveniencia, limites, decisoes e pendencias autocontidas para consumidores.
- validation_report.md: comandos, exit codes e evidencia da releitura e do calculo; limite local e sequencial da prova.

READ_SCOPE
- Ler artefatos de INPUT e quatro paths permanentes no repositorio de autoridade, na revisao publicada do result validado, somente em modo read-only.

WRITE_SCOPE
- Escrever somente {{CARD_DIR}}/consumption/consumption_receipt.json, {{CARD_DIR}}/consumption/downstream_manifest.yaml, {{CARD_DIR}}/consumption/handoff.md e {{CARD_DIR}}/consumption/validation_report.md.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Exigir handoff completed de publication e publication_validation.json.valid:true; autoridade vem do binding validado.
- Reler quatro paths na revisao publicada, calcular SHA-256 dos bytes e digest agregado com destinos ordenados e destination + NUL + hash lowercase + LF.
- Exigir candidato == aprovado == publicado == consumido e conjunto exato de destinos. Somente entao marcar receipt.valid:true.
- Registrar comandos e exit codes no relatorio; a prova cobre somente revisao lida e sequencia local.

FORBIDDEN
- Nao alterar Git, corrigir/republicar documentos, substituir resultado externo, alegar prova remota/concorrente ou introduzir desenho tecnico.

FAIL_CONDITIONS
- Falhar se pre-check, handoff ou validation de entrada falhar; se output estiver ausente/vazio; se repo key, revisao, paths, hashes ou digest divergir.
- Falhar se receipt.valid nao for true ou relatorio nao registrar a releitura.
