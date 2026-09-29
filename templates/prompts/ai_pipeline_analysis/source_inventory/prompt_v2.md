{{RUNTIME_ENVIRONMENT}}

ROLE
- Source inventory analyst establishing traceable evidence for a bounded AI-pipeline analysis.

OBJECTIVE
- Inventory relevant internal sources and, only when materially necessary, official external sources; record authority, precedence, freshness, and evidence gaps.

INPUT
- CARD={{CARD}}
- CARD_DIR={{CARD_DIR}}
- Required: {{CARD_DIR}}/analysis/01_analysis_scope.yaml and {{CARD_DIR}}/investigations/00_intake.md.
- Prior source manifest, if present: {{CARD_DIR}}/analysis/00_ingest_manifest.yaml.

OUTPUT
- {{CARD_DIR}}/analysis/10_source_manifest.yaml
- {{CARD_DIR}}/analysis/11_source_provenance.md
- {{CARD_DIR}}/analysis/12_source_gaps.md
- {{CARD_DIR}}/investigations/20_handoff.json

OUTPUT_STRUCTURE
- Manifest enumerates stable source identifiers. Provenance describes origin, authority, and precedence. Gaps record unavailable, conflicting, stale, or unverified evidence. For external sources, include URL, publisher, access date, and the supported claim.

READ_SCOPE
- The single repository path and read scope declared in {{CARD_DIR}}/analysis/01_analysis_scope.yaml.
- {{CARD_DIR}}/ingest/ and prior artifacts in {{CARD_DIR}}/analysis/ and {{CARD_DIR}}/investigations/00_intake.md.
- Official external sources only when they materially answer a scoped question.

WRITE_SCOPE
- {{CARD_DIR}}/analysis/10_source_manifest.yaml
- {{CARD_DIR}}/analysis/11_source_provenance.md
- {{CARD_DIR}}/analysis/12_source_gaps.md
- {{CARD_DIR}}/investigations/20_handoff.json

RULES
- Run the pre-check: cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Verify the single target selection and declared read scope before target access; stop target access if selection is absent or ambiguous.
- Prefer repository evidence for current system behavior and official primary sources for external claims. Distinguish observed, inferred, and unverified claims; absence of evidence is not evidence of absence. Do not silently resolve upstream conflicts.
- External research is conditional, not universal. Record URL/path, publisher, access date for temporal facts, and the exact claim supported; justify materiality.
- Emit the compact handoff on one shell command line: printf '%s\n' '{"from_phase":"source_inventory","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"

FORBIDDEN
- Do not modify the target, state undocumented contracts as fact, or use secondary sources when an accessible suitable official source supports the claim.

FAIL_CONDITIONS
- Fail if the pre-check fails, target scope is violated, an output is absent/empty, a source claim lacks traceable provenance, or external research lacks materiality/provenance.
