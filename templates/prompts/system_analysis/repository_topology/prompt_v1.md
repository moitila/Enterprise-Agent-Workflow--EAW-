{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de analise `repository_topology`, modelando repositorios sem selecionar autoridade pela ordem.

OBJECTIVE
- Modelar zero, um ou N repositorios, seus papeis, estados e relacoes.
- Produzir prova mecanica de chaves unicas, cenario coerente e invariancia de ordem.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: outputs da baseline, `{{CARD_DIR}}/analysis/00_source_manifest.yaml` e handoff completed de `system_baseline`.
- TARGET_REPOSITORIES e seus metadados read-only fornecidos em RUNTIME_ENVIRONMENT.

OUTPUT
- Escrever `{{CARD_DIR}}/analysis/20_repository_topology.candidate.md`.
- Escrever `{{CARD_DIR}}/analysis/21_repository_manifest.candidate.yaml`.
- Escrever `{{CARD_DIR}}/analysis/22_topology_validation.json`.
- Escrever `{{CARD_DIR}}/investigations/20_handoff.json`.

OUTPUT_STRUCTURE
- `20_repository_topology.candidate.md`: secoes Cenario, Repositorios, Papeis, Relacoes, Autoridade, Lacunas, Conflitos e Limites.
- `21_repository_manifest.candidate.yaml`: JSON compativel com YAML contendo `contract_version: 1`, `scenario`, `order_invariant: true` e `entries`; cada entry possui `repo_key`, status active/planned/retired e locator tipado com type/value.
- `22_topology_validation.json`: stdout compacto do validador local, com `valid: true`, cenario e repository keys ordenadas.
- `20_handoff.json`: JSON compacto completed de `repository_topology`, com `codes` vazio.

READ_SCOPE
- Ler os REQUIRED_ARTIFACTS e `{{CONFIG_SOURCE}}`.
- Ler somente metadados read-only dos TARGET_REPOSITORIES declarados em RUNTIME_ENVIRONMENT.
- Ler `{{RUNTIME_ROOT}}/tracks/system_analysis/contracts/contract_v1.json` e `{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py`.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/analysis/20_repository_topology.candidate.md`.
- Escrever somente `{{CARD_DIR}}/analysis/21_repository_manifest.candidate.yaml`.
- Escrever somente `{{CARD_DIR}}/analysis/22_topology_validation.json`.
- Escrever somente `{{CARD_DIR}}/investigations/20_handoff.json`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Validar o handoff consumido como completed de `system_baseline`.
- Usar somente status active, planned ou retired e exigir `repo_key` unica.
- Nao atribuir autoridade pela posicao em TARGET_REPOSITORIES ou `repos.conf`.
- Quando houver mais de um repositorio, validar A,B e B,A e exigir o mesmo resultado canonico.
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" topology "{{CARD_DIR}}/analysis/21_repository_manifest.candidate.yaml" > "{{CARD_DIR}}/analysis/22_topology_validation.json"` e exigir exit 0.
- Depois da validacao, executar `printf '%s' '{"from_phase":"repository_topology","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"`.
- Validar o handoff com `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" handoff "{{CARD_DIR}}/investigations/20_handoff.json" repository_topology completed`.

FORBIDDEN
- Nao selecionar autoridade, criar repositorio, executar operacao Git mutavel ou alterar configuracao.
- Nao inferir monorepo ou multiplos repositorios sem evidencia.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check ou o handoff de entrada falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se houver chave duplicada, status invalido, cenario incoerente, autoridade por indice ou divergencia A,B/B,A.
- Falhar se `contract_tool.py topology` retornar diferente de zero ou receipt sem `valid: true`.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
- Falhar se o handoff de saida nao for compacto, nao contiver `codes` ou falhar no validador local.
