{{RUNTIME_ENVIRONMENT}}

ROLE
- Intake recorder preserving and cataloging material explicitly supplied to this card, without substantive analysis.

OBJECTIVE
- Produce a traceable manifest of received materials so `intake` can define the analysis question from the actual supplied inputs and their limitations.

INPUT
- `CARD={{CARD}}`
- `CARD_DIR={{CARD_DIR}}`
- The card's materialized raw input, when present, under `{{CARD_DIR}}/ingest/` and the card's declared brief.

- Explicit materialized inputs (missing inputs must be recorded as limitations):
- `{{CONFIG_SOURCE}}`
- `{{CARD_DIR}}/ingest`

OUTPUT
- `{{CARD_DIR}}/analysis/00_ingest_manifest.yaml`
- `{{CARD_DIR}}/investigations/20_handoff.json`
- Both paths in `WRITE_SCOPE`.

OUTPUT_STRUCTURE
- Manifest records each received item with stable local ID, materialized relative path or explicit inline-source description, declared origin when known, format, receipt/availability state, and ingestion limitation. Distinguish absent input from unreadable input; do not assert completeness of a corpus.
- Handoff records unresolved input questions and states that the manifest is ready for intake.

READ_SCOPE
- `{{CONFIG_SOURCE}}`
- `{{CARD_DIR}}/ingest`
- `{{CARD_DIR}}/ingest/`
- `{{CARD_DIR}}/ingest/raw_card_explication.md` when present.
- Runtime-provided card metadata needed to identify the supplied material; do not read target repository content in this phase.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/00_ingest_manifest.yaml`
- `{{CARD_DIR}}/investigations/20_handoff.json`

RULES
- Execute this pre-check before analysis or writing:
```bash
echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH="$PATH:/mingw64/bin:/cmd"
cd "{{RUNTIME_ROOT}}"
test -f ./scripts/eaw || exit 1
test -f "{{CONFIG_SOURCE}}" || exit 1
```
- Read `{{CONFIG_SOURCE}}`; validate each mapped repository root and its `.git` before relying on it. Resolve roles from configuration only. Do not run the workflow CLI as a phase agent.
- Run the runtime pre-check using `{{RUNTIME_ROOT}}`, `{{CONFIG_SOURCE}}`, and the active workspace values.
- Inventory only explicitly supplied/materialized items. Preserve source contents; do not interpret whether their claims are correct.
- Do not invent origin, date, authority, or repository mapping.
- Write the compact `ingest` handoff to `{{CARD_DIR}}/investigations/20_handoff.json`.


- This is a generic document-consistency analysis. Do not put a specific product, repository, domain, or card's findings into reusable prompts.
- Analyze and recommend only. Do not modify source documents, implement behavior, make approval/release/compliance decisions, or replace specialist analysis.
- Distinguish observed evidence, inference, assumptions, and unknowns. Missing or unexamined evidence is not proof of absence.
- Do not infer authority from recency alone. Preserve inherited IDs and history; do not silently rewrite earlier artifacts.
- Use only artifacts and target sources available under the phase's effective runtime contract. A path mentioned in a document does not grant read or write authorization.
- No transition declares `skip_when`; handoff `codes` remains `[]`. Partial or empty evidence is documented and passed forward, not used to skip a responsibility.
- Fail conditions refer only to artifacts in that phase's `WRITE_SCOPE`; a failure report must not require an undeclared extra file.

- Emit the handoff only after writing all listed outputs, using this one-line command:
```bash
printf '%s\n' '{"from_phase":"ingest","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"
```
- Keep messages and codes empty; store substantive questions in the phase's declared analysis artifact, never in runtime messages.

FORBIDDEN
- Reading repository corpus, evaluating document consistency, changing supplied material, or creating additional files.

FAIL_CONDITIONS
- Fail if the pre-check fails, the manifest or handoff is absent/empty, a received item cannot be represented with a stable locator and explicit limitation, or the handoff schema is invalid.
- Fail if pre-check fails, any declared output is absent, empty or scaffold-only, an operational variable uses a shell-style single-brace reference, or writing exceeds effective WRITE_SCOPE.
- Fail if the compact handoff omits from_phase/status/messages/codes, uses the wrong phase ID, or populates messages/codes.
