# EAW Runtime Contracts

Status: public runtime contract

This document centralizes runtime lifecycle contracts that were previously scattered across README, architecture, workflow YAML, prompt governance, and tests. It documents observed behavior and human architectural decisions for Package 1 and Package 2 documentation work.

## Runtime Ownership Boundary

The EAW shell runtime owns deterministic phase execution surfaces:

- workflow state loading from `out/<CARD>/state_card_*.yaml` and compatibility state paths;
- installed track and phase YAML resolution;
- `track.transitions` evaluation;
- phase output scaffolding;
- prompt rendering into `out/<CARD>/prompts/`;
- context block injection when the generated block is non-empty;
- completion validation gates;
- envelope schema validation;
- execution journal events;
- runtime state and operational logs.

The EAW shell runtime does not own LLM execution. Agent execution is performed by the operator or orchestrator using the generated prompt and declared contracts.

Based on human architectural decision DECISION-002: Modo D means a disciplined cycle of shell runtime plus operator/orchestrator plus external agent. The shell prepares deterministic surfaces; it must not be documented as spawning an isolated agent unless that behavior is implemented in the dispatcher.

## Card Lifecycle

The active workflow position is `card_state.current_phase`. The selected workflow is `card_state.track_id`, resolved against `tracks/<track_id>/track.yaml`.

`eaw card <CARD> --track <TRACK>` creates the card state and materializes the track `initial_phase`.

`eaw next <CARD>` is the normal forward-progress command:

1. load workflow context;
2. materialize the current phase surface;
3. validate required current phase artifacts;
4. validate envelope schema if envelope files exist;
5. write context summary;
6. emit phase envelopes when requested by track transition contract;
7. update state through `track.transitions`;
8. materialize the destination phase;
9. generate a destination context bundle when available.

If completion validation fails because artifacts are missing, unfilled, or invalid, the runtime leaves `current_phase` unchanged and reports the block.

`eaw complete <CARD>` is a supported explicit completion command. It validates the current phase and marks it complete without advancing to the next phase. On the final phase it also writes final completion side effects described below.

`eaw run <CARD>` repeatedly calls `eaw next <CARD>` and adds run-level state and logs under `out/<CARD>/runtime/`.

## Final Phase Completion

When `current_phase` equals the track `final_phase`, two public flows can complete the workflow:

- `eaw complete <CARD>`: explicit operator completion after validation;
- `eaw next <CARD>`: final-phase auto-close when validation already passes.

Final completion side effects include idempotent journal completion events. `complete` emits `card_completed`, card metrics, and follow-up candidates when applicable. `next` also emits final completion events idempotently during auto-close.

`track_completed` means the declared workflow reached its terminal state. `card_completed` means the card unit of work was marked complete after final-phase validation.

## Required Artifacts

Phase completion uses `phase.completion`.

Supported completion strategy:

- absent or `required_artifacts_exist`: each declared required artifact must exist.

Strict completion additionally rejects required artifacts that are empty, still equal to known scaffold/template content, or fail object metadata checks such as minimum bytes, validation mode, required headings, or JSON envelope schema.

## Runtime Envelopes

Two minimal JSON envelope files are part of the Package 1 contract.

### `investigations/10_phase_output.json`

Required fields when present:

| Field | Required | Accepted values / meaning |
|---|---:|---|
| `phase_id` | yes | Non-empty phase identifier. |
| `status` | yes | `completed`, `skipped`, or `failed`. |
| `summary` | yes | Phase summary string. May be empty when emitted by runtime. |

### `investigations/20_handoff.json`

Required fields when present:

| Field | Required | Accepted values / meaning |
|---|---:|---|
| `from_phase` | yes | Non-empty source phase identifier. |
| `status` | yes | `completed`, `skipped`, or `failed`. |
| `messages` | yes | JSON array. Non-empty entries must include `type` and `code`. |
| `codes` | yes | JSON array of handoff codes. Code catalogs are track-specific. |

If both envelope files exist, their `status` values must match.

Minimal successful handoff:

```json
{"from_phase":"findings","status":"completed","messages":[],"codes":[]}
```

Runtime-emitted skipped handoffs may also include `code_origin`, `inherited_from`, `skip_reason_code`, and informational message entries.

## Skip Behavior

`skip_when` is a track transition contract that can skip the next phase based on handoff codes emitted by the previous phase.

Observed shell behavior:

- `cmd_next` loads active phase exit codes from `investigations/20_handoff.json` before loading workflow context;
- when the current transition declares `skip_when`, the runtime compares declared skip codes with active handoff codes;
- if a code matches, the runtime emits skip envelopes for the phase that would have been next;
- the runtime then advances to that skipped phase's transition target when one exists.

Runtime-emitted skip artifacts:

```text
out/<CARD>/investigations/00_human.md
out/<CARD>/investigations/10_phase_output.json
out/<CARD>/investigations/20_handoff.json
```

Skipped phase output uses:

```json
{"phase_id":"<phase>","status":"skipped","summary":"Phase skipped by skip_when rule","skip_reason_code":"<CODE>"}
```

Skipped handoff uses `status: "skipped"`, `code_origin: "inherited"`, and an informational message with code `PHASE_SKIPPED_BY_RULE`.

Final-phase special case: when the final phase already has a skipped `10_phase_output.json`, `next` rewrites `20_handoff.json` to matching skipped status and bypasses artifact completion validation before final auto-close.

## Context Summary

The runtime can append a derived traceability view at:

```text
out/<CARD>/investigations/_context_summary.md
```

For each phase emission, the context summary reads `investigations/10_phase_output.json`. It records the phase status, using `unknown` when no status is available, and includes the phase summary only when that value is non-empty. Each emission appends a section for the phase, so the file is an accumulated execution trace rather than a current-state snapshot.

The runtime emits this summary during `eaw next` transitions and during final-phase completion. A track can set `context_summary_policy: excluded`; in that case, absence of the file is intentional. This policy exclusion does not define the behavior of write failures.

The context summary is not a sovereign source and does not control workflow state, transitions, or routing. Handoff envelopes and track transitions retain those responsibilities. Context and agent bundles remain separate derived views with their documented failure behavior, and card metrics remain derived from execution journal events.

## Context Sources

Based on human architectural decision DECISION-003: onboarding has a sovereign workspace source at:

```text
<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/
```

Preferred consumption is by reference through the context block. Documentation must not promise automatic per-card onboarding materialization unless a specific runtime or phase explicitly generates it.

Runtime-derived dynamic context is per-card operational context and may be materialized under:

```text
out/<CARD>/context/dynamic/
```

## Context Bundles

`next` generates a derived context bundle for the destination phase when generation succeeds:

```text
out/<CARD>/runtime/context_bundle_<next_phase>.md
```

The bundle is fail-soft. If the runtime cannot create `runtime/` or cannot write the bundle, it prints a warning and continues.

The bundle is not a sovereign source. It is a rendered view for operator convenience and audit support.

Observed sections:

- title with card and destination phase;
- generated timestamp;
- card, track, completed current phase, and next phase;
- `EAW_WORKDIR`, `OUT_DIR`, and `CARD_DIR`;
- repositories table resolved from `repos.conf`, including branch, commit, and dirty status when git queries succeed;
- required artifacts checklist for the destination phase;
- active sovereign contract presence for `implementation/00_scope.lock.md` and `implementation/10_change_plan.md`;
- descriptive write policy note.

Write policy inside the context bundle is descriptive only. Enforcement remains unchanged.

## Agent Bundles

`next` also attempts to generate a derived agent bundle for the destination phase:

```text
out/<CARD>/runtime/agent_bundle_<next_phase>.md
```

The bundle is a rendered view of effective skills for operator/orchestrator use. It does not mean the shell runtime spawned or executed an LLM agent.

Observed behavior:

- reads `phase.skills` from the destination phase YAML;
- prepends the workspace skill (`eaw_workspace`) to the effective skill list;
- resolves skill files through `skills/registry.yaml`;
- writes the contents of resolved skill files into the bundle;
- returns an error if `skills/registry.yaml` is absent or a declared skill is not found;
- prints a warning and continues if `runtime/` cannot be created or the bundle cannot be written.

The agent bundle is not a sovereign source. The phase YAML and skill registry remain the source of skill routing.

## Prompt Context Block

When a phase produces a non-empty context block, the rendered prompt template must contain a standalone line exactly equal to:

```text
{{CONTEXT_BLOCK}}
```

If that standalone placeholder is absent, context injection fails with `ERROR: {{CONTEXT_BLOCK}} placeholder not found in template`.

If no context block is produced, the placeholder is not required.

## Output Locations

Primary card output:

```text
out/<CARD>/
```

Key runtime artifacts:

| Path | Owner | Purpose |
|---|---|---|
| `state_card_*.yaml` | runtime | Mutable workflow state. |
| `investigations/*.md` | phase/agent/runtime | Phase work artifacts. |
| `investigations/_context_summary.md` | runtime | Derived, accumulated per-phase traceability summary when not excluded by track policy. |
| `investigations/10_phase_output.json` | phase/agent/runtime | Phase output envelope. |
| `investigations/20_handoff.json` | phase/agent/runtime | Handoff envelope and transition codes. |
| `prompts/<alias>.md` | runtime | Rendered phase prompt. |
| `execution_journal.jsonl` | runtime | Structured append-only journal. |
| `execution.log` | runtime | Compatibility operational log. |
| `runtime/run_state.yaml` | runtime | `eaw run` state snapshot. |
| `runtime/execution.log` | runtime | `eaw run` per-attempt log. |
| `runtime/context_bundle_<phase>.md` | runtime | Destination context bundle, when generated. |
| `runtime/agent_bundle_<phase>.md` | runtime | Destination agent-skill bundle, when generated. |
| `card_metrics.json` | runtime | Final card metrics derived from execution journal completion events. |
| `_followup_candidates.md` | runtime | Candidate follow-up list derived from final scope lock Out of Scope bullets. |

## Write Allowlist Resolution

The runtime builds prompt/runtime write allowlist text from card artifacts. This is separate from `eaw rollback`.

Observed resolution order:

1. `implementation/00_scope.lock.md`, if present.
2. Markdown files in the card root or `intake/` containing a `WRITE_ALLOWLIST` list.
3. `implementation/10_change_plan.md` involved files.
4. Fallback to the card directory and any phase-declared output write paths.

`00_scope.lock.md` parsing accepts section titles containing `Allowlist`, `ALLOWLIST`, `Autorizados`, or `WRITE`. It can extract absolute paths from fenced code blocks, bullet lists, numbered lists, table-like lines, and `KEY: /path` lines.

Known constraints:

- extracted paths must look absolute (`/...`);
- glob patterns containing `*` or `?` are ignored;
- trailing punctuation is stripped;
- directories ending in `/` are ignored;
- if scope lock exists but cannot be parsed, the runtime warns with `WRITE_ALLOWLIST: scope.lock presente mas nao parseavel`.

When `00_scope.lock.md` yields paths, it is the sovereign source for implementation write scope. If it is absent or unparsable, fallback behavior is visible in generated prompt/runtime text and should be reviewed by the operator.

## Follow-up Candidates

On final explicit completion, `complete` calls follow-up candidate generation. The generator is fail-soft and never creates cards automatically.

Input:

```text
out/<CARD>/implementation/00_scope.lock.md
```

Source section:

```text
## Out of Scope
```

Output when direct bullets exist:

```text
out/<CARD>/_followup_candidates.md
```

Each direct bullet becomes a numbered candidate with:

- description;
- `Suggested track: TBD`;
- suggested scope reminding the operator to review and convert into a dedicated card if still relevant.

If the Out of Scope section contains unsupported tables or subsections, the runtime writes `_followup_candidates.md` with an unsupported-content note instead of converting nested content. If scope lock, Out of Scope, or direct bullets are absent, no file is generated.

## Card Metrics

Final completion can write:

```text
out/<CARD>/card_metrics.json
```

Metrics are derived from `execution_journal.jsonl` and only count `phase_completed` events whose phase name starts with `workflow_phase_`.

Fields:

| Field | Meaning |
|---|---|
| `total_duration_ms` | Sum of counted phase durations. |
| `phases_executed` | Number of distinct counted workflow phase names. |
| `re_executions` | Count of distinct phases with more than one counted completion event. |
| `first_attempt_success_rate` | Distinct phases with exactly one successful counted event divided by distinct counted phases. |

If the journal is absent or empty, metrics are not written.

## Non-Goals

- This document does not change runtime behavior.
- This document does not treat planned agent spawning as implemented shell behavior.
