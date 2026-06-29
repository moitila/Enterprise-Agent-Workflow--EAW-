# EAW CLI Contract

Status: public runtime contract

This document describes the public shell CLI exposed by `scripts/eaw`. It documents observed runtime behavior; it does not introduce new commands or change execution semantics.

## Runtime Boundary

The EAW shell runtime owns deterministic workflow surfaces: card state, track and phase resolution, prompt rendering, context block injection, validation gates, state transitions, execution journal events, and runtime artifacts under `out/<CARD>/`.

The shell runtime does not own LLM execution. Agent execution is performed by the operator or orchestrator using the generated phase prompt, declared context, and declared operational contracts.

## Global Requirements

- Run commands from the EAW repository or invoke `scripts/eaw` by path.
- In workspace mode, set `EAW_WORKDIR` so runtime config and output resolve from the intended workspace.
- Card commands require a valid runtime workdir and installed track tree under `tracks/<track_id>/`.
- The public dispatcher is `scripts/eaw`.

## Core Commands

| Command | Public | Responsibility |
|---|---:|---|
| `eaw init [--workdir <path>] [--force] [--upgrade]` | yes | Initialize or upgrade the workspace config scaffold. |
| `eaw card <CARD> --track <TRACK> ["<TITLE>"]` | yes | Create a card, initialize card state, and materialize the track initial phase. |
| `eaw next <CARD>` | yes | Validate the current phase completion contract, advance through `track.transitions` when complete, and materialize the destination phase. |
| `eaw complete <CARD>` | yes | Explicitly mark the current phase complete after required artifacts and envelope schema pass validation. |
| `eaw run <CARD>` | yes | Orchestrate a card by repeatedly calling `eaw next <CARD>` with run-level state and logs. |
| `eaw validate` | yes | Validate workspace config, prompt availability, selected template contracts, implementation artifacts, and workflow card states found under `out/`. |
| `eaw validate workflow [--track <track_id> \| --all]` | yes | Validate installed track/phase YAML structure, prompt bindings, transitions, outputs, completion strategy, tooling hints, and context block shape. |
| `eaw doctor` | yes | Report resolved directories, tools, and config status. |
| `eaw status <CARD>` / `eaw status --all` | yes | Report current card or workspace card status from runtime state. |
| `eaw rollback <CARD>` | yes | Restore scoped target repo files from `HEAD` using paths parsed from `00_scope.lock.md`. |
| `eaw ingest-pr <CARD> <PR_NUMBER> [--repo <REPO>]` / `eaw ingest-pr <CARD> --file <FILE>` | yes | Append PR-derived input into `ingest/raw_card_explication.md`. |
| Prompt governance commands | yes | Validate, suggest, propose, and apply prompt candidates. |
| `eaw smoke` / `eaw test` | yes | Execute local smoke/test wrapper scopes. See `docs/TEST_STRATEGY.md`. |

## Lifecycle Commands

### `eaw next <CARD>`

`next` is the normal lifecycle command. It:

- loads the card workflow context from the card state and installed track;
- materializes the current phase surface;
- renders the required artifact checklist;
- validates current phase completion using `phase.completion`;
- validates envelope schema when envelope artifacts exist;
- records context summary;
- writes emitted phase envelopes when the track contract requests them;
- updates `previous_phase`, `current_phase`, `completed_phases`, `phase_status`, and phase timestamps;
- materializes the destination phase after transition;
- writes a context bundle for the destination phase when generation succeeds.

If required artifacts are missing, still scaffold-only, or invalid, `next` exits successfully after leaving the card on the same `current_phase` and reporting the reason. This is an operator-facing block, not a shell crash.

When the current phase is the track `final_phase`, `next` performs final-phase auto-close if the phase is not yet marked complete and all validation gates pass. It then emits `card_completed` and `track_completed` journal events idempotently and reports that the workflow is already complete.

### `eaw complete <CARD>`

`complete` is a supported public command. It explicitly marks the current phase complete when:

- the card has canonical workflow YAMLs;
- the current phase required artifacts pass strict completion validation;
- existing phase envelope artifacts pass schema validation.

For non-final phases, `complete` marks the current phase complete but does not advance to the next phase. The operator then uses `next` to continue the lifecycle.

For the final phase, `complete` emits `card_completed` idempotently, writes card metrics, generates follow-up candidates when applicable, and marks the final phase complete. `next` can also auto-close the final phase when its validation gates already pass.

### `eaw run <CARD>`

`run` is a shell orchestration loop over `next`. It:

- finds and reads card state;
- validates that `track_id` resolves to an installed track;
- validates that `current_phase` is listed in the track;
- writes `out/<CARD>/runtime/run_state.yaml`;
- appends `out/<CARD>/runtime/execution.log`;
- repeatedly invokes `eaw next <CARD>`;
- detects terminal completion, invalid state, track consistency errors, failed phase execution, and no-forward-progress.

`run` does not call deprecated prompt modules such as `intake`, `analyze`, or `implement` as progression shortcuts.

## Status And Auxiliary Commands

### `eaw status <CARD>`

Prints a single-card status report. It:

- requires `out/<CARD>/` to exist under `EAW_OUT_DIR`;
- loads workflow context using the same card state resolution as lifecycle commands;
- prints `card_id`, `track_id`, `current_phase`, and `phase_status`;
- lists completed phases or `none`;
- lists pending required artifacts for the current phase or `none`;
- prints the latest line of `execution_journal.jsonl`, or a missing/empty marker.

`status` is read-only.

### `eaw status --all`

Scans immediate children of `EAW_OUT_DIR` and reports cards that have `state_card_*.yaml` in the card root or compatibility `intake/` directory. Output shape:

```text
card_id | track | phase | status
```

Cards are sorted by card directory name. If any discovered card has invalid workflow context, the command returns non-zero.

### `eaw rollback <CARD>`

`rollback` is a target-repo restore helper. It is intentionally narrow and can discard local file changes.

Observed behavior:

- resolves the card at `$EAW_WORKDIR/out/<CARD>`;
- requires `implementation/00_scope.lock.md`;
- extracts up to 20 backtick-wrapped file paths from markdown list items;
- resolves the first `target` repository from `$EAW_CONFIG_DIR/repos.conf`;
- for each extracted file that exists in that target repo, runs `git checkout HEAD -- <file>`;
- prints restored, skipped, and failed counts;
- returns non-zero when the card, scope lock, target file list, target repo, or restore operation fails.

Important: `rollback` does not read the richer write allowlist parser used for prompt/runtime context. It uses its own simpler backtick-list extraction. Operators should review the target repo state before using it.

### `eaw ingest-pr <CARD> <PR_NUMBER> [--repo <REPO>]`

Fetches PR data through the GitHub CLI and appends a summarized import block to:

```text
out/<CARD>/ingest/raw_card_explication.md
```

Observed behavior:

- requires the card directory to exist;
- creates `out/<CARD>/ingest/` if needed;
- requires `gh` when importing by PR number;
- calls `gh pr view <PR_NUMBER> --json title,body,comments,reviews`, optionally with `--repo`;
- extracts title, body, and comment authors with simple shell text parsing;
- labels comment authors as `bot` when the login contains common bot markers, otherwise `human`;
- appends to the raw card explanation file instead of replacing it.

### `eaw ingest-pr <CARD> --file <FILE>`

Imports from a local file instead of calling `gh`. The file content is treated as PR data and appended through the same output path.

`ingest-pr` does not create a card, does not validate PR JSON semantically, and does not advance the workflow.

## Agent Execution

The shell runtime prepares the execution surface. It does not spawn or control an LLM by itself in the observed dispatcher path.

Operator or orchestrator responsibility:

- open the generated phase prompt under `out/<CARD>/prompts/`;
- execute the phase with the chosen agent/Codex process;
- ensure the phase writes only the declared artifacts;
- return to `eaw next` or `eaw complete` after artifacts exist.

`phase.skills`, when documented in workflow YAML, is an orchestration contract for the operator/orchestrator. It must not be described as guaranteed shell-spawn behavior unless implemented by the runtime.

## Related Contracts

- Runtime lifecycle and envelopes: `docs/RUNTIME_CONTRACTS.md`
- Validation behavior: `docs/VALIDATION.md`
- Workflow YAML structure: `docs/WORKFLOW_YAML_CONTRACT.md`
- Prompt governance: `docs/PROMPT_GOVERNANCE.md`
- Execution journal: `docs/EXECUTION_JOURNAL.md`
