# EAW Validation Contract

Status: public runtime contract

This document describes what EAW validation commands check and what they do not guarantee.

## Commands

### `eaw validate`

`eaw validate` checks the active runtime workspace and card outputs visible under `EAW_OUT_DIR`.

Observed responsibilities:

- print resolved runtime directories;
- require workspace `config/` and `repos.conf` when `EAW_WORKDIR` is set;
- parse `repos.conf` and warn for missing repo paths;
- warn when `search.conf` is missing;
- resolve required default prompt metadata;
- scan workflow cards under `out/`;
- load each card workflow context;
- enforce mandatory analysis audit checks;
- run strict completion validation for cards currently in `findings`;
- summarize track, current phase, prompt phase, prompt path, next phase, and final phase;
- check selected intake template headings;
- check implementation artifacts when an `implementation/` directory exists.

`eaw validate` is not a universal proof that every card is complete. It may validate special gates for particular phases and artifacts, but operators must still rely on `eaw next` or `eaw complete` for the current phase lifecycle gate.

### `eaw validate workflow --track <track_id>`

Validates one installed track under `tracks/<track_id>/`.

Checks include:

- track directory and `track.yaml` existence;
- `track.id`, `track.initial_phase`, `track.final_phase`, and `track.phases` consistency;
- duplicate phases;
- phase YAML existence and duplicate phase config files;
- `phase.id`;
- `phase.prompt.path` presence and ACTIVE resolvability;
- `phase.prompt.active` presence and version shape;
- warning when `phase.prompt.active` diverges from `ACTIVE`;
- `phase.outputs` allowed keys and list shape;
- `phase.completion.strategy`;
- `phase.tooling_hints` list shape;
- `phase.context` structure and supported keys;
- transition source and target consistency;
- missing `transitions.<phase>.next` for non-final phases;
- accidental `next` transition on final phase.

Successful validation prints `OK track=<track_id> phases=<count>`.

### `eaw validate workflow --all`

Discovers installed tracks through `eaw tracks` and validates each one using the same rules as `--track`.

If no installed tracks are found, validation exits as a usage/runtime error for the workflow validator.

## Completion Gates

Lifecycle commands use stricter completion gates than structural workflow validation.

`eaw next` and `eaw complete` validate the current phase required artifacts before progressing or marking complete. A phase can be blocked because required artifacts are:

- missing;
- empty;
- still equal to generated scaffold/template content;
- invalid according to object metadata such as `min_bytes`, `validation_mode`, required headings, or JSON envelope schema.

When `eaw next` blocks for missing, unfilled, or invalid artifacts, it leaves the card on the same `current_phase` and returns successfully after reporting the reason. This gives the operator a deterministic repair point.

## Envelope Validation

When envelope files exist, lifecycle commands validate:

- `10_phase_output.json` has `phase_id`, valid `status`, and `summary`;
- `20_handoff.json` has `from_phase`, valid `status`, `messages` array, and `codes` array;
- non-empty `messages` entries include `type` and `code`;
- `10_phase_output.json.status` and `20_handoff.json.status` match when both files exist.

Accepted statuses are:

```text
completed
skipped
failed
```

## Prompt Validation

Prompt governance commands are separate from workflow validation:

- `eaw prompt validate`
- `eaw validate-prompt <TRACK> <PHASE> <CANDIDATE>`
- `eaw suggest-prompt ...`
- `eaw propose-prompt ...`
- `eaw apply-prompt ...`

Workflow validation checks whether phase prompt bindings resolve through `ACTIVE`. Prompt-specific commands validate candidate prompt files and activation behavior. See `docs/PROMPT_GOVERNANCE.md`.

## What Success Does Not Guarantee

A successful validation command does not guarantee:

- an external agent has executed a phase;
- a card is finished;
- every phase artifact is semantically correct;
- all target repository tests pass;
- every optional context source exists;
- rollback is safe for the current target repo state;
- ingest-pr imported semantically valid PR data;
- follow-up candidates should become real cards automatically.

Use validation as a contract gate, not as a substitute for operator review.

## Related Contracts

- CLI lifecycle: `docs/CLI.md`
- Runtime lifecycle and envelopes: `docs/RUNTIME_CONTRACTS.md`
- Workflow YAML: `docs/WORKFLOW_YAML_CONTRACT.md`
- Prompt governance: `docs/PROMPT_GOVERNANCE.md`
