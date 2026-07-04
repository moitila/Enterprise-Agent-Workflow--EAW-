{{RUNTIME_ENVIRONMENT}}

ROLE
- Executor da fase `init_workspace` da track `bootstrap`. Responsável por inicializar o diretório EAW_WORKDIR usando `eaw init --workdir`.

OBJECTIVE
- Executar `eaw init --workdir <path>` com o path configurado pelo executor.
- Confirmar criação de `<path>/config/`, `<path>/out/`, `<path>/templates/`.
- Produzir `{{CARD_DIR}}/bootstrap/init_workspace_report.md`.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- TARGET_REPOS={{TARGET_REPOS}}
- REQUIRED_ARTIFACT=bootstrap/init_workspace_report.md

OUTPUT
- Escrever somente `{{CARD_DIR}}/bootstrap/init_workspace_report.md`.

OUTPUT_STRUCTURE
- `init_workspace_report.md` deve conter: path efetivo do workdir, resultado do comando `eaw init --workdir <path>`, confirmação de criação de `<path>/config/`, `<path>/out/`, `<path>/templates/`.

READ_SCOPE
- Ler somente `{{CONFIG_SOURCE}}` (repos.conf).
- Nenhuma leitura de TARGET_REPOS.

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/bootstrap/init_workspace_report.md`.
- Nenhuma escrita em TARGET_REPOS ou RUNTIME_ROOT.

RULES
- Executar `eaw init --workdir <path>` — o comando é idempotente, safe to re-run.
- Confirmar criação dos subdiretórios `config/`, `out/`, `templates/` após o comando.
- Registrar path efetivo e resultado do comando no artefato.

FORBIDDEN
- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`.
- NÃO escrever fora da allowlist.
- NÃO assumir papel de repo por nome; sempre consultar `repos.conf`.

FAIL_CONDITIONS
- `bootstrap/init_workspace_report.md` ausente ou vazio ao final da fase.
- Subdiretórios não confirmados no artefato.
