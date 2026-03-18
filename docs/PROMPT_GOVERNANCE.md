# PROMPT_GOVERNANCE

## Overview
Este documento centraliza a arquitetura de Prompt Governance do EAW, consolidando as regras e componentes implementados na trilha atual.
O objetivo é consolidar regras e componentes já implementados em um único artefato auditável.

## Prompt Governance Goals
- Determinismo na seleção de prompts por fase.
- Auditabilidade da resolução e do prompt efetivamente usado.
- Rastreabilidade entre contrato documental e comportamento observado.
- Reprodutibilidade de execuções por versão ativa de prompt.

## Prompt Contract
O contrato de prompts estabelece a estrutura esperada por fase e seu uso operacional.
Elementos concretos no repositório:
- `templates/prompts/default/<phase>/prompt_vN.md`
- `templates/prompts/default/<phase>/prompt_vN.meta`
- `templates/prompts/default/<phase>/ACTIVE`
- `scripts/commands/cmd_validate_prompt.sh`
O Prompt Contract Engine valida a estrutura e consistência dos prompts antes de sua utilização operacional.

## Prompt Versioning
O versionamento usa candidatos `prompt_vN.md` por fase.
O binding operacional atual é definido por `ACTIVE` em cada diretório de fase.
A resolução operacional seleciona o arquivo `prompt_v{ACTIVE}.md`.
Referências concretas:
- `templates/prompts/default/intake/ACTIVE`
- `templates/prompts/default/analyze_findings/ACTIVE`
- `templates/prompts/default/analyze_hypotheses/ACTIVE`
- `templates/prompts/default/analyze_planning/ACTIVE`

## Prompt Registry
O arquivo `templates/prompts/registry.yaml` existe como metadata de governança por fase.
Nesta etapa, `registry.yaml` não é fonte de binding em runtime.
A função operacional de binding permanece no `ACTIVE` de cada fase.

## Prompt Loader
O loader utiliza `load_prompt` para resolver o template efetivo por fase.
Referências concretas:
- `scripts/eaw_core.sh` (funções `load_prompt` e `prompt_resolve_active_metadata`)
- `scripts/commands/cmd_intake.sh`
- `scripts/commands/cmd_analyze.sh`
- `scripts/commands/cmd_implement.sh`

## Prompt Provenance
A provenance registra o prompt efetivamente utilizado na execução.
O artefato observado de saída é `out/<CARD>/provenance/prompts_used.yaml`.
A escrita da provenance é acionada no fluxo de resolução de prompt.
Referências concretas:
- `scripts/eaw_core.sh` (função `prompt_provenance_append`)
- `out/<CARD>/provenance/prompts_used.yaml`

## Resolution Flow

Fluxo completo de resolução até provenance:

1. O runtime lê `phase.prompt.path` do YAML da fase (fonte de verdade para track e template).
2. `eaw_prompt_binding_from_path` deriva `track` e `phase` do path declarado.
3. `load_prompt "<track>" "<phase>"` é chamado com os valores derivados.
4. `prompt_resolve_active_metadata` usa `ACTIVE` para determinar `prompt_vN.md` efetivo.
5. O template é renderizado com placeholders do runtime.
6. O artefato de saída é gravado em `out/<CARD>/prompts/<alias>.md` (naming próprio de saída).
7. O sistema registra provenance em `prompts_used.yaml`.

### Prompt Resolution Model

```text
phase.prompt.path (YAML da fase — fonte de verdade)
↓
eaw_prompt_binding_from_path → track + phase
↓
load_prompt(track, phase)
↓
ACTIVE → prompt_vN.md
↓
Render + Write to prompts/{alias}.md
↓
Provenance Log
```

## Architectural Decisions

- `phase.prompt.path` é a fonte de verdade para qual track e template são usados na renderização.
- O nome/path do artefato gerado (`prompts/<alias>.md`) é determinado pelo alias da fase, não pelo path declarado.
- O track nunca é inferido por alias fixo quando `phase.prompt.path` está declarado.
- O fallback para track `default` ocorre apenas quando `phase.prompt.path` está ausente ou indecifrável; nunca silenciosamente.
- `ACTIVE` é o binding operacional de versão dentro de cada track/phase.
- `registry.yaml` não define binding em runtime nesta fase.
- A provenance deve registrar o prompt efetivamente utilizado na execução.

## Sprint Result
Resultado esperado consolidado desta trilha:
- Prompt Governance Layer
- Prompt Contract Engine
- Prompt Registry
- Prompt Loader
- Prompt Provenance
