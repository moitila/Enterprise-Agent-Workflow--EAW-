# tests/baseline

## Objective

This is a small, versionable regression baseline for EAW 1.0. One disposable `bug` fixture exercises CLI, stdout, stderr, exit codes, rendered prompts, state, journal, and phase artifacts. The fixture's concrete `bug` semantics are not a generic runtime contract; it is only the selected representative flow.

## Expected Baseline

`expected/bug_intake.capture` is the approved, persistent reference. Normal mode never overwrites it. It compares a fresh capture with that file and prints a unified diff on divergence.

## Use

From the repository root:

```bash
bash tests/baseline/run_content_baseline.sh
```

Normal mode performs four separate checks:

1. Determinism: fixture A versus fixture B.
2. Regression: fixture A versus `expected/bug_intake.capture`.
3. Negative completion: `eaw complete <CARD>` fails (the command was removed in EAW-ARQ-016-NEXT-CLOSURE; `eaw next` is now the sole route to lifecycle closure).
4. Positive completion: a disposable `bug` card is driven through every phase via `eaw next`; on the final phase, auto-close emits `card_completed` and `track_completed` in `execution_journal.jsonl` and writes `phase_completed: true` to the state file.

`PASS` means all four checks passed. It means the covered flow still matches the approved reference and the single closure route behaves correctly, not that every EAW workflow is covered. Checks 3 and 4 only run in normal (non `--update-expected`) mode.

After an approved behavior change, update the expected baseline deliberately:

```bash
bash tests/baseline/run_content_baseline.sh --update-expected
```

This command still requires the determinism check to pass. Normal mode never updates `expected/`.

For a controlled comparison without modifying the versioned reference:

```bash
bash tests/baseline/run_content_baseline.sh --expected /path/to/alternate.capture
```

`--expected` is comparison-only. It cannot be combined with `--update-expected`;
the update mode writes only `expected/bug_intake.capture`.

## Fixture and Safety

Each run creates its own repository and EAW workdir with `mktemp -d`, then removes them with `trap EXIT`. It does not use real cards or the active EAW workspace.

## Normalization

Only proven ephemeral values are normalized:

| Surface | Normalized value | Reason |
|---|---|---|
| Runtime | Repository checkout path | A clone may reside at a different physical path. |
| CLI and artifacts | Temporary fixture paths | `mktemp` paths differ by run. |
| Prompt | `CANONICAL_PATH` | The executor path contains session-specific temporary directories. |
| State | Lifecycle timestamp fields | Runtime creation time differs by run. |
| Journal | `timestamp` and `duration_ms` fields | Operational timing differs by run. |
| Git provenance | 40-character fixture commit hash | Each fixture initializes a new commit. |

Other prompt and artifact content does not receive global date, ID, or path masking. Add a new normalization only after proving that the exact field is nondeterministic.

## Limitations

- One `bug` intake flow is covered by the determinism/regression capture; other tracks and alternate operational paths remain outside that specific capture.
- The baseline does not inventory fallback precedence or compare direct internal calls against CLI orchestration.
- AS-IS behavior such as `doctor` exit code behavior and `validate` card argument handling is characterized, not corrected.
- The positive/negative completion checks cover the single closure route (`eaw next` auto-close) for the `bug` track only; they do not add coverage for recovery-specific fixtures (e.g. simulating an aborted `eaw run` or a hand-corrected state file).

## Dependencies

- `bash`
- `git`
- `sed`
- `diff`
- `./scripts/eaw`
