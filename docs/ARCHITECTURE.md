# EAW Architecture (v0.6.0)

Canonical architecture document for EAW.

## Overview

EAW v0.6.0 uses a modular shell architecture that keeps CLI behavior stable while separating internal responsibilities.

Main modules:
- `scripts/eaw`: CLI entrypoint and command dispatcher
- `scripts/eaw_core.sh`: shared execution primitives (including phase execution/logging)
- `scripts/commands/*.sh`: command handlers (`init`, `feature|bug|spike`, `ingest`, `prompt`, `doctor`, `validate`, `analyze`)
- `scripts/lib.sh`: shared utility functions

The architecture is intentionally contract-first: internal modularization must not change public CLI, artifact names, or output layout.

## Runtime Flow

1. User invokes `./scripts/eaw <subcommand>`.
2. Dispatcher loads core + command modules.
3. Selected command runs deterministic phase steps.
4. Outputs are written to `out/<CARD>/` according to the contract.
5. `out/<CARD>/execution.log` records phase execution (`phase|status|duration_ms|note`).

## Deterministic Output Boundaries

Public output surface:
- dossier: `out/<CARD>/<type>_<CARD>.md`
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
- Prompt-path behavior remains stable via `tests/smoke_prompt.sh`.
