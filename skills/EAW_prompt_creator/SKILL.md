---
name: eaw-prompt-creator
description: Create or review EAW track phases, prompts, and transitions using contract-first rules. Use when defining a new EAW track, writing a phase prompt, revising prompt contracts, or checking whether transitions between phases are structurally valid.
---

# EAW Prompt Creator

Use this skill when the task is to create or review prompts, phases, or tracks for the EAW.

This skill is for EAW contract design, not for executing a card.

## What This Skill Produces

- new phase prompt drafts for the EAW
- revisions to existing phase prompts
- track and phase contract reviews
- transition reviews between phases
- onboarding-oriented prompts for new repository tracks

## Core Rule

Do not treat phase names as the source of truth.

Always reason from:

- `phase_role`
- `phase.context.dynamic_context_template`
- `phase.context.onboarding_template`
- required artifacts
- `read_scope`
- `write_scope`
- outputs
- validation
- transition contract

## Semantic Phase Roles

Identifique o papel semântico antes de escrever qualquer prompt:

- `intake` — coleta estruturada do problema/objetivo do card
- `ingest` — ingesta de fontes externas (tickets, PR, logs); equivalente a intake em tracks com origens externas
- `dynamic_context` — materializa `context/dynamic/` de forma governada antes de `findings`; contrato `deterministic_baseline_v1`
- `analysis` / `findings` — investigação e coleta de evidências
- `hypothesis` — formula e prioriza hipóteses
- `planning` — plano de ação antes da implementação
- `implementation_planning` — produz `00_scope.lock.md` e `10_change_plan.md`
- `implementation` / `implementation_executor` — execução do plano; escrita de código
- `validation` — valida artefatos produzidos sem escrever código novo
- `reporting` / `refine` — consolida e publica artefatos operacionais

## Standard Prompt Structure

Todo prompt EAW começa com `{{RUNTIME_ENVIRONMENT}}` como primeira linha. Este placeholder é substituido pelo runtime com o bloco completo de contexto de execução (CARD_ID, TRACK_ID, STEP_ID, WRITE_ALLOWLIST, TARGET_REPOSITORIES, etc.).

Estrutura mínima de um prompt:

```
{{RUNTIME_ENVIRONMENT}}

ROLE
- <papel do agente>

OBJECTIVE
- <objetivo da fase>

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- ...
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/<artefato_obrigatorio>

OUTPUT
- Escrever somente: {{CARD_DIR}}/<artefato_saida>

OUTPUT_STRUCTURE
- <estrutura do artefato de saida>

READ_SCOPE
- <o que pode ser lido>

WRITE_SCOPE
- Escrever somente em: {{CARD_DIR}}/<diretorio>

RULES
- Executar o pre-check: cd "{{RUNTIME_ROOT}}", test -f ./scripts/eaw, ...
- <regras operacionais>

FORBIDDEN
- <acoes proibidas>

FAIL_CONDITIONS
- Falhar se pre-check falhar.
- Falhar se artefato de saida nao existir ao final.
```

## Prompt Versioning Contract (ACTIVE + .meta)

Cada prompt tem três arquivos associados em `templates/prompts/<track>/<phase>/`:

| Arquivo | Propósito |
|---------|----------|
| `prompt_vN.md` | Conteúdo do prompt (versão N) |
| `prompt_vN.meta` | Metadados: version, required_sections, required_substrings, forbidden_words |
| `ACTIVE` | Contém apenas o número `N` da versão ativa |

Quando criar um novo prompt:
1. Criar `prompt_v1.md` com o conteúdo
2. Criar `prompt_v1.meta` com metadados mínimos
3. Criar `ACTIVE` contendo apenas `1`

Quando revisar (nova versão):
1. Criar `prompt_v(N+1).md` com o novo conteúdo
2. Criar `prompt_v(N+1).meta`
3. Atualizar `ACTIVE` para `N+1` (usar `eaw apply-prompt <TRACK> <PHASE> v<N+1>`)

Nunca editar um `prompt_vN.md` já existente — criar nova versão.

## Handoff Contract (20_handoff.json)

Quando uma fase precisa emitir codes para o mecanismo `skip_when`, o prompt deve instruir explicitamente:

```
Emitir {{CARD_DIR}}/investigations/20_handoff.json ao final, SEMPRE, com schema compacto:
- Se <condição>: {"from_phase":"<phase_id>","status":"completed","messages":[],"codes":["CODIGO"]}
- Senão:         {"from_phase":"<phase_id>","status":"completed","messages":[],"codes":[]}
```

Regras do schema:
- Formato compacto obrigatório: sem espaços após `:` e `,`
- Campos obrigatórios: `from_phase`, `status`, `messages`, `codes`
- `codes` é array; quando vazio usar `[]`, nunca omitir
- O runtime lê o arquivo via grep regex — JSON formatado/pretty-printed falha
- Escrever via `printf` ou similar, nunca via editor que adicione whitespace

O prompt deve declarar `20_handoff.json` em:
- `OUTPUT` — como artefato de saída
- `WRITE_SCOPE` — como destino autorizado
- `FAIL_CONDITIONS` — falhar se ausente ou sem campo `codes`

## Context Declaration

Quando a fase depende de contexto materializado:

- `onboarding_template` → contexto estável em `out/<CARD>/context/onboarding/`
- `dynamic_context_template: deterministic_baseline_v1` → contexto operacional em `out/<CARD>/context/dynamic/`

No prompt, tratar contexto como artefato observável e materializado, nunca como conhecimento ambiente. Nomear o path esperado explicitamente.

Após EAW-ARCH-CONTEXT-PATH-REF: em tracks com `dynamic_context_template`, referenciar contexto via path-reference no prompt (não via `{{CONTEXT_BLOCK}}` inline).

## Workflow

1. Identify the target:
   - new track
   - new phase
   - prompt revision
   - transition review

2. Identify the semantic role:
   - `intake`
   - `ingest`
   - `dynamic_context`
   - `analysis` / `findings`
   - `hypothesis`
   - `planning`
   - `implementation_planning`
   - `implementation` / `implementation_executor`
   - `validation`
   - `reporting` / `refine`

3. Resolve context from the active environment before drafting:
   - treat `WORKDIR`, `EAW_WORKDIR`, runtime root, and related values as execution-time values provided or resolved by the active runtime
   - derive the runtime root from the current execution environment, not from a hardcoded path
   - treat `repos.conf` from the active workspace/runtime as the source of truth
   - if the user pointed to working notes or design docs, read those explicit files
   - if the runtime repository has official docs for workflow/prompt contract, read them from the current runtime root

4. Draft or review the phase using the minimum contract:
   - `phase_id`
   - `phase_name`
   - `phase_role`
   - `phase.context.dynamic_context_template` when the phase depends on operational context materialized by the runtime
   - `phase.context.onboarding_template` when the phase depends on stable repository context
   - `objective`
   - `inputs`
   - `required_artifacts`
   - `read_scope`
   - `write_scope`
   - `outputs`
   - `validation`
   - `forbidden`
   - `fail_conditions`
   - `handoff_to`

5. Check the prompt against the semantic obligations of the chosen `phase_role`.

6. Check whether the next phase can operate from outputs and contract alone, without depending on the previous phase name.

7. When a phase declares runtime context, verify the prompt treats context as observable, materialized input:
   - `onboarding` is stable repository context materialized under `out/<CARD>/context/onboarding/`
   - `dynamic_context` is operational context derived from the card and materialized under `out/<CARD>/context/dynamic/`
   - never describe either context source as implicit, ambient, or assumed
   - never ask a phase to inject context that has not been materialized yet

## Output Style

When creating a phase or prompt, produce:

- a short explanation of the role of the phase
- the proposed phase contract
- the prompt text or prompt sections
- explicit transition assumptions
- a short review of risks or missing contract items

When reviewing, produce:

- `APROVADO`, `APROVADO_COM_RESTRICOES`, or `BLOQUEADO`
- critical contract failures first
- warnings second
- objective fixes last

## Guardrails

- never rely on the phase name alone
- never create a phase without `phase_role`
- never leave `write_scope` open-ended
- never define validation that depends on subjective judgment
- never let the next phase require an artifact not produced earlier
- never mix planning and implementation unless the contract explicitly allows it
- never expand repo access without declaring it in contract
- never leave `phase.context.*` implicit when the runtime behavior depends on onboarding or dynamic context
- never treat onboarding and `dynamic_context` as the same surface
- never reference context as available unless its materialization path under `out/<CARD>/context/` is explicit and auditable

## EAW-Specific Notes

- The runtime remains sovereign for `RUNTIME_ROOT`, `repos.conf`, `EAW_WORKDIR`, `next`, and state progression.
- This skill governs prompt and contract quality, not runtime execution.
- Treat `WORKDIR`, `EAW_WORKDIR`, `RUNTIME_ROOT`, and similar values as execution-time context, never as constants.
- Never hardcode workspace-specific paths, repository aliases, or runtime variable values.
- Always resolve track, templates, docs, and repos from the active runtime and current workspace.
- Todo prompt deve começar com `{{RUNTIME_ENVIRONMENT}}` como primeira linha.
- `eaw_workspace` é sempre incluída implicitamente pelo runtime no agent_bundle — nunca declarar em `phase.skills`.
- Skills em `phase.skills` devem refletir o papel real do agente da fase: `eaw_card_execution` só para fases orquestradoras.
- When reviewing a phase that depends on context, require explicit alignment with the runtime context contract:
  - `phase.context.onboarding_template` selects stable repository context
  - `phase.context.dynamic_context_template: deterministic_baseline_v1` selects operational context generated from the card
  - both are runtime-governed and must be reflected in the prompt as materialized artifacts, not informal assumptions
- Prefer phase prompts that are explicit about artifacts, validation, and fail-fast behavior.
- For onboarding tracks, start from repository identity and output reusable repository understanding artifacts.

## Fast Checklist

Before finalizing any prompt or phase, confirm:

- começa com `{{RUNTIME_ENVIRONMENT}}` como primeira linha
- the `phase_role` is explicit
- outputs are inside `write_scope`
- validation is executable
- forbidden actions match the phase role
- transition dependencies are covered by prior outputs
- the prompt can be reviewed without relying on informal context
- if context is required, `phase.context.*` is explicit and the prompt names the expected materialization under `out/<CARD>/context/onboarding/` and/or `out/<CARD>/context/dynamic/`
- se a fase emite codes para `skip_when`: `20_handoff.json` está em OUTPUT, WRITE_SCOPE e FAIL_CONDITIONS
- `eaw_workspace` não está declarada em `phase.skills` (implícita)
- `ACTIVE` e `.meta` criados junto com o prompt
