# Execution Journal — Schema v1

## Overview

The Execution Journal is a structured, append-only log written by the EAW runtime for each phase execution within a card. It lives at `out/<CARD>/execution_journal.jsonl` and uses JSON Lines format (one JSON object per line).

The `execution.log` (pipe-separated, 4-column) remains unchanged and continues to serve as the operational phase log. The Execution Journal is an additive structured layer, independent of `execution.log`.

## Format

JSON Lines: one JSON object per line, UTF-8, no trailing comma, no wrapping array.

Example event:

```json
{"card_id":"565","track":"feature","phase":"findings","timestamp":"2026-03-16T10:00:00Z","agent":"runtime","mode":"phase_driven","status":"OK","duration_ms":224}
```

## Fields

| Field          | Type   | Required | Description |
|----------------|--------|----------|-------------|
| `card_id`      | string | yes      | Card identifier (e.g., `"565"`). |
| `track`        | string | yes      | Track name (e.g., `"feature"`). |
| `phase`        | string | yes      | Phase name as executed (e.g., `"findings"`). |
| `timestamp`    | string | yes      | UTC ISO 8601 timestamp at end of phase execution (`YYYY-MM-DDTHH:MM:SSZ`). |
| `agent`        | string | yes      | Fixed value `"runtime"` in this version. Identifies who wrote the event. |
| `mode`         | string | yes      | Fixed value `"phase_driven"` in this version. Identifies the execution mode. |
| `status`       | string | yes      | `"OK"` or `"FAIL"`. Mirrors the value recorded in `execution.log`. |
| `duration_ms`  | number | yes      | Phase duration in milliseconds. Mirrors the value recorded in `execution.log`. |

## Semantics

**`agent`:** Identifies the entity responsible for writing the event. In this version, only the EAW runtime writes journal events, so the value is always `"runtime"`. Future versions may introduce agent-specific values (e.g., AI-assisted phases with a named agent identity).

**`mode`:** Identifies how the phase was triggered. In this version, all phases are triggered by the `eaw next` phase-driven lifecycle, so the value is always `"phase_driven"`. Future versions may introduce other modes (e.g., `"manual"`, `"replay"`).

## File Path

```
out/<CARD>/execution_journal.jsonl
```

The file is created on demand the first time a phase is executed for a given card. Subsequent phase executions append to the existing file.

## Compatibility Rules

- New fields may be added to future events without breaking existing readers.
- Existing required fields will not be removed in patch versions.
- Readers must ignore unknown fields.
- The `agent` and `mode` fields will be extended with new values in future versions; readers must not treat the current fixed values as exhaustive.

## Invariants

- **Append-only:** The file is never truncated or overwritten. Each phase execution appends exactly one line.
- **Conditional write:** The journal is only written when `CARD_DIR` (the card output directory) is defined. Executions without a card context (e.g., unit tests without card initialization) do not write to the journal.
- **Atomicity:** Append via shell is not atomic. EAW executes phases sequentially per card, making concurrent write conflicts negligible in practice. This invariant should be revisited before parallel card execution is introduced.

## Relationship to `execution.log`

| Property        | `execution.log`             | `execution_journal.jsonl`     |
|-----------------|-----------------------------|-------------------------------|
| Format          | Pipe-separated, 4 columns   | JSON Lines                    |
| Fields          | `phase\|status\|duration_ms\|note` | All required fields above |
| Purpose         | Operational phase log       | Structured audit trail        |
| Written by      | `run_phase()` in `eaw_core.sh` | `eaw_journal_append()` in `eaw_core.sh` |
| Modified by 565 | No                          | Created                       |
