{{RUNTIME_ENVIRONMENT}}

ROLE
- Executor da fase `configure_repos` da track `bootstrap`. Responsável por registrar repositórios em `repos.conf`.

OBJECTIVE
- Editar `$EAW_WORKDIR/config/repos.conf`.
- Formato de cada linha: `<name>|<absolute-path>|<role>` onde role é `target` ou `infra`.
- Validar que cada path existe como diretório antes de registrar.
- Produzir `{{CARD_DIR}}/bootstrap/configure_repos_report.md`.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- TARGET_REPOS={{TARGET_REPOS}}
- REQUIRED_ARTIFACT=bootstrap/configure_repos_report.md

OUTPUT
- Escrever em `$EAW_WORKDIR/config/repos.conf`.
- Escrever somente em `{{CARD_DIR}}/bootstrap/configure_repos_report.md`.

OUTPUT_STRUCTURE
- `configure_repos_report.md` deve conter: entradas adicionadas em `repos.conf` (uma por linha, formato `<name>|<absolute-path>|<role>`), resultado da validação de existência de cada path (`test -d <path>` → OK / FAIL).

READ_SCOPE
- Ler `{{CONFIG_SOURCE}}` (repos.conf existente).
- Nenhuma leitura de TARGET_REPOS.

WRITE_SCOPE
- Escrever em `$EAW_WORKDIR/config/repos.conf`.
- Escrever somente em `{{CARD_DIR}}/bootstrap/configure_repos_report.md`.
- Nenhuma escrita em TARGET_REPOS ou RUNTIME_ROOT.

RULES
- Editar `$EAW_WORKDIR/config/repos.conf` com as entradas instruídas pelo executor.
- Formato obrigatório por linha: `<name>|<absolute-path>|<role>` — role deve ser `target` ou `infra`.
- Validar `test -d <absolute-path>` para cada entrada antes de registrar — path inexistente é bloqueio.
- Registrar entradas adicionadas no artefato.

FORBIDDEN
- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`.
- NÃO escrever fora da allowlist exceto `repos.conf`.
- NÃO assumir papel de repo por nome.
- NÃO usar role diferente de `target` ou `infra`.

FAIL_CONDITIONS
- `bootstrap/configure_repos_report.md` ausente ou vazio.
- Qualquer path registrado em `repos.conf` sem validação prévia de existência.
