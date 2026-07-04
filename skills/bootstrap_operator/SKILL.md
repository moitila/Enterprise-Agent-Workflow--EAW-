# SKILL: bootstrap_operator

## Objetivo

Guiar o agente executor nas fases da track `bootstrap` do EAW. Cobre os comportamentos
operacionais específicos para inicialização de workspaces EAW do zero.

## Contexto de uso

Esta skill é declarada nas fases da track `bootstrap`. O agente executor deve aplicá-la
ao executar qualquer fase dessa track. É complementar à skill `workspace` (workspace.md),
que permanece obrigatória em toda execução EAW.

## Comportamentos por fase

### init_workspace
- Executar `eaw init --workdir <path>` com o path configurado pelo executor
- Confirmar criação de `<path>/config/`, `<path>/out/`, `<path>/templates/`
- Registrar path efetivo e resultado do comando no artefato `bootstrap/init_workspace_report.md`
- `eaw init` é idempotente — safe to re-run

### configure_env
- Instruir `export EAW_WORKDIR=<path>` no shell ativo
- **Gate obrigatório**: `echo $EAW_WORKDIR` deve retornar o path configurado (instrução de prompt, H2)
- Persistir em `~/.bashrc` ou `~/.zshrc` conforme shell do executor
- Registrar path persistido e saída do gate no artefato `bootstrap/configure_env_report.md`
- NÃO modificar `scripts/` ou qualquer arquivo de runtime EAW

### configure_repos
- Editar `$EAW_WORKDIR/config/repos.conf`
- Formato de cada linha: `<name>|<absolute-path>|<role>` onde role é `target` ou `infra`
- Validar que cada path existe como diretório antes de registrar
- Registrar entradas adicionadas no artefato `bootstrap/configure_repos_report.md`

### validate_repos
- Para cada repo em `repos.conf`: executar `git -C <path> rev-parse --is-inside-work-tree`
- Validação é **instrução de prompt/shell** — NÃO modificar `cmd_validate.sh` (H3)
- Falha em qualquer repo → registrar no artefato, NÃO prosseguir para próxima fase
- Registrar resultado por repo (OK / FAIL) em `bootstrap/validate_repos_report.md`

### validate_env
- Executar `eaw validate` e capturar saída completa
- Executar `eaw doctor` e capturar saída completa
- Confirmar ausência de erros críticos (warnings são aceitáveis)
- Registrar saídas e conclusão em `bootstrap/validate_env_report.md`

## Limites absolutos

- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`
- NÃO escrever fora da allowlist declarada em `implementation/00_scope.lock.md`
- NÃO assumir papel de repo por nome; sempre consultar `repos.conf`
- NÃO executar múltiplas fases em paralelo
