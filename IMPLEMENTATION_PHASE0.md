# Implementation Phase 0 - Workspace mode

## Summary of changes

- Added centralized directory resolution in `scripts/lib.sh` via `resolve_workdirs()`.
- Preserved default behavior when `EAW_WORKDIR` is unset.
- Refactored `scripts/eaw` to consume resolved variables (`EAW_CONFIG_DIR`, `EAW_TEMPLATES_DIR`, `EAW_OUT_DIR`).
- Added runtime validation with clear message when `EAW_WORKDIR` is set but `config/` is missing.
- Extended `eaw init` with:
  - `--workdir <path>`
  - `--force`
- Implemented workspace initialization:
  - creates `<workdir>/config`, `<workdir>/templates`, `<workdir>/out`
  - creates `config/repos.conf` sample
  - creates `config/search.conf` from core default when available, or placeholder otherwise
  - copies default core templates (`feature.md`, `bug.md`, `spike.md`) when available
  - does not overwrite existing files unless `--force`
- Added `docs/integration.md` with workspace usage guidance.

## Files changed

- `scripts/lib.sh`
- `scripts/eaw`
- `docs/integration.md`
- `IMPLEMENTATION_PHASE0.md`

## Manual test (3 commands)

```bash
./scripts/eaw init --workdir /tmp/eaw-phase0
EAW_WORKDIR=/tmp/eaw-phase0 ./scripts/eaw feature 1001 "Workspace smoke"
EAW_WORKDIR=/tmp/eaw-phase0-missing ./scripts/eaw feature 1002 "Should fail with guidance"
```

Expected:
- command 1 creates `config/`, `templates/`, `out/` and sample config files
- command 2 writes dossier under `/tmp/eaw-phase0/out/1001/`
- command 3 exits with friendly message suggesting `./scripts/eaw init --workdir ...`

## bash -n logs

```text
bash -n scripts/eaw: OK
bash -n scripts/lib.sh: OK
```
