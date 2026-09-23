{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de analise `system_baseline`, consolidando uma baseline rastreavel sem decidir topologia ou autoridade.

OBJECTIVE
- Consolidar objetivo, escopo, atores, capacidades, limites, restricoes, decisoes e questoes abertas a partir do inventario aprovado.
- Preservar contradicoes e nivel de certeza para consumo mecanico e humano na proxima fase.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: `{{CARD_DIR}}/analysis/00_source_manifest.yaml`, `{{CARD_DIR}}/analysis/01_source_gaps.md`, `{{CARD_DIR}}/analysis/02_source_provenance.md` e `{{CARD_DIR}}/investigations/20_handoff.json` de `source_inventory`.

OUTPUT
- Escrever `{{CARD_DIR}}/analysis/10_system_analysis.candidate.md`.
- Escrever `{{CARD_DIR}}/analysis/11_decision_register.yaml`.
- Escrever `{{CARD_DIR}}/analysis/12_open_questions.md`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.

OUTPUT_STRUCTURE
- `10_system_analysis.candidate.md`: secoes Identidade, Objetivo, Escopo Dentro, Escopo Fora, Atores, Capacidades, Limites, Restricoes, Decisoes Vigentes, Suposicoes, Questoes Abertas e Limites de Confianca.
- `11_decision_register.yaml`: `contract_version: 1` e decisoes com `decision_id`, estado entre DECIDED, PROPOSED, TBD, SIMULATED, OUT_OF_SCOPE e SUPERSEDED, source ids e justificativa.
- `12_open_questions.md`: questoes sem resposta, evidencia faltante, responsavel quando declarado e impacto.
- `20_handoff.json`: JSON compacto completed de `system_baseline`, com `codes` vazio.

READ_SCOPE
- Ler os quatro REQUIRED_ARTIFACTS.
- Ler somente as fontes autorizadas e identificadas no `00_source_manifest.yaml`.
- Ler `{{RUNTIME_ROOT}}/tracks/system_analysis/contracts/contract_v1.json` e a ferramenta local de contrato.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/analysis/10_system_analysis.candidate.md`.
- Escrever somente `{{CARD_DIR}}/analysis/11_decision_register.yaml`.
- Escrever somente `{{CARD_DIR}}/analysis/12_open_questions.md`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Validar que o handoff consumido tem `from_phase=source_inventory`, `status=completed` e `codes=[]`.
- Fazer cada afirmacao referenciar um `source_id` ou portar qualificacao explicita de inferencia ou incerteza.
- Manter contradicoes visiveis e nao promover PROPOSED, TBD ou SIMULATED para DECIDED sem fonte autoritativa.
- Depois de validar os tres artefatos, executar `printf '%s' '{"from_phase":"system_baseline","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" handoff "{{CARD_DIR}}/investigations/20_handoff.json" system_baseline completed`.

FORBIDDEN
- Nao decidir topologia, autoridade documental, arquitetura detalhada ou implementacao.
- Nao ocultar contradicoes nem converter ausencia de evidencia em decisao.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check ou o handoff de entrada falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se uma afirmacao nao tiver source id nem qualificacao, ou se um estado fora do contrato for usado.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff de saida nao for compacto, nao contiver `codes` ou falhar no validador local.
