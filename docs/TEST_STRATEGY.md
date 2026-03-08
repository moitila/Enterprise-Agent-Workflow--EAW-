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
- `tests/run_phase_smoke.sh`: validates `run_phase` and `execution.log` line format
- `tests/smoke_prompt_core.sh`: validates minimal prompt governance contract for smoke
- `tests/smoke_config_contract.sh`: validates `eaw.conf` contract scenarios (missing file, missing `config_version`, outdated version)
- `tests/golden_structure_check.sh`: validates deterministic output structure
- `tests/scaffold_parity_smoke.sh`: validates normal vs workspace scaffold parity and asserts `intake/` exists empty

3. Integration tests
- `tests/integration/integration_prompt_lifecycle.sh`: validates full prompt lifecycle (`propose/suggest/validate/apply`) and provenance/binding
- `tests/integration/integration_suite.sh`: orchestrates integration entrypoints

4. Category split (deterministic wrappers)
- `tests/smoke/`: baseline smoke checks.
- `tests/integration/`: integration entrypoints and orchestration.
- `tests/lifecycle/`: lifecycle-focused deterministic assertions.
- `tests/golden/`: structure and golden output assertions.

## Minimal Deterministic Examples

Example A (end-to-end smoke):
```bash
./tests/smoke.sh
```
Expected:
- exit code `0`
- `out/<CARD>/` created
- expected contract artifacts present

Example B (phase log smoke):
```bash
./tests/run_phase_smoke.sh
```
Expected:
- exit code `0`
- `execution.log` entries with 4 columns: `phase|status|duration_ms|note`

Example C (prompt core smoke budget):
```bash
start="$(date +%s)"
./tests/smoke_prompt_core.sh
elapsed="$(( $(date +%s) - start ))"
test "$elapsed" -le 20
```
Expected:
- exit code `0`
- prompt core smoke under `20s` in CI baseline

## Environment Requirements

- `bash`
- `git`
- `mktemp`

`mktemp` is required because smoke tests create isolated temporary workspaces and repositories.

## Stability Policy

- Tests assert contract behavior, not implementation details of module layout.
- New tests must preserve determinism and avoid non-reproducible dependencies.

## Prompt Evolution v0

- Prompt lifecycle validation should cover the canonical `default` phases:
  - `default/intake`
  - `default/analyze_findings`
  - `default/analyze_hypotheses`
  - `default/analyze_planning`
  - `default/implementation_planning`
  - `default/implementation_executor`
- Each phase must provide versioned candidates `prompt_vN.md`, `prompt_vN.meta`, and `ACTIVE` under `templates/prompts/default/<phase>/` (`v1` is the seeded baseline in init scaffolding).
- Minimal command coverage is:
  - `./scripts/eaw validate-prompt default <phase> v1`
  - `./scripts/eaw apply-prompt default <phase> v1`
