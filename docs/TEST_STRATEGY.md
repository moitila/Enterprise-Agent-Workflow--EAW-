# EAW Test Strategy

## Scope

This strategy documents deterministic validation for the public EAW contract without changing CLI behavior.

## Test Layers

1. Static shell checks
- `bash -n` on changed shell scripts
- `shellcheck`
- `shfmt -d`

2. Contract smoke tests
- `tests/smoke.sh`: validates card creation and required artifacts
- `tests/smoke_prompt.sh`: validates prompt generation (happy + structurally incomplete intake paths)
- `tests/run_phase_smoke.sh`: validates `run_phase` and `execution.log` line format
- `tests/golden_structure_check.sh`: validates deterministic output structure
- `tests/scaffold_parity_smoke.sh`: validates normal vs workspace scaffold parity and asserts `intake/` exists empty

## Minimal Deterministic Examples

Example A (end-to-end smoke):
```bash
./tests/smoke.sh
```
Expected:
- exit code `0`
- `out/<CARD>/` created
- expected contract artifacts present

Example B (prompt smoke):
```bash
./tests/smoke_prompt.sh
```
Expected:
- exit code `0`
- prompt artifact written
- structural warning only when intake is intentionally incomplete

Example C (phase log smoke):
```bash
./tests/run_phase_smoke.sh
```
Expected:
- exit code `0`
- `execution.log` entries with 4 columns: `phase|status|duration_ms|note`

## Environment Requirements

- `bash`
- `git`
- `mktemp`

`mktemp` is required because smoke tests create isolated temporary workspaces and repositories.

## Stability Policy

- Tests assert contract behavior, not implementation details of module layout.
- New tests must preserve determinism and avoid non-reproducible dependencies.
