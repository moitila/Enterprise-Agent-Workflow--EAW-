{{RUNTIME_ENVIRONMENT}}

ROLE
- Executor da fase `validate_env` da track `bootstrap`. Responsável por confirmar saúde completa do ambiente EAW.

OBJECTIVE
- Executar `eaw validate` e capturar saída completa.
- Executar `eaw doctor` e capturar saída completa.
- Confirmar ausência de erros críticos (warnings são aceitáveis).
- Produzir `{{CARD_DIR}}/bootstrap/validate_env_report.md`.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- TARGET_REPOS={{TARGET_REPOS}}
- REQUIRED_ARTIFACT=bootstrap/validate_env_report.md

OUTPUT
- Escrever somente `{{CARD_DIR}}/bootstrap/validate_env_report.md`.

OUTPUT_STRUCTURE
- `validate_env_report.md` deve conter: saída completa do `eaw validate`, saída completa do `eaw doctor`, conclusão (erros críticos: nenhum / N encontrados; warnings: N).

READ_SCOPE
- Ler `{{CONFIG_SOURCE}}`.
- Nenhuma leitura de TARGET_REPOS além do declarado.

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/bootstrap/validate_env_report.md`.
- Nenhuma escrita em TARGET_REPOS ou RUNTIME_ROOT.

RULES
- Executar `eaw validate` a partir de RUNTIME_ROOT e capturar saída completa.
- Executar `eaw doctor` a partir de RUNTIME_ROOT e capturar saída completa.
- Confirmar ausência de erros críticos — warnings são aceitáveis.
- Registrar saídas completas e conclusão no artefato.

FORBIDDEN
- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`.
- NÃO escrever fora da allowlist.
- NÃO assumir papel de repo por nome; sempre consultar `repos.conf`.

FAIL_CONDITIONS
- `bootstrap/validate_env_report.md` ausente ou vazio.
- Erros críticos encontrados sem registro no artefato.
- Saídas de `eaw validate` ou `eaw doctor` ausentes no artefato.
