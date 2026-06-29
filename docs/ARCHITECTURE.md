# EAW Architecture (v0.6.0)

Canonical architecture document for EAW.

Conceptual model for onboarding and positioning: `docs/CONCEPTUAL_MODEL.md`.

## Overview

EAW v0.6.0 uses a modular shell architecture that keeps CLI behavior stable while separating internal responsibilities.

Main modules:
- `scripts/eaw`: CLI entrypoint and command dispatcher
- `scripts/eaw_core.sh`: shared execution primitives (including phase execution/logging)
- `scripts/commands/*.sh`: command handlers (`init`, `card`, `next`, `complete`, `run`, `doctor`, `validate`, prompt governance, and compatibility modules)
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
- In the current runtime model, phase completion is validated through the phase `completion` contract when `next` or `complete` runs. `complete` is a supported public command for explicit current-phase completion; `next` remains the normal progression command and can auto-close the final phase.
- The current phase-driven executor is incremental: it scaffolds declared outputs, materializes any `phase.outputs.prompts` entries under `out/<CARD>/prompts/` using the declared alias as the filename, emits compatibility prompt artifacts for built-in prompt phases, and records execution in `execution.log`.

### Deterministic Agent Mode (Modo D)

Modo D is the execution model in which EAW prepares deterministic phase execution surfaces for an external agent or Codex process. The shell runtime governs state, prompts, context injection, validation gates, and transitions; the operator or orchestrator owns the actual LLM execution.

**Cycle (authoritative definition):**

```
next → load phase.yaml → render prompt/context/runtime surface → operator/orchestrator runs external agent → artifacts are written → next or complete validates and advances
```

**Shell runtime role:** `./scripts/eaw next` is the entry point and governor for deterministic shell state. It resolves track/phase YAML, renders prompts, injects non-empty context blocks, validates artifacts and envelopes, writes journal events, and advances card state. It must not be described as spawning an LLM agent unless that behavior is implemented in the dispatcher.

**Operator/orchestrator role:** the operator or orchestration layer takes the generated prompt and declared contracts, runs the external agent, and ensures required artifacts are written back under `out/<CARD>/` before returning to `next` or `complete`.

**Current runtime state:** `phase.skills` is a workflow YAML contract surface for orchestration, not a guaranteed shell-spawn behavior. The current shell dispatcher does not semantically validate or load skills as part of an LLM spawn path.

**Post-execution skills:** skills such as reviewer and delivery are post-execution capabilities. They operate outside the shell lifecycle unless an operator/orchestrator explicitly invokes them.

**Skills invariant:** the shell runtime does not modify prompt content to mention or include skill names. `phase.skills` is external to `phase.prompt.path` and to injected context declared by `phase.context`.

Cross-document references:
- Formal contract for `phase.skills` field: `docs/WORKFLOW_YAML_CONTRACT.md` (Phase Skills Block).
- Object model for Skill: `docs/CONCEPTUAL_MODEL.md` (Core Objects → Skill).
- Prompt governance rule for skills/prompt orthogonality: `docs/PROMPT_GOVERNANCE.md` (Operational Skill Surface).
- Runtime boundary: `docs/RUNTIME_CONTRACTS.md`.

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

## Testable Architecture Invariants

- CLI interface remains stable (`./scripts/eaw <subcommand>`).
- `run_phase` behavior remains stable via `tests/run_phase_smoke.sh`.
- Output structure remains deterministic via `tests/smoke.sh` and `tests/golden_structure_check.sh`.
