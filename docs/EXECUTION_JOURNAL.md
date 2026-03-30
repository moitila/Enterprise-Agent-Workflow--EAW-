# Execution Journal — Schema v2

## Overview

The Execution Journal is a structured, append-only log written by the EAW runtime for each phase execution within a card. It lives at `out/<CARD>/execution_journal.jsonl` and uses JSON Lines format (one JSON object per line).

The journal is the single source of truth for phase execution. The legacy `execution.log` (pipe-separated, 4-column) is preserved as a compatibility view derived from `out/<CARD>/execution_journal.jsonl`; it is not an independent write path.

## Format

JSON Lines: one JSON object per line, UTF-8, no trailing comma, no wrapping array.

Example events (schema v2):

```json
{"card_id":"566","track":"feature","phase":"findings","timestamp":"2026-03-16T10:00:00Z","agent":"runtime","mode":"phase_driven","status":"STARTED","duration_ms":0,"event_type":"phase_started"}
{"card_id":"566","track":"feature","phase":"findings","timestamp":"2026-03-16T10:00:01Z","agent":"runtime","mode":"phase_driven","status":"OK","duration_ms":224,"event_type":"phase_completed"}
```

## Fields

| Field          | Type   | Required | Description |
|----------------|--------|----------|-------------|
| `card_id`      | string | yes      | Card identifier (e.g., `"566"`). |
| `track`        | string | yes      | Track name (e.g., `"feature"`). |
| `phase`        | string | yes      | Phase name as executed (e.g., `"findings"`). |
| `timestamp`    | string | yes      | UTC ISO 8601 timestamp at event emission time (`YYYY-MM-DDTHH:MM:SSZ`). |
| `agent`        | string | yes      | Fixed value `"runtime"` in this version. Identifies who wrote the event. |
| `mode`         | string | yes      | Fixed value `"phase_driven"` in this version. Identifies the execution mode. |
| `status`       | string | yes      | `"OK"` or `"FAIL"` for `phase_completed`; `"STARTED"` for `phase_started`. |
| `duration_ms`  | number | yes      | Phase duration in milliseconds. `0` for `phase_started` events (duration not yet known). |
| `event_type`   | string | yes (v2) | `"phase_started"` or `"phase_completed"`. See Event Types below. |

## Event Types

**`phase_started`:** Emitted immediately before the phase function begins execution inside `run_phase()`. Signals that the runtime is about to execute the phase. `status` is `"STARTED"` and `duration_ms` is `0` (execution has not completed yet).

**`phase_completed`:** Emitted immediately after the phase function returns inside `run_phase()`. `status` is `"OK"` or `"FAIL"` and `duration_ms` reflects the actual phase duration.

Each phase execution produces one `phase_started` event followed by one `phase_completed` event. If a phase is aborted before `run_phase()` returns, the `phase_completed` event may be absent — readers must tolerate unpaired `phase_started` events.

**`track_completed`:** Emitted by `cmd_next` when `current_phase` equals `final_phase` (as declared in `track.yaml`). Signals that the track workflow has reached its terminal state. `status` is `"OK"`, `duration_ms` is `0` (not applicable at track level), and `phase` contains the name of the terminal phase. Emission is idempotent: `cmd_next` checks for an existing `track_completed` event in the journal before emitting and skips if one is already present.

**`card_completed`:** Emitted by `cmd_complete` (`eaw complete <CARD>`) when `current_phase` equals `final_phase` and the phase artifacts pass explicit validation. Represents the operator-affirmed closure of the card as a unit of work — distinct from `track_completed`, which is emitted automatically by `cmd_next` when the workflow reaches its terminal state without additional artifact validation. `status` is `"OK"`, `duration_ms` is `0`, and `phase` contains the name of the terminal phase. Emission is idempotent: repeated calls to `eaw complete` emit the event exactly once.

## Semantics

**`agent`:** Identifies the entity responsible for writing the event. The value is read from the `EAW_AGENT` environment variable; if unset, it defaults to `"runtime"`. Known values: `"runtime"` (EAW runtime, default), `"unknown"` (context not determinable). Additional values may be introduced by callers (e.g., an AI agent identity such as `"claude-sonnet"`).

**`mode`:** Identifies how the phase was triggered. The value is read from the `EAW_MODE` environment variable; if unset, it defaults to `"phase_driven"`. Known values: `"phase_driven"` (triggered by `eaw next`, default), `"manual"` (triggered directly by a human operator), `"ci"` (triggered by a CI pipeline). Additional values may be introduced by callers.

**`duration_ms`:** Phase duration in milliseconds. Calculated as the difference between two `date +%s%3N` timestamps (milliseconds since Unix epoch) captured immediately before and after the phase function call in `run_phase`. In `phase_started` events, the value is hardcoded to `0` because the phase has not yet executed — `0` acts as a sentinel indicating duration not yet known. In `phase_completed` events, the value reflects the actual elapsed time. Because the journal is append-only, each retry of the same phase appends new `phase_started` and `phase_completed` events without overwriting previous ones; consumers should treat each event pair independently when analyzing per-attempt duration.

## File Path

```
out/<CARD>/execution_journal.jsonl
```

The file is created on demand the first time a phase is executed for a given card. Subsequent phase executions append to the existing file.

## Derived Compatibility View

```
out/<CARD>/execution.log
```

`execution.log` is rebuilt from `execution_journal.jsonl` and keeps the historical `phase|status|duration_ms|note` shape for existing consumers. Only completion records are projected into the pipe log, so each phase contributes one operational line while the journal retains the full structured event stream.

## Compatibility Rules

- New fields may be added to future events without breaking existing readers.
- Existing required fields will not be removed in patch versions.
- Readers must ignore unknown fields.
- The `agent` field is configurable via `EAW_AGENT` (default: `"runtime"`); readers must not treat the default value as exhaustive.
- The `mode` field is configurable via `EAW_MODE` (default: `"phase_driven"`); readers must not treat the default value as exhaustive.
- **Schema v1 compatibility:** Events written before schema v2 (card 565) do not have `event_type`. Readers must treat absent `event_type` as a legacy `phase_completed` equivalent and must not reject v1 events.

## Invariants

- **Append-only:** The file is never truncated or overwritten. Each phase execution appends events sequentially.
- **Conditional write:** The journal is only written when the card context (`OUTDIR` and `card_id`) is defined. Executions without a card context (e.g., unit tests without card initialization) do not write to the journal.
- **Atomicity:** Append via shell is not atomic. EAW executes phases sequentially per card, making concurrent write conflicts negligible in practice. This invariant should be revisited before parallel card execution is introduced.
- **Event order:** Within a single phase execution, `phase_started` always precedes `phase_completed` in the file.

## Relationship to `execution.log`

| Property        | `execution.log`                    | `execution_journal.jsonl`          |
|-----------------|------------------------------------|------------------------------------|
| Format          | Pipe-separated, 4 columns          | JSON Lines                         |
| Fields          | `phase\|status\|duration_ms\|note` | All required fields above          |
| Purpose         | Operational compatibility view     | Structured audit trail and source of truth |
| Written by      | `eaw_execution_log_from_journal()` in `eaw_core.sh` | `eaw_journal_append()` in `eaw_core.sh` |
| Source          | Derived from `phase_completed` journal events | Primary append-only runtime record |
| Events per phase | 1 (end only)                      | 2 (start + completion)             |
| Independence    | No                                 | Yes                                |
| Modified by 565 | No                                 | Created                            |
| Modified by 566 | No                                 | `event_type` field added           |
