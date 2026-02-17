# PROJECT STATE — EAW v0.2.0

## Executive Summary

EAW v0.2.0 encerra a fase experimental e estabelece o projeto como uma CLI com governança mínima para uso por terceiros, com isolamento de workspace, contrato de configuração e comandos de diagnóstico.

## Project Context

EAW nasceu como uma CLI determinística para orquestração de fluxo:

- `bug` / `feature` / `spike` -> contexto -> output estruturado

Objetivo: suportar uso multi-repo (ex.: Tasy) sem forçar fork nem acoplamento estrutural ao core.

## Initial Architectural Problem

Antes da v0.2.0, havia:

- Configuração misturada com core
- Ausência de contrato de versão de config
- Risco de fork para customização
- Workspace implícito
- Atualizações sem processo formal

Isso reduzia previsibilidade e dificultava adoção disciplinada.

## Decisions Implemented In v0.2.0

### Workspace Mode

Separação explícita entre:

- Core: repositório EAW
- Workspace do consumidor: `.eaw/`

Variáveis principais:

- `EAW_WORKDIR`
- `EAW_CONFIG_DIR`
- `EAW_TEMPLATES_DIR`
- `EAW_OUT_DIR`

Princípio aplicado: sem fallback silencioso de configuração.

### Config Contract

Introduzido `config_version=1` para evolução controlada de configuração.

### Governance Commands

- `validate` -> valida estrutura de config/paths/templates
- `doctor` -> diagnostica ambiente e modo de execução
- `init --upgrade` -> upgrade assistido e não destrutivo

### Compatibility Policy

Política formal de compatibilidade documentada para SemVer, contrato de output e contrato de workspace.

### CI Quality Gate

`shfmt` como gate de qualidade para scripts shell.

## Current Capabilities

- Workspace mode via `EAW_WORKDIR`
- Separação formal entre core e workspace do consumidor
- Comandos: `init`, `feature`, `bug`, `spike`, `analyze`, `ingest`, `validate`, `doctor`
- `config_version` implementado
- Política de compatibilidade documentada
- Upgrade não destrutivo (`init --upgrade`)
- Quality gate de formatação no CI

## Architectural Guarantees

- Sem fallback híbrido implícito de config em workspace mode
- Path resolution determinístico
- Output isolado por workspace
- Exit codes coerentes nos comandos de diagnóstico
- Configuração externa ao core quando em workspace mode

## Remaining Limitations

- Templates ainda em Markdown livre (sem schema formal)
- Contratos ainda não machine-validated
- Sem sistema de plugin/extensão
- Sem empacotamento versionado (tarball/package)
- Sem suíte automatizada robusta de testes unitários

## Maturity Assessment

EAW deixou de ser:

- Script pessoal
- Experimento local improvisado
- Ferramenta acoplada ao ambiente individual

EAW passou a ser:

- CLI versionada
- Com contrato explícito
- Com isolamento de workspace
- Com governança documentada
- Com pipeline básico de qualidade

Princípios estabelecidos:

- Determinismo > improviso
- Workspace externo ao core
- Sem fallback mágico
- Config versionada
- Upgrade não destrutivo
- Release formal com tag

## Recommended Next Phase

Escolher trilha principal para v0.3.x:

1. Formalização de contratos com schema
2. Aplicação real em projeto OSS (prova pública)
3. Evolução para modelo extensível
4. Ampliação de automação de testes

## Conclusion

v0.2.0 marca o fim da fase experimental. A partir deste ponto, EAW está posicionado como ferramenta utilizável por terceiros com risco reduzido de quebra estrutural.
