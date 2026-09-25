{{RUNTIME_ENVIRONMENT}}

ROLE
- Reler a publicacao e emitir contrato downstream autocontido, tipado e validado.

OBJECTIVE
- Provar preservacao semantica/byte-exata e separar permissao futura de consumidores da instalacao observada e de categorias informativas.

INPUT
- CARD={{CARD}}; CARD_DIR={{CARD_DIR}}; RUNTIME_ROOT={{RUNTIME_ROOT}}; CONFIG_SOURCE={{CONFIG_SOURCE}}.
- Artefatos upstream/model/candidate/approval/publication, contrato/tool e {{RUNTIME_ROOT}}/tracks/tracks.yaml.

OUTPUT
- Escrever {{CARD_DIR}}/consumption/consumption_receipt.json, downstream_manifest.yaml, handoff.md e validation_report.md.

OUTPUT_STRUCTURE
- Receipt com digest/paridade; manifesto com authoritative_consumers e informational_categories; handoff documental; report com comandos, exit codes, permissao contratual e instalacao observada separadas.

READ_SCOPE
- Ler artefatos de INPUT, {{CONFIG_SOURCE}}, registry e os quatro paths da revisao publicada exata, read-only.

WRITE_SCOPE
- Escrever somente os quatro paths declarados em OUTPUT sob {{CARD_DIR}}/consumption.

RULES
- Antes de qualquer outra acao: echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Reler bytes pela revisao publicada, recalcular hashes/digest e reexecutar semantic sobre os documentos publicados.
- Executar consumption e manifest; consumidor exige membership em authoritative_consumer_track_ids e authoritative:true. Reportar installed exclusivamente pelo registry, sem promover permissao futura a instalacao.
- Categoria exige category_id, authoritative:false e ausencia de track_id, target, route e workflow.

FORBIDDEN
- Nao alterar Git, corrigir/republicar, inferir track livre, misturar categoria/consumidor ou criar roteamento informativo.

FAIL_CONDITIONS
- Falhar se pre-check/input/tool falhar, output faltar, receipt/manifest nao for valid:true, paridade/digest divergir ou consumidor/categoria violar contrato.
- Falhar se houver placeholder operacional shell-style de chave simples.
