{{RUNTIME_ENVIRONMENT}}

ROLE
- Atuar como fase de reporting `consumption_handoff`, verificando a publicacao e emitindo contrato autocontido para analises posteriores.

OBJECTIVE
- Reler os quatro documentos na revisao publicada da autoridade explicita e provar `candidate_digest == approved_digest == published_digest == consumed_digest`.
- Entregar manifesto e handoff suficientes para o proximo consumidor sem depender da historia informal do card.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- REQUIRED_ARTIFACTS: authority binding/validation, candidate validation, approval request/record/validation, publication request/result/validation e handoff completed de `publication`.
- Revisao publicada e quatro paths declarados no publication result validado.

OUTPUT
- Escrever `{{CARD_DIR}}/consumption/consumption_receipt.json`.
- Escrever `{{CARD_DIR}}/consumption/downstream_manifest.yaml`.
- Escrever `{{CARD_DIR}}/consumption/handoff.md`.
- Escrever `{{CARD_DIR}}/consumption/validation_report.md`.

OUTPUT_STRUCTURE
- `consumption_receipt.json`: `contract_version: 1`, `valid` booleano, `errors`, repo key, revision, lista canonica de paths e os quatro digests nao vazios.
- `downstream_manifest.yaml`: contract version, sistema/escopo, autoridade, revisao, quatro documentos, digest/receipt, repositorios, decisoes vigentes, questoes abertas, limites de confianca e proxima analise recomendada.
- `handoff.md`: contrato de consumo, identidade publicada, evidencias, decisoes vigentes, pendencias e limites local/sequencial.
- `validation_report.md`: comandos, exit codes e evidencia literal da releitura, SHA-256, conjunto de paths e `contract_tool.py consumption`.

READ_SCOPE
- Ler os REQUIRED_ARTIFACTS.
- Resolver o repositorio somente pelo authority binding validado.
- Ler somente os quatro paths permanentes na revisao exata declarada no publication result.
- Ler o contrato e a ferramenta sob `{{RUNTIME_ROOT}}/tracks/system_analysis/`.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/consumption/consumption_receipt.json`.
- Escrever somente `{{CARD_DIR}}/consumption/downstream_manifest.yaml`.
- Escrever somente `{{CARD_DIR}}/consumption/handoff.md`.
- Escrever somente `{{CARD_DIR}}/consumption/validation_report.md`.

RULES
- echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
- cd "{{RUNTIME_ROOT}}"
- test -f ./scripts/eaw
- test -f "{{CONFIG_SOURCE}}"
- Validar o handoff de entrada como completed de `publication` e exigir publication validation `valid: true`.
- Resolver authority binding por repo key e publication root explicitos, nunca pela ordem de targets.
- Reler os quatro paths na revisao publicada, calcular SHA-256 dos bytes e o digest agregado no algoritmo do contrato.
- Exigir os quatro digests nao vazios e identicos e o conjunto exato de paths antes de declarar `valid: true`.
- Executar `python3 "{{RUNTIME_ROOT}}/tracks/system_analysis/tools/contract_tool.py" consumption "{{CARD_DIR}}/consumption/consumption_receipt.json"` e registrar stdout e exit code em `validation_report.md`.
- Declarar explicitamente que a prova e local e sequencial.

FORBIDDEN
- Nao corrigir, republicar, alterar Git, mudar authority binding ou substituir resultado externo.
- Nao alegar garantias sobre remotos, concorrencia, replay distribuido, SIGKILL, branch protection, atomicidade distribuida, autenticacao produtiva ou executor malicioso.
- Nao ler fora de READ_SCOPE nem escrever fora de WRITE_SCOPE.

FAIL_CONDITIONS
- Falhar se o pre-check, handoff de entrada ou publication validation falhar.
- Falhar se qualquer output declarado estiver ausente ou vazio.
- Falhar se repo key, revision, conjunto de paths ou qualquer digest divergir.
- Falhar se `contract_tool.py consumption` retornar diferente de zero ou nao produzir JSON compacto com `valid: true`.
- Falhar se houver referencia operacional em formato shell-style de chave simples nas secoes operacionais.
