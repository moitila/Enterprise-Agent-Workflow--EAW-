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

## Operational Skill Surface

O executor do EAW opera com três superfícies ortogonais e independentes ao executar uma fase de agente isolado:

1. **Conteúdo do prompt** — selecionado via `phase.prompt.path` e resolução de `ACTIVE`. Imutável durante a execução da fase.
2. **Contexto injetado** — selecionado via `phase.context` (`dynamic_context_template`, `onboarding_template`). Materializado sob `out/<CARD>/context/` antes da execução.
3. **Skills operacionais** — declaradas via `phase.skills`. Carregadas pelo executor como contexto operacional do agente isolado, externas ao prompt e ao contexto injetado.

**Invariante de governança:** o executor não altera o conteúdo do prompt para incluir ou mencionar nomes de skills. `phase.skills` é ortogonal a `phase.prompt.path` e ao registro `ACTIVE`. A separação entre as três superfícies é absoluta e deve ser preservada em qualquer extensão futura do runtime.

Esta regra é de governança de prompts: skills equipam o agente operacionalmente, mas nunca como texto no prompt. A mecânica completa do ciclo de execução (Modo D) é definida em `docs/ARCHITECTURE.md` (Deterministic Agent Mode).

## RUNTIME_ENVIRONMENT Blocks

O bloco `RUNTIME_ENVIRONMENT` injetado no prompt renderizado contém seções condicionais
determinadas pelo YAML da fase. A ordem canônica das seções é:

```
RUNTIME_ENVIRONMENT

CARD_ID:
TRACK_ID:
STEP_ID:
...
TARGET_REPOSITORIES:
[PHASE_SKILLS: — quando declarado]
[CAPABILITIES_DECLARED: — quando capabilities: não-vazia]
WRITE_ALLOWLIST:
[READ_SOURCES: — quando read_sources: não-vazia]
CRITICAL_PATHS:
```

### WRITE_ALLOWLIST

Sempre presente. Lista os paths absolutos nos quais o agente tem permissão de escrita.
Derivado do `00_scope.lock.md` do card quando disponível, com fallback para a allowlist
calculada pelo runtime. `assert_write_scope` valida cada escrita contra esta lista.

### READ_SOURCES

Presente **somente quando** o campo `read_sources:` no YAML da fase contiver ao menos
um item (lista não-vazia). Omitido quando o campo está ausente ou é `read_sources: []`.

- **Posição**: após o bloco `WRITE_ALLOWLIST:` (incluindo `WRITE_ALLOWLIST_SOURCE` e
  `WRITE_ALLOWLIST_RESOLVED_FROM_SCOPE_LOCK`), imediatamente antes de `CRITICAL_PATHS:`.
- **Formato do bloco**:
  ```
  READ_SOURCES:
  <item1>
  <item2>
  ```
- **Campo YAML de fase correspondente**: `phase.read_sources` (aninhado sob `phase:`, indentação de 2 espaços). Placeholders portáveis com delimitadores duplos são suportados: `{{RUNTIME_ROOT}}`, `{{CARD_DIR}}`, `{{OUT_DIR}}`, `{{EAW_WORKDIR}}`. O runtime resolve cada placeholder para o path absoluto correspondente antes de injetar o bloco READ_SOURCES no prompt. Paths relativos ou placeholders desconhecidos bloqueiam a materialização.
- **Compatibilidade retroativa**: fases sem o campo ou com `read_sources: []` mantêm
  comportamento inalterado — o bloco simplesmente não aparece no prompt.
- **Função extratora**: `eaw_yaml_phase_read_sources` em `scripts/commands/eaw_commands.sh`.
- **Enforcement**: `assert_read_scope <path>` deve ser chamado antes de ler qualquer
  item declarado em `read_sources`.

## CONTEXT_BLOCK

O placeholder CONTEXT_BLOCK em templates de prompt é resolvido pelo runtime em
`eaw_build_phase_context_block` (`scripts/commands/eaw_commands.sh`) antes da
entrega do prompt ao agente. Dois mecanismos de resolução são suportados:

### Mecanismo 1: dynamic_context_template
Declarado em `context.dynamic_context_template` no YAML da fase.
Requer que o track declare a fase `dynamic_context` (que materializa
`context/dynamic/` antes desta fase ser executada).

### Mecanismo 2: onboarding_template
Declarado em `context.onboarding_template` no YAML da fase.
Usado em tracks de onboarding (ex.: ARCH_REFACTOR_ONBOARD, bug_ONBOARD)
que entregam contexto via template de onboarding em vez de fase dedicada.
Não requer fase `dynamic_context` no track.

### Comportamento sem mecanismo declarado
Se a fase não declarar nenhum dos dois mecanismos,
`eaw_apply_context_block_to_prompt` remove o placeholder CONTEXT_BLOCK
(substituído por string vazia). O prompt é entregue sem bloco de contexto.
Incluir CONTEXT_BLOCK em um prompt de fase sem mecanismo declarado resulta
em prompt entregue sem contexto — não em erro de runtime.

### Invariante de CI (INV-03)
INV-03 em `tests/invariants.sh` valida que prompts ativos com CONTEXT_BLOCK
têm ao menos um mecanismo de resolução declarado no YAML da fase correspondente
(`onboarding_template:` ou `dynamic_context_template:`). Um prompt com
CONTEXT_BLOCK e sem mecanismo declarado é considerado configuração inválida.
