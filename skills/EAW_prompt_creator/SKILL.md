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

## Workflow

1. Identify the target:
   - new track
   - new phase
   - prompt revision
   - transition review

2. Identify the semantic role:
   - `intake`
   - `analysis`
   - `hypothesis`
   - `planning`
   - `implementation_planning`
   - `implementation`
   - `validation`
   - `reporting`

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
- When reviewing a phase that depends on context, require explicit alignment with the runtime context contract:
  - `phase.context.onboarding_template` selects stable repository context
  - `phase.context.dynamic_context_template` selects operational context generated from the card
  - both are runtime-governed and must be reflected in the prompt as materialized artifacts, not informal assumptions
- Prefer phase prompts that are explicit about artifacts, validation, and fail-fast behavior.
- For onboarding tracks, start from repository identity and output reusable repository understanding artifacts.

## Fast Checklist

Before finalizing any prompt or phase, confirm:

- the `phase_role` is explicit
- outputs are inside `write_scope`
- validation is executable
- forbidden actions match the phase role
- transition dependencies are covered by prior outputs
- the prompt can be reviewed without relying on informal context
- if context is required, `phase.context.*` is explicit and the prompt names the expected materialization under `out/<CARD>/context/onboarding/` and/or `out/<CARD>/context/dynamic/`
