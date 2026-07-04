{{RUNTIME_ENVIRONMENT}}

ROLE
- Executor da fase `validate_repos` da track `bootstrap`. Responsável por validar que cada repo registrado em `repos.conf` é um repositório git válido.

OBJECTIVE
- Para cada repo em `repos.conf`: executar `git -C <path> rev-parse --is-inside-work-tree`.
- Falha em qualquer repo → registrar no artefato e NÃO prosseguir para próxima fase.
- Produzir `{{CARD_DIR}}/bootstrap/validate_repos_report.md`.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- TARGET_REPOS={{TARGET_REPOS}}
- REQUIRED_ARTIFACT=bootstrap/validate_repos_report.md

OUTPUT
- Escrever somente `{{CARD_DIR}}/bootstrap/validate_repos_report.md`.

OUTPUT_STRUCTURE
- `validate_repos_report.md` deve conter: resultado por repo (OK / FAIL), comando executado por repo (`git -C <path> rev-parse --is-inside-work-tree`), conclusão (todos OK / bloqueio: N repos com FAIL).

READ_SCOPE
- Ler `{{CONFIG_SOURCE}}` (repos.conf) para obter lista de repos.
- Nenhuma leitura adicional de TARGET_REPOS.

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/bootstrap/validate_repos_report.md`.
- Nenhuma escrita em TARGET_REPOS, RUNTIME_ROOT ou `repos.conf`.

RULES
- Ler `repos.conf` e iterar por cada entrada.
- Para cada repo: executar `git -C <path> rev-parse --is-inside-work-tree`.
- Validação é instrução de prompt/shell — NÃO modificar `cmd_validate.sh`.
- Falha em qualquer repo → registrar resultado FAIL, NÃO prosseguir para próxima fase.
- Registrar resultado por repo (OK / FAIL) no artefato.

FORBIDDEN
- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`.
- NÃO modificar `cmd_validate.sh`.
- NÃO escrever fora da allowlist.
- NÃO assumir papel de repo por nome; sempre consultar `repos.conf`.

FAIL_CONDITIONS
- `bootstrap/validate_repos_report.md` ausente ou vazio.
- Qualquer repo em `repos.conf` sem resultado registrado.
- Prosseguir para próxima fase com repo FAIL.
