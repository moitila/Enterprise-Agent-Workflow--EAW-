{{RUNTIME_ENVIRONMENT}}

ROLE
- Inventory declared source materials for a reusable information-model analysis.

OBJECTIVE
- Record what sources are available, their observable identity and declared authority, plus gaps and limitations. Do not perform the model analysis in this phase.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- Read card-provided source declarations and materials under {{CARD_DIR}}/ingest when present.
- Upstream consolidated analyses and other primary materials are inputs only when declared or supplied in the card.

OUTPUT
- Write only {{CARD_DIR}}/analysis/00_source_manifest.yaml, {{CARD_DIR}}/analysis/01_source_gaps.md, and {{CARD_DIR}}/investigations/20_handoff.json.

OUTPUT_STRUCTURE
- 00_source_manifest.yaml: sources with stable local identifier, location, type, observable revision/date when available, declared authority, analytical role, and availability.
- 01_source_gaps.md: missing, unavailable, conflicting, incomplete, or ambiguous sources and their analytical limitations.
- Handoff compact JSON with from_phase, status, messages, and codes; normal codes is an empty array.

READ_SCOPE
- {{CARD_DIR}} and materials explicitly declared by the card. Do not scan unrelated repositories or infer source locations.

WRITE_SCOPE
- {{CARD_DIR}}/analysis/00_source_manifest.yaml
- {{CARD_DIR}}/analysis/01_source_gaps.md
- {{CARD_DIR}}/investigations/20_handoff.json

RULES
- Distinguish observed source facts from declared authority and your own inference.
- Preserve conflicts and source gaps without resolving authority by assumption.
- Do not calculate hashes/digests or create publication/governance records.
- A source gap alone does not block later analysis; report a concrete impossibility only if no meaningful analysis can proceed.
- Emit handoff in compact JSON. Write it on one shell line with printf, for example: printf '%s' '{"from_phase":"source_inventory","status":"completed","messages":["Manifest and source gaps recorded."],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"

FORBIDDEN
- Do not characterize or model information objects, relationships, or lifecycles in this phase.
- Do not modify source materials.

FAIL_CONDITIONS
- Fail if any required output is absent or empty.
- Fail if source identity, declared authority, or availability is represented as verified without observable evidence.
