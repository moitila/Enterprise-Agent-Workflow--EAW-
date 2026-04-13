# EAW Architecture (v0.6.0)

Canonical architecture document for EAW.

Conceptual model for onboarding and positioning: `docs/CONCEPTUAL_MODEL.md`.

## Overview

EAW v0.6.0 uses a modular shell architecture that keeps CLI behavior stable while separating internal responsibilities.

Main modules:
- `scripts/eaw`: CLI entrypoint and command dispatcher
- `scripts/eaw_core.sh`: shared execution primitives (including phase execution/logging)
- `scripts/commands/*.sh`: command handlers (`init`, `feature|bug|spike`, `doctor`, `validate`, `intake`, `analyze`, `implement`)
- `scripts/lib.sh`: shared utility functions

The architecture is intentionally contract-first: internal modularization must not change public CLI, artifact names, or output layout.

## Runtime Flow

1. User invokes `./scripts/eaw <subcommand>`.
2. Dispatcher loads core + command modules.
3. Selected command runs deterministic phase steps.
4. Outputs are written to `out/<CARD>/` according to the contract.
5. `out/<CARD>/execution.log` records phase execution (`phase|status|duration_ms|note`).

For full-card orchestration, `./scripts/eaw run <CARD>` adds a run-level control loop on top of the same declarative lifecycle. The command creates `out/<CARD>/runtime/run_state.yaml` and `out/<CARD>/runtime/execution.log`, validates the current card state before iterating, and advances only by delegating to `./scripts/eaw next <CARD>`. The runtime does not use `intake`, `analyze`, or `implement` as internal progression shortcuts.

## Phase Transition Semantics

- `current_phase` is the declarative workflow position persisted in card state.
- `track.transitions` defines the next valid state transition for the current phase.
- `./scripts/eaw next <CARD>` updates workflow state and executes the destination phase in a phase-driven way using the phase YAML outputs and runtime prompt bindings.
- `./scripts/eaw run <CARD>` re-reads `card_state`, checks whether the current phase already equals `final_phase`, and otherwise calls `./scripts/eaw next <CARD>` as the only forward-progress primitive.
- `./scripts/eaw run <CARD>` persists `run_state.yaml` fields such as `attempt`, `status`, `track_id`, `current_phase`, `phase_status`, and `stop_reason`, and appends run-level audit lines to `runtime/execution.log`.
- Named run termination states are part of the observed runtime behavior: `COMPLETED`, `TRACK_CONSISTENCY_ERROR`, `CARD_STATE_INVALID`, `NO_FORWARD_PROGRESS`, and `PHASE_EXECUTION_FAILED`.
- Prompt-oriented commands such as `intake`, `analyze`, and `implement` remain the deprecated compatibility surface that materializes the aggregated prompt flow for the same lifecycle during the transition to the phase-driven model, with planned removal in `v1.0`.
- In the current runtime model, phase completion is validated through the phase `completion` contract when `next` runs; the architecture does not rely on a separate public `complete` CLI command.
- The current phase-driven executor is incremental: it scaffolds declared outputs, materializes any `phase.outputs.prompts` entries under `out/<CARD>/prompts/` using the declared alias as the filename, emits compatibility prompt artifacts for built-in prompt phases, and records execution in `execution.log`.

## Deterministic Output Boundaries

Public output surface:
- dossier: `out/<CARD>/<type>_<CARD>.md` (deterministic compatibility filename; primary workflow classification remains `track` / `card_state.track_id`)
- staged investigations: `out/<CARD>/investigations/*.md`
- contextual evidence: `out/<CARD>/context/dynamic/` with runtime-selected artifacts and snippets materialized per card
- phase telemetry: `out/<CARD>/execution.log`
- run telemetry: `out/<CARD>/runtime/run_state.yaml` and `out/<CARD>/runtime/execution.log`

Compatibility rule:
- Internal file/module reorganizations are allowed.
- Public contract and CLI are unchanged.

## Operational Constraints

- `repos.conf` defines repositories and roles (`target`/`infra`).
- Only `target` repos are collected under `context/dynamic/` when the phase declares dynamic context materialization.
- Best-effort collector failures are logged in `_warnings.txt` and do not fail the full run by default.
- Fatal errors remain explicit and non-zero.

## Coringas Creative Pipeline

The Coringas backlog is a design-time specialization of the generic EAW workflow. It canonizes the creative pipeline at the documentation layer only; it does not add runtime logic or modify the active runtime root.

The core separation is:

- `track` defines the workflow flow.
- `prompt` defines the phase task and its prompt binding.
- `skill` defines the semantic behavior expected from the isolated agent.

Canonical Coringas track sequence:

1. `creative_ideation`
2. `world_definition`
3. `production_design`
4. `script_finalization`

The design-time gate is intentionally ordered:

- `A0` canonizes architecture, prompt governance, and the creative skill contracts.
- `A1`, `A2`, and `A3` materialize `EAW_creative_research`, `EAW_creative_prompting`, and `EAW_creative_governance`.
- `creative_ideation` runs first as the pilot track.
- `world_definition`, `production_design`, and `script_finalization` only expand after the pilot proves the contract.

The Coringas handoff surface is bounded and replay-safe:

- research brief
- ideation selection memo
- world definition brief
- production design brief
- final script packet

The pipeline remains contract-first:

- no runtime changes in the active runtime root
- no track implementation before skill contracts exist
- no prompt expansion that bypasses the documented handoff surface
- no write paths outside the active target repositories for this backlog

## Testable Architecture Invariants

- CLI interface remains stable (`./scripts/eaw <subcommand>`).
- `run_phase` behavior remains stable via `tests/run_phase_smoke.sh`.
- Output structure remains deterministic via `tests/smoke.sh` and `tests/golden_structure_check.sh`.
