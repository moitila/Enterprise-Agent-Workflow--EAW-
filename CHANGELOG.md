# Changelog

## Unreleased

### Fixed (CARD 574A — CompleteYAML)

- `eaw_official_track_dir`: substituiu `grep -qF` por awk via `eaw_yaml_track_scalar` para leitura consistente do registry (DV-DA1).
- `eaw_detect_card_template_type`: substituiu inferencia por nome de arquivo pela leitura de `card_state.track_id` em `state_card_*.yaml` via `eaw_yaml_state_scalar` (DV-DA3).
- `tracks.yaml` movido de `$EAW_ROOT_DIR/tracks.yaml` para `$EAW_ROOT_DIR/tracks/tracks.yaml`; todos os call sites atualizados (DV-DA2).
- `eaw_validate_workflow_track`: substituiu chamada a `eaw_official_track_dir` por verificacao direta do diretorio, eliminando dependencia circular com o registry (DV-DA4).
- `cmd_tracks_install`: substituiu sobrescrita integral do registry por reconciliacao incremental — le o registry existente, instala apenas tracks ausentes, escreve uma unica vez ao final (DV-DA0).
- `tests/smoke_tracks.sh`: adicionada cobertura do ciclo completo de `eaw tracks install`, incluindo idempotencia e rejeicao de track invalida (DV-DA5).

## v0.8.0 — Declarative Workflow Tracks & Onboarding Alignment

### Highlights
- Introduced official declarative workflow tracks under `tracks/<track>/` for `standard`, `feature`, `bug`, and `spike`.
- Added runtime support for track-based card creation via `eaw card <CARD> --track <TRACK>`.
- Added declarative workflow progression through `eaw next <CARD>`, backed by `card_state.current_phase` and `track.transitions`.
- Resolved phase prompts through declarative `prompt.path` and strengthened workflow validation in the runtime.
- Expanded the documentation set with a formal workflow YAML contract, track command contract, and conceptual onboarding model.

### Added
- Official workflow trees for `standard`, `feature`, `bug`, and `spike`, including `track.yaml`, `phases/*.yaml`, and logical `card_state.yaml` templates.
- `eaw tracks` validation hardening and dedicated smoke coverage.
- Workflow prompt path smoke coverage and card-command smoke coverage.
- `docs/WORKFLOW_YAML_CONTRACT.md` documenting `track`, `phase`, `card_state`, and compatibility behavior.
- `docs/TRACKS_COMMAND.md` for `eaw tracks`.
- `docs/CONCEPTUAL_MODEL.md` to clarify the product mental model and onboarding path.

### Changed
- Replaced legacy card creation commands with `eaw card <CARD> --track <TRACK>`.
- Updated runtime workflow loading to prefer official installed tracks and keep per-card compatibility artifacts as fallback.
- Updated `README.md`, `docs/integration.md`, and `docs/CONTRACT.md` to position the declarative lifecycle as primary and `intake` / `analyze` / `implement` as aggregated compatibility flows.
- Formalized missing `config/eaw.conf` as an optional formal contract in diagnostics:
  - `doctor` now reports `eaw.conf: OPTIONAL_FORMAL (...)` with no warning increment.
  - `validate` now emits an `INFO` line for missing `eaw.conf` and keeps `warnings=0`.

### Testing
- Added or updated smoke coverage for:
  - `eaw card`
  - `eaw tracks`
  - declarative `prompt.path`
  - config contract scenarios for `eaw.conf`
- Lifecycle and golden structure checks now cover the expanded workflow-track model.

### Compatibility Notes
- Public CLI remains stable and backward-compatible for prompt-oriented flows.
- Workflow classification is now documented consistently as `track` / `card_state.track_id`.
- `intake`, `analyze`, and `implement` remain available as aggregated compatibility commands for AI-assisted execution.

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
