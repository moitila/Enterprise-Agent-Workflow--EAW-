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

## Phase Transition Semantics

- `current_phase` is the declarative workflow position persisted in card state.
- `track.transitions` defines the next valid state transition for the current phase.
- `./scripts/eaw next <CARD>` updates workflow state and executes the destination phase in a phase-driven way using the phase YAML outputs and runtime prompt bindings.
- Prompt-oriented commands such as `intake`, `analyze`, and `implement` remain the deprecated compatibility surface that materializes the aggregated prompt flow for the same lifecycle during the transition to the phase-driven model, with planned removal in `v1.0`.
- In the current runtime model, phase completion is validated through the phase `completion` contract when `next` runs; the architecture does not rely on a separate public `complete` CLI command.
- The current phase-driven executor is incremental: it scaffolds declared outputs, materializes any `phase.outputs.prompts` entries under `out/<CARD>/prompts/` using the declared alias as the filename, emits compatibility prompt artifacts for built-in prompt phases, and records execution in `execution.log`.

## Deterministic Output Boundaries

Public output surface:
- dossier: `out/<CARD>/<type>_<CARD>.md` (deterministic compatibility filename; primary workflow classification remains `track` / `card_state.track_id`)
- staged investigations: `out/<CARD>/investigations/*.md`
- contextual evidence: `out/<CARD>/context/<repoKey>/...`
- phase telemetry: `out/<CARD>/execution.log`

Compatibility rule:
- Internal file/module reorganizations are allowed.
- Public contract and CLI are unchanged.

## Operational Constraints

- `repos.conf` defines repositories and roles (`target`/`infra`).
- Only `target` repos are collected under `context/`.
- Best-effort collector failures are logged in `_warnings.txt` and do not fail the full run by default.
- Fatal errors remain explicit and non-zero.

## Testable Architecture Invariants

- CLI interface remains stable (`./scripts/eaw <subcommand>`).
- `run_phase` behavior remains stable via `tests/run_phase_smoke.sh`.
- Output structure remains deterministic via `tests/smoke.sh` and `tests/golden_structure_check.sh`.
