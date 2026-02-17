# Relatório de Diff — EAWTASI_merged vs EAW_TS

Data: 2026-02-17

## Comparação

- Branch atual: EAWTASI_merged
- HEAD: 68af1eb
- Base: clean/EAW_TS (b8f53c4)
- Range: clean/EAW_TS..HEAD

## Resumo

- 3 arquivos alterados
- 76 inserções
- 4 deleções

## Arquivos impactados

- M .gitignore
- M scripts/eaw
- A scripts/sync-repos-config.sh

## Principais mudanças

### 1) .gitignore
Inclusão de regras para evitar versionamento de configurações locais:

- config/repos.conf
- config/search.conf
- config/*.local.conf

### 2) scripts/eaw
Ajuste em `cmd_init()` para:

- tentar executar scripts/sync-repos-config.sh;
- aplicar fallback legado quando o script não existir;
- manter criação de search.conf quando necessário;
- exibir mensagens finais de inicialização.

### 3) scripts/sync-repos-config.sh
Novo script para gerar/sincronizar config/repos.conf com prioridade:

1. repos.local.conf
2. variáveis de ambiente (FW_PREFIX, BEFW_HOME, BE_HOME, TS_PREFIX)
3. fallback para repos.example.conf

## Estatística (git diff --stat)

```text
 .gitignore                   |  5 ++++
 scripts/eaw                  | 19 +++++++++++----
 scripts/sync-repos-config.sh | 56 ++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 76 insertions(+), 4 deletions(-)
```
