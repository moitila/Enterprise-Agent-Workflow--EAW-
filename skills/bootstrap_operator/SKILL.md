# SKILL: bootstrap_operator

## Objetivo

Guiar o agente na inicialização de um workspace EAW do zero, sem exigir card ou EAW_WORKDIR
pré-existentes. Esta skill é executada diretamente pelo agente — o usuário não executa
os passos manualmente.

## Modo de uso

Passe esta skill ao agente junto com o pedido de bootstrap:

> "Bootstrap meu workspace EAW. Skill: `skills/bootstrap_operator/SKILL.md`"

O agente executa os 5 passos em sequência. Nenhum card é necessário.

## Passos (execução direta, sem card)

### 1. init_workspace
- Perguntar ao executor o path desejado para o workdir
- Executar `eaw init --workdir <path>` a partir do RUNTIME_ROOT
- Confirmar criação de `<path>/config/`, `<path>/out/`, `<path>/templates/`
- `eaw init` é idempotente — seguro re-executar
- Reportar path efetivo e resultado ao executor

### 2. configure_env
- Executar `export EAW_WORKDIR=<path>` no shell ativo
- **Gate obrigatório**: `echo $EAW_WORKDIR` deve retornar o path — confirmar antes de prosseguir
- Persistir em `~/.bashrc` ou `~/.zshrc` conforme shell do executor
- Windows/PowerShell: `$env:EAW_WORKDIR = "<path>"` e persistir via profile
- NÃO modificar `scripts/` ou qualquer arquivo de runtime EAW

### 3. configure_repos
- Editar `$EAW_WORKDIR/config/repos.conf`
- Formato por linha: `<name>|<absolute-path>|<role>` — role é `target` ou `infra`
- Validar `test -d <absolute-path>` para cada entrada antes de registrar
- Path inexistente é bloqueio — não registrar, reportar ao executor

### 4. validate_repos
- Para cada repo em `repos.conf`: `git -C <path> rev-parse --is-inside-work-tree`
- NÃO modificar `cmd_validate.sh` — validação é instrução de shell direta
- Falha em qualquer repo → reportar ao executor, não prosseguir

### 5. validate_env
- Executar `eaw validate` e capturar saída
- Executar `eaw doctor` e capturar saída
- Confirmar ausência de erros críticos (warnings são aceitáveis)
- Reportar conclusão ao executor

## Limites absolutos

- NÃO modificar `scripts/`, `lib.sh`, `eaw_core.sh`, `cmd_*.sh`
- NÃO assumir papel de repo por nome; sempre ler `repos.conf`
- NÃO prosseguir se gate de `echo $EAW_WORKDIR` falhar
- NÃO prosseguir se qualquer repo falhar em `git rev-parse`
