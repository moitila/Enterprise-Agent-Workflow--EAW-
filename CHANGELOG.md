# Changelog

## v0.6.0 — Internal Modularization & Structural Stabilization

### Highlights
- Refactored the CLI architecture into a modular design.
- Extracted command handlers into dedicated modules under `scripts/commands/`.
- Introduced `scripts/eaw_core.sh` to isolate shared execution logic.
- Preserved full CLI contract (commands, flags, exit codes, and output structure).
- Improved internal test robustness and behavior validation.

### Internal Changes
- Separated bootstrap/dispatcher from core execution logic.
- Consolidated `run_phase` implementation in `scripts/eaw_core.sh`.
- Removed duplicated `run_phase` definition from `scripts/eaw`.
- Updated `tests/run_phase_smoke.sh` to validate runtime behavior (instead of textual extraction).
- Added golden structure checks for deterministic validation.

### Stability Improvements
- Eliminated structural drift risk caused by duplicate function definitions.
- Maintained deterministic execution logs and phase tracking.
- Smoke suite passing:
  - `tests/smoke.sh`
  - `tests/smoke_prompt.sh`
  - `tests/run_phase_smoke.sh`

### No Breaking Changes
- CLI commands unchanged.
- Output structure unchanged.
- No template changes.
- No contract-level behavior changes.

### Architectural Status
Internal architecture now enforces modular separation of:
- Bootstrap / Dispatcher
- Core execution engine
- Command handlers

This improves maintainability and future extensibility without changing public CLI behavior.

## v0.2.0

### Added
- Workspace mode with EAW_WORKDIR
- Hardened workspace isolation (no config fallback)
- config_version contract
- eaw validate command
- eaw doctor command
- Non-destructive upgrade (init --upgrade)
- Formal compatibility policy

### Changed
- Path resolution now respects workspace root in workspace mode

### Notes
- Legacy mode remains fully supported.
- No breaking changes from previous version.
