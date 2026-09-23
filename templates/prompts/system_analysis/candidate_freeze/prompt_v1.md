{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de implementacao documental `candidate_freeze`, congelando um pacote byte-exato sem publicar.

OBJECTIVE
- Montar os quatro candidatos destinados aos paths permanentes e ligar cada byte a uma autoridade e revisao-base explicitas.
- Calcular SHA-256 por arquivo e digest agregado canonico para approval e publication posteriores.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: baseline, topologia, authority resolution, authority validation e handoff completed de `authority_resolution`.
- Metadados read-only da autoridade resolvida na revisao-base declarada.

OUTPUT
- Escrever `{{CARD_DIR}}/candidate/system-analysis.md`.
- Escrever `{{CARD_DIR}}/candidate/repository-topology.md`.
- Escrever `{{CARD_DIR}}/candidate/repositories.yaml`.
- Escrever `{{CARD_DIR}}/candidate/system-analysis.manifest.json`.
- Escrever `{{CARD_DIR}}/candidate/candidate_validation.json`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.

OUTPUT_STRUCTURE
- `system-analysis.md`: secoes Identidade, Objetivo, Escopo Dentro, Escopo Fora, Atores, Capacidades, Limites, Restricoes, Decisoes Vigentes, Suposicoes, Questoes Abertas e Limites de Confianca.
- `repository-topology.md`: secoes Cenario, Repositorios, Papeis, Relacoes, Autoridade, Lacunas, Conflitos e Limites.
- `repositories.yaml`: `contract_version: 1`, cenario e repositorios canonicos com keys, papeis, status e locators.
- `system-analysis.manifest.json`: `contract_version: 1`, identidade do candidate, repo key, revisao-base e os quatro destinos permanentes em ordem lexicografica.
- `candidate_validation.json`: `contract_version: 1`, `repo_key`, `base_revision`, mapa `files` dos quatro destinos para SHA-256 lowercase, `candidate_digest`, `valid: true` e `errors: []`.
- `20_handoff.json`: JSON compacto completed de `candidate_freeze`, com `codes` vazio.

READ_SCOPE
- Ler os REQUIRED_ARTIFACTS e os quatro candidates enquanto sao validados.
- Ler metadados da autoridade somente em modo read-only e na revisao-base declarada.
- Ler o contrato e a ferramenta sob `{{RUNTIME_ROOT}}/tracks/system_analysis/`.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/candidate/system-analysis.md`.
- Escrever somente `{{CARD_DIR}}/candidate/repository-topology.md`.
- Escrever somente `{{CARD_DIR}}/candidate/repositories.yaml`.
- Escrever somente `{{CARD_DIR}}/candidate/system-analysis.manifest.json`.
- Escrever somente `{{CARD_DIR}}/candidate/candidate_validation.json`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Exigir authority validation `valid: true`, binding unico e handoff completed de `authority_resolution`.
- Mapear exatamente para `docs/system/repository-topology.md`, `docs/system/repositories.yaml`, `docs/system/system-analysis.manifest.json` e `docs/system/system-analysis.md`, em ordem lexicografica.
- Calcular SHA-256 dos bytes finais de cada candidate e o agregado com entradas `destination`, byte NUL, SHA-256 lowercase e LF.
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" candidate "{{CARD_DIR}}/candidate/candidate_validation.json"` e exigir exit 0 e `valid: true`.
- Considerar qualquer mudanca posterior nos quatro candidates como nova identidade que exige novo approval.
- Depois da validacao, executar `printf '%s' '{"from_phase":"candidate_freeze","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" handoff "{{CARD_DIR}}/investigations/20_handoff.json" candidate_freeze completed`.

FORBIDDEN
- Nao escrever no repositorio autoritativo, publicar, solicitar approval antes da validacao ou adicionar destinos.
- Nao alterar authority binding ou revisao-base durante o freeze.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check, authority validation ou handoff de entrada falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se os quatro destinos, ordem, SHA-256 ou digest agregado divergirem do contrato.
- Falhar se `contract_tool.py candidate` retornar diferente de zero.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff nao for compacto, nao contiver `codes` ou falhar no validador local.
