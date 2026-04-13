# EAW Conceptual Model

## Purpose

This document explains the mental model of EAW without replacing the formal contracts.
Use it to understand what the system is, what each documentation layer is for, and how the runtime behavior maps to the product narrative.

## What Problem EAW Solves

AI is useful in engineering, but ungoverned use creates drift, weak traceability, and unsafe changes in complex systems.

EAW exists to make AI-assisted engineering auditable and repeatable by card. Instead of treating a request as an open-ended conversation, EAW turns it into a governed flow with explicit state, bounded prompts, context collection, and deterministic output artifacts.

## What EAW Is

EAW is a deterministic AI-assisted engineering system with these core layers:

1. Philosophy
   Defined by `docs/manifesto.md`.
   This layer explains why EAW exists, the risk model behind it, and the principles of work-type differentiation, context engineering, and deterministic outputs.

2. Conceptual system model
   Defined by this document.
   This layer explains how to think about EAW as a whole: a system that governs work by card through `track`, `phase`, card state, prompts, context, and artifacts.

3. Runtime and contracts
   Defined by `docs/ARCHITECTURE.md`, `docs/CONTRACT.md`, `docs/WORKFLOW_YAML_CONTRACT.md`, and `docs/PHASE_CONTRACT_ENGINEERING.md`.
   This layer specifies how the runtime behaves, what artifacts it produces, and what invariants must remain stable.

4. Prompt governance
   Defined by `docs/PROMPT_GOVERNANCE.md` and the prompt contracts.
   This layer explains how prompts are versioned, selected by `ACTIVE`, and recorded through provenance.

5. Operational card flow
   Observed through the CLI and artifacts under `out/<CARD>/`.
   This layer is how the system is used in practice: create card, gather intake, analyze, plan, implement, validate, and preserve evidence.

## What EAW Is Not

EAW is not only:

- a prompt wrapper
- a bash script collection
- a document generator
- an autonomous coding agent

Those elements can exist inside the repository, but they are implementation details or supporting mechanisms.
The system itself is the governed combination of workflow state, contracts, prompt binding, context engineering, and auditable execution.

## Core Objects

### Card

A card is the unit of governed work.
It carries a business identifier and accumulates state, evidence, prompts, and artifacts under `out/<CARD>/`.

### Track

A track is the primary workflow classification.
The runtime persists it in `card_state.track_id` and resolves the official workflow from `tracks/<track>/track.yaml`.

### Phase

A phase is a controlled stage in the workflow.
Examples include intake, findings, hypotheses, planning, implementation planning, and implementation execution.

### Card State

Card state captures where the card is in the workflow.
The current runtime uses fields such as `card_state.track_id` and `card_state.current_phase` to make progression explicit and auditable.

### Prompt Binding

Each governed phase resolves its effective prompt through `templates/prompts/<track>/<phase>/ACTIVE`.
This makes prompt selection observable and versioned instead of implicit.

### Context

The canonical context model is documented in `docs/CONTEXT_MODEL.md`.
That contract distinguishes workspace-sourced `onboarding` context from phase-derived `dynamic_context`.
`onboarding` is maintained outside the target repository and consumed by EAW; `dynamic_context` is runtime-sourced and may vary by phase.
When context is materialized, `dynamic_context` is collected under `out/<CARD>/context/dynamic/` to keep AI inputs bounded and reviewable. `onboarding` is consumed by reference from the workspace source via the context block; it is not materialized per card.
Templates are versioned independently under `templates/context/<type>/<template_name>/` and rendered without redefining the origin of the context.
Both remain separate from prompt rendering concerns and from `tooling_hints`.

### Artifacts

Artifacts are deterministic files written under `out/<CARD>/`.
They include investigation documents, implementation planning files, prompt artifacts, test plans, provenance, and execution logs.

## How The Layers Fit Together

- The manifesto explains why rigor is necessary.
- The conceptual model explains how to think about the system.
- The architecture explains how the runtime is built.
- The contracts explain what must stay stable.
- Prompt governance explains how prompt execution is controlled.
- The CLI and `out/<CARD>/` show the model operating on a real card.

### Coringas Creative Specialization

The Coringas pipeline is a specialization of the generic EAW card flow. It keeps the same governed model, but adds semantic boundaries for creative work so the team can scale prompts and tracks without turning them into a single undifferentiated blob.

For this backlog, the distinction is:

- `track` decides the flow of work.
- `prompt` decides the task of a phase.
- `skill` decides the creative behavior expected from the agent that executes that phase.

The three creative skills split responsibility cleanly:

- `EAW_creative_research` collects references, symbols, cultural notes, and anti-cliche evidence.
- `EAW_creative_prompting` decides how to ask for exploration, comparison, consolidation, or validation.
- `EAW_creative_governance` keeps handoffs bounded and prevents one track from silently taking over another track's responsibility.

The pipeline is intentionally staged:

1. First canonize the architecture and the skill contracts.
2. Then run `creative_ideation` as a pilot.
3. Only after the pilot is stable, expand to `world_definition`, `production_design`, and `script_finalization`.

This preserves the core EAW property: a workflow is only useful when its semantics remain auditable and replay-safe.

## How To Read The Repo

If you are new to EAW, use this sequence:

1. `docs/manifesto.md`
2. `docs/CONCEPTUAL_MODEL.md`
3. `README.md`
4. `docs/ARCHITECTURE.md`
5. `docs/WORKFLOW_YAML_CONTRACT.md`
6. `docs/PROMPT_GOVERNANCE.md`
7. `docs/CONTRACT.md`

## Product Positioning

EAW should be described as a governed AI-assisted engineering system, implemented today as a deterministic shell-based runtime with formal documentation and output contracts.

That wording matters:

- `governed` highlights bounded execution and auditability
- `AI-assisted engineering` reflects the role of prompts and context engineering
- `system` reflects the combination of runtime, contracts, state, and governance
- `shell-based runtime` is an implementation choice, not the whole product identity

## Boundary

This document does not change CLI semantics, artifact contracts, workflow YAML contracts, or prompt governance.
It exists only to clarify the mental model and keep onboarding aligned with the implemented system.

## Incremental Context Migration

The canonical contract remains in `docs/CONTEXT_MODEL.md`.
This section explains how to adopt that contract incrementally, with examples described as copiaveis diretamente so teams can migrate without redefining semantics.

### Checklist de migracao

Use this checklist de migracao in order:

1. Validate that the current track still works sem contexto adicional.
2. Add `dynamic_context` to one phase only and keep the scope narrow.
3. Run `./scripts/eaw smoke` before expanding to another phase.
4. Verify `out/<CARD>/context/dynamic/` and confirm the materialized evidence is readable.
5. Add onboarding only when stable repository knowledge is repeatedly needed.
6. Expand phase por phase after the previous step is stable and auditable.
7. Keep the rollout reversivel; removing the new `context` block must restore the previous baseline.

### Track por track, fase por fase

- `feature`: start with `findings`, because the runtime already uses `dynamic_context_template: deterministic_baseline_v1` there; expand to `planning` only after smoke validation.
- `bug`: start sem bootstrap and add `dynamic_context` only to the first phase where evidence selection is needed; keep onboarding optional until repeated repository knowledge becomes a real constraint.
- `standard`: begin with one operational phase, validate the materialized `CONTEXT` blocks, then extend phase por phase instead of changing the whole track at once.
- `spike`: keep the smallest context surface possible; prefer dynamic evidence selection first and postpone onboarding unless the exploratory work repeats the same repository facts.
- `ARCH_REFACTOR`: consider `context_bootstrap` only when the refactor needs an explicit first checkpoint for provenance and deterministic context materialization.

### Example complete `phase.yaml` with `context`

This example is copiavel diretamente for a first migration sem bootstrap:

```yaml
id: findings
description: Investigate the current card with bounded evidence.
context:
  dynamic_context_template: deterministic_baseline_v1
  onboarding_template: repo_discovery
tooling_hints:
  execution_mode: deterministic
outputs:
  artifacts:
    - investigations/20_findings.md
```

Expected verification after `./scripts/eaw next 589`:

- inspect `out/589/context/dynamic/00_scope_manifest.md`
- inspect `out/589/context/dynamic/20_candidate_files.txt`
- inspect `out/589/context/dynamic/30_target_snippets.md`
- confirm the generated prompt shows `CONTEXT - DYNAMIC`

### Example of incremental adoption sem bootstrap

Use this path when you want the smallest reversible change:

1. Keep the current track as-is.
2. Add the `context` block to a single phase such as `findings`.
3. Run `./scripts/eaw next 589`.
4. Check `out/589/context/dynamic/` and confirm the prompt contains `CONTEXT - DYNAMIC`.
5. Run `./scripts/eaw smoke`.

### Example of incremental adoption with bootstrap opcional

Use this path when the team wants an explicit first pass for context artifacts:

1. Add a bootstrap opcional step before the phase that depends on the new context.
2. Materialize onboarding if a stable source exists under `context_sources/onboarding/<repo_key>/`.
3. Run `./scripts/eaw next 589`.
4. Check `out/589/context/dynamic/00_scope_manifest.md` and confirm the onboarding context block was injected via reference.
5. Run `./scripts/eaw smoke` before expanding the rollout.

The bootstrap path is still incremental: first verify determinism and provenance, then expand track por track and fase por fase.
