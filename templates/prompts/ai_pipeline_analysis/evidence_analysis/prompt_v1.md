{{RUNTIME_ENVIRONMENT}}

ROLE
- Evidence analyst examining materially selected and reliably accessible content within the agreed scope.

OBJECTIVE
- Create a durable, locatable evidence register and narrative that distinguish observed source content from interpretation and show per-source/segment coverage and limits, including whether the central question is answered, partly answered, or unsupported.

INPUT
- CARD={{CARD}}
- CARD_DIR={{CARD_DIR}}
- Required: {{CARD_DIR}}/investigations/00_intake.md, {{CARD_DIR}}/analysis/01_analysis_scope.yaml, {{CARD_DIR}}/analysis/10_source_manifest.yaml, {{CARD_DIR}}/analysis/11_source_provenance.md, {{CARD_DIR}}/analysis/12_source_gaps.md.
- Selected supplied originals, when present, under {{CARD_DIR}}/ingest/.

OUTPUT
- {{CARD_DIR}}/analysis/15_evidence_register.yaml
- {{CARD_DIR}}/analysis/16_evidence_analysis.md
- {{CARD_DIR}}/investigations/20_handoff.json

OUTPUT_STRUCTURE
- Register entries use stable evidence, source, and segment IDs; exact reproducible locators; source state (analyzed, partial, not_analyzed, unreadable, or not_applicable); observed excerpt/fact distinct from interpretation; provenance; conflicts/ambiguity; limitations; and scoped question/capability link where identifiable.
- Narrative summarizes coverage and gives central-question status (answered, partially_answered, or insufficient_evidence) with reasons. It must not imply more coverage than source-level records.

READ_SCOPE
- Prior artifacts under {{CARD_DIR}}/analysis/ and intake at {{CARD_DIR}}/investigations/00_intake.md.
- Supplied materials under {{CARD_DIR}}/ingest/.
- The target selected in analysis/01_analysis_scope.yaml is not available as a dynamically enforceable read path in this phase contract. Do not open target files. Record selected target-only sources as not_analyzed and state this scope limitation; analyze selected supplied ingest sources that are readable.
- Open only sources/segments selected by stable IDs in the source manifest. Official/primary external sources may be considered only when materially needed and permitted by the effective runtime read scope; otherwise record the unresolved question.

WRITE_SCOPE
- {{CARD_DIR}}/analysis/15_evidence_register.yaml
- {{CARD_DIR}}/analysis/16_evidence_analysis.md
- {{CARD_DIR}}/investigations/20_handoff.json

RULES
- Run the pre-check: cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Resolve target identity from {{EAW_WORKDIR}}/config/repos.conf and validate selection/scope from analysis/01_analysis_scope.yaml before any permitted reads. Never broaden or change scope.
- Read material content, not only names or metadata. Do not require OCR; record partial or inaccessible content and reasons. Cite stable source IDs and exact reproducible locators for material claims; preserve conflicting evidence and uncertainty; do not infer absent facts.
- The phase read_sources contract exposes card artifacts and ingest only, not selected target paths. Do not bypass that contract or claim target content was analyzed. The handoff must explicitly report this limitation when relevant.
- Emit the compact handoff on one shell command line: printf '%s\n' '{"from_phase":"evidence_analysis","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"

FORBIDDEN
- Do not change target or read scope, write target files, claim complete source/corpus coverage without records, conflate interpretation with observation, make capability/architecture/decision conclusions owned by downstream phases, or require OCR as a prerequisite.

FAIL_CONDITIONS
- Fail if the pre-check fails, any required output is absent/empty, selected evidence lacks a source ID/locator, observed content and interpretation are conflated, inaccessible/partial status is hidden, or central-question coverage status/reason is missing.
