# Card Execution Engine — Contract

Version: 0.1

Purpose
-------
Defines the inputs, outputs and operational rules for the Card Execution Engine (CE Engine).
This is a _contract_ for callers and implementers — it does not change CLI or behaviour.

Inputs
------
- Command: `eaw <subcommand>` (no changes to CLI).
- Card parameters: `card id` (string), `title` (string), and the workflow track selected during card creation via `eaw card <CARD> --track <TRACK>`.
- Primary workflow classification is the selected `track`, persisted as `card_state.track_id`.
- Configuration files (workspace `config/`):
  - `repos.conf` — lines in format `key|path` (legacy) or `key|path|role`, where role is `target` or `infra` (path may be absolute, ~/, or relative to EAW root). Missing role defaults to `target`.
  - `search.conf` — newline-separated search patterns (optional).
- Templates: `templates/<type>.md` must exist for dossier rendering compatibility. This filename/template family does not replace `track` as the primary workflow classification.

Command semantics
-----------------
Primary workflow classification remains the selected `track`, persisted as `card_state.track_id`. The declarative lifecycle advances through `card_state.current_phase` and `track.transitions`; `eaw next <CARD>` is the runtime command that first validates the current phase `completion` contract, then applies the transition and executes the destination phase using the declared workflow outputs and prompt bindings. The command sections below document the aggregated prompt-oriented CLI surface that remains public for compatibility and deterministic artifact generation.
In the current runtime model, `eaw next <CARD>` is the phase-driven entrypoint, while `eaw intake <CARD>`, `eaw analyze <CARD>`, and `eaw implement <CARD>` remain available as deprecated aggregated compatibility commands for prompt-oriented flows, with planned removal in `v1.0`.
The current contract documents phase completion through `phase.completion` and the `eaw next <CARD>` transition gate. It does not define a public `eaw complete <CARD>` command in the current CLI surface, so callers should treat completion as part of the declarative phase contract rather than a separate command.

### `eaw intake`

Syntax:
`eaw intake <CARD> [--round=N]`

Behavior:
- Generates a deterministic intake prompt in `out/<CARD>/prompts/intake.md`.
- Does not modify source code repositories.
- The generated prompt constrains evidence reading to `out/<CARD>/intake/**`.
- Emits a warning in `stderr` marking the wrapper as deprecated, points callers to `eaw next`, and keeps the wrapper functional during the transition until the planned `v1.0` removal target.

### `eaw analyze`

Syntax:
`eaw analyze <CARD>`

Behavior:
- Generates prompt artifacts only at `out/<CARD>/prompts/<prompt_alias>.md` when the current phase declares `outputs.prompts`.
- In `out/<CARD>/prompts/`, the filename is the declared alias exactly.
- Validates intake structure heuristically using the available intake/dossier template family and emits warnings in the generated prompt when intake is incomplete.
- Ensures deterministic auxiliary artifacts for analysis flow, including `TEST_PLAN_<CARD>.md` when absent.
- Does not modify source code repositories.
- Emits a warning in `stderr` marking the wrapper as deprecated, points callers to `eaw next`, and keeps the wrapper functional during the transition until the planned `v1.0` removal target.

### `eaw implement`

Syntax:
`eaw implement <CARD>`

Behavior:
- Creates implementation scaffolds in `out/<CARD>/implementation/`.
- Generates implementation prompt artifacts only in `out/<CARD>/prompts/implementation_planning.md` and `out/<CARD>/prompts/implementation_executor.md`.
- Emits a warning in `stderr` marking the wrapper as deprecated, points callers to `eaw next`, and keeps the wrapper functional during the transition until the planned `v1.0` removal target.

### `eaw doctor-hardening`

Syntax:
`eaw doctor-hardening`

Behavior:
- Runs advanced hardening diagnostics (prompt ACTIVE binding, validate status, canonical smoke entrypoints, tool checks).
- Reports risk and summary (`critical_failures`, `warnings`) for operational troubleshooting.
- Does not modify source code repositories.

Outputs
-------
- Primary output directory: `out/<CARD>/`
- Expected artifacts inside `out/<CARD>/`:
  - `<type>_<CARD>.md` — rendered dossier (main artifact; deterministic compatibility filename, not the primary workflow classification)
  - `investigations/00_intake.md` — investigation intake
  - `investigations/10_baseline.md` — baseline stage scaffold
  - `investigations/20_findings.md` — findings stage scaffold
  - `investigations/30_hypotheses.md` — hypotheses stage scaffold
  - `investigations/40_next_steps.md` — next-steps stage scaffold
  - `prompts/<prompt_alias>.md` — phase-driven prompt file generated from `outputs.prompts`; the filename matches the declared alias exactly
  - `execution.log` — phase execution log with format `phase|status|duration_ms|note`
  - `execution_journal.jsonl` — structured Execution Journal in JSON Lines format; one event per phase execution with fields `card_id`, `track`, `phase`, `timestamp`, `agent`, `mode`, `status`, `duration_ms`; schema documented in `docs/EXECUTION_JOURNAL.md`
  - `TEST_PLAN_<CARD>.md` — placeholder test plan
  - `context/<repoKey>/` — per-repo metadata files (git-branch.txt, git-commit.txt, changed-files.txt, git-diff.patch, git-status.txt)
  - `context/<repoKey>/_warnings.txt` — optional; contains best-effort collection warnings (created only on tolerated failures)
  - Only repositories with role `target` are processed into `context/`; role `infra` is explicitly excluded from collection.

Prompt declaration rule
-----------------------
- `outputs.prompts` is optional in the general workflow contract.
- Phases that produce prompts should declare them explicitly.
- Internal/tooling phases that do not produce prompts should omit the field.
- Prompt artifacts are materialized only in `out/<CARD>/prompts/`.

Determinism
-----------
- Filenames and artifact paths are deterministic and must match the contract exactly (e.g. `out/<CARD>/feature_<CARD>.md`). This is an output naming convention kept for compatibility; workflow classification remains track-based through `card_state.track_id`.
- Where EAW emits `date` values it uses UTC in ISO 8601 `YYYY-MM-DD` format (see `iso_date()` in `scripts/lib.sh`).
- `git-commit.txt` contains the canonical commit SHA; `git-branch.txt` contains the branch name.
- `changed-files.txt` is a newline-separated list of paths. Implementations SHOULD present this list in stable (sorted) order to improve reproducibility; callers must not rely on directory listing order.
- Locale-sensitive output must not be relied upon by callers; implementations should use POSIX/C semantics for sorting/formatting where determinism matters.

Notes on `_warnings.txt`
-----------------------
- `_warnings.txt` is created per-repo under `out/<CARD>/context/<repoKey>/` only when a best-effort collection step fails.
- Each line in `_warnings.txt` should contain a short, human-readable reason and a pointer to the related artifact (example: `allowed to fail: git diff failed (see git-diff.patch)`).
- Presence of `_warnings.txt` is informational and does not constitute a fatal error by contract.


Operational rules / invariants
------------------------------
- CLI is the authoritative entry point; contract implementation must not change arguments/flags.
- Path resolution: inputs that are paths support absolute `/`, home `~/` and EAW-root-relative.
- Idempotency: running the same card creation twice should produce the same `out/<CARD>/` artifacts (overwriting is acceptable).
- Error handling:
  - Fatal errors must exit non-zero and include contextual message (file:function:line:command).
  - Best-effort collections (git/status, rg/grep) are tolerated; failures are recorded in `_warnings.txt` but do not fail the run.
  - Write scope is enforced per phase; when violated, runtime emits `WRITE_SCOPE_VIOLATION: phase=<...> command=<...> blocked_path=<...>` and returns exit code `97`.
  - Prompt binding is resolved through `templates/prompts/<track>/<phase>/ACTIVE`; missing file, empty value, invalid version, or missing `prompt_vN.meta` are fatal validation scenarios for prompt resolution.
- Side effects limited to `out/<CARD>/` and temporary resources; no global state is mutated beyond `config/` during runtime.

Prompt provenance
-----------------
- Runtime records resolved prompt bindings in `out/<CARD>/provenance/prompts_used.yaml`.
- This provenance file is part of deterministic observability for prompt lifecycle execution.

Tolerances & Observability
--------------------------
- Commands that are "best-effort" must be annotated and their failures recorded to `_warnings.txt`.
- The runtime must provide an `EAW_ERROR:` message on unhandled failures including file, function, line and failing command.

Validation & Testing
--------------------
- Implementations must pass: `bash -n`, `shellcheck`, `shfmt -d`, and `./scripts/eaw --help`.
- Smoke suite:
  - `tests/smoke.sh` — end-to-end card creation smoke
  - `tests/run_phase_smoke.sh` — execution log/run_phase behavior validation
  - `tests/smoke_prompt_core.sh` — prompt governance minimal smoke contract
  - `tests/golden_structure_check.sh` — deterministic structure assertions
  - `tests/scaffold_parity_smoke.sh` — normal vs workspace scaffold parity and empty `intake/` assertions
- Integration suite additions:
  - `tests/integration/integration_prompt_lifecycle.sh` — full prompt lifecycle integration checks
- Test harnesses rely on `mktemp` for isolated temporary directories.

Prompt Evolution v0
-------------------
- Versioned prompt candidates live under `templates/prompts/<track>/<phase>/` with `prompt_vN.md`, `prompt_vN.meta`, and `ACTIVE`.
- The canonical seeded `default` phases are:
  - `default/intake`
  - `default/analyze_findings`
  - `default/analyze_hypotheses`
  - `default/analyze_planning`
  - `default/implementation_planning`
  - `default/implementation_executor`
- Validation and activation commands are:
  - `./scripts/eaw validate-prompt default <phase> v1`
  - `./scripts/eaw apply-prompt default <phase> v1`

Examples
--------
repos.conf entry:
```
myrepo|~/projects/foo
```
Invocation (current public CLI):
```
eaw card CARD123 --track feature "Implement X"
```
Expected artifact:
```
out/CARD123/feature_CARD123.md
```
This filename remains deterministic for compatibility with existing tooling; the workflow itself is still classified by `track` / `card_state.track_id`.

Change policy
-------------
- Contract changes must be backwards compatible with the CLI.
- Any relaxation of tolerances must be documented and covered by tests.

Contact
-------
- Maintainers: see repository README
