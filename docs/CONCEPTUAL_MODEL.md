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
When context is materialized, `onboarding` is collected under `out/<CARD>/context/onboarding/` and `dynamic_context` under `out/<CARD>/context/dynamic/` to keep AI inputs bounded and reviewable.
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
