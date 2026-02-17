# Card Execution Engine — Contract

Version: 0.1

Purpose
-------
Defines the inputs, outputs and operational rules for the Card Execution Engine (CE Engine).
This is a _contract_ for callers and implementers — it does not change CLI or behaviour.

Inputs
------
- Command: `eaw <subcommand>` (no changes to CLI).
- Card parameters: `type` (feature|bug|spike), `card id` (string), `title` (string).
- Configuration files (workspace `config/`):
  - `repos.conf` — lines in format `key|path` (path may be absolute, ~/, or relative to EAW root).
  - `search.conf` — newline-separated search patterns (optional).
- Templates: `templates/<type>.md` must exist for card rendering.

Outputs
-------
- Primary output directory: `out/<CARD>/`
- Expected artifacts inside `out/<CARD>/`:
  - `<type>_<CARD>.md` — rendered dossier (main artifact)
  - `AI_PROMPT_<CARD>.md` — optional prompt file (when analyze runs)
  - `TEST_PLAN_<CARD>.md` — placeholder test plan
  - `context/<repoKey>/` — per-repo metadata files (git-branch.txt, git-commit.txt, changed-files.txt, git-diff.patch, git-status.txt)
  - `_warnings.txt` — optional; contains best-effort collection warnings (created only on tolerated failures)

Operational rules / invariants
------------------------------
- CLI is the authoritative entry point; contract implementation must not change arguments/flags.
- Path resolution: inputs that are paths support absolute `/`, home `~/` and EAW-root-relative.
- Idempotency: running the same card creation twice should produce the same `out/<CARD>/` artifacts (overwriting is acceptable).
- Error handling:
  - Fatal errors must exit non-zero and include contextual message (file:function:line:command).
  - Best-effort collections (git/status, rg/grep) are tolerated; failures are recorded in `_warnings.txt` but do not fail the run.
- Side effects limited to `out/<CARD>/` and temporary resources; no global state is mutated beyond `config/` during runtime.

Tolerances & Observability
--------------------------
- Commands that are "best-effort" must be annotated and their failures recorded to `_warnings.txt`.
- The runtime must provide an `EAW_ERROR:` message on unhandled failures including file, function, line and failing command.

Validation & Testing
--------------------
- Implementations must pass: `bash -n`, `shellcheck`, `shfmt -d`, and `./scripts/eaw --help`.
- A minimal smoke harness (`tests/smoke.sh`) verifies a full card creation flow against a temporary git repository.

Examples
--------
repos.conf entry:
```
myrepo|~/projects/foo
```
Invocation (unchanged):
```
eaw feature CARD123 "Implement X"
```
Expected artifact:
```
out/CARD123/feature_CARD123.md
```

Change policy
-------------
- Contract changes must be backwards compatible with the CLI.
- Any relaxation of tolerances must be documented and covered by tests.

Contact
-------
- Maintainers: see repository README
