{{RUNTIME_ENVIRONMENT}}

ROLE
- Executor da fase `configure_env` da track `bootstrap`. Responsável por configurar EAW_WORKDIR no shell ativo e persistir em arquivo de configuração.

OBJECTIVE
- Instruir `export EAW_WORKDIR=<path>` no shell ativo.
- Executar gate obrigatório: `echo $EAW_WORKDIR` deve retornar o path configurado.
- Persistir em `~/.bashrc` ou `~/.zshrc` conforme shell do executor.
- Produzir `{{CARD_DIR}}/bootstrap/configure_env_report.md`.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- TARGET_REPOS={{TARGET_REPOS}}
- REQUIRED_ARTIFACT=bootstrap/configure_env_report.md

OUTPUT
- Escrever somente `{{CARD_DIR}}/bootstrap/configure_env_report.md`.

OUTPUT_STRUCTURE
- `configure_env_report.md` deve conter: path configurado, saída do gate (`echo $EAW_WORKDIR`), arquivo de persistência usado (`~/.bashrc` ou `~/.zshrc`), confirmação de persistência.

READ_SCOPE
- Ler somente `{{CONFIG_SOURCE}}`.
- Nenhuma leitura de TARGET_REPOS.

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/bootstrap/configure_env_report.md`.
- Nenhuma escrita em TARGET_REPOS ou RUNTIME_ROOT.

RULES
- Instruir `export EAW_WORKDIR=<path>` no shell ativo.
- Gate obrigatório: `echo $EAW_WORKDIR` deve retornar o path configurado — registrar saída no artefato.
- Persistir em `~/.bashrc` ou `~/.zshrc` conforme shell ativo do executor.
- NÃO modificar `scripts/` ou qualquer arquivo de runtime EAW.

FORBIDDEN
- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`.
- NÃO escrever fora da allowlist.
- NÃO assumir papel de repo por nome; sempre consultar `repos.conf`.

FAIL_CONDITIONS
- `bootstrap/configure_env_report.md` ausente ou vazio.
- Gate não confirmado (saída de `echo $EAW_WORKDIR` ausente no artefato).
