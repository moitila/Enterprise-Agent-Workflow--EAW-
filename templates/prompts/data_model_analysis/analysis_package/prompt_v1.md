{{RUNTIME_ENVIRONMENT}}

ROLE
- Consolidate the reviewed conceptual and logical information model into a traceable human-readable and structured package.

OBJECTIVE
- Produce consistent final documents that preserve evidence, supported conclusions, uncertainty, conflicts, limitations, and open questions for downstream use.

INPUT
- CARD={{CARD}}
- CARD_DIR={{CARD_DIR}}
- Read all prior phase artifacts and handoffs under {{CARD_DIR}}.
- Reconcile the critical review with the analysis and declared source manifest; carry forward supported corrections.

OUTPUT
- Write only {{CARD_DIR}}/analysis/data-model-analysis.md, {{CARD_DIR}}/analysis/data-objects.yaml, {{CARD_DIR}}/analysis/data-relationships.yaml, {{CARD_DIR}}/analysis/data-lifecycles.yaml, and {{CARD_DIR}}/analysis/open-questions.md.

OUTPUT_STRUCTURE
- Markdown explains the model, evidence basis, conceptual decisions, relationships, lifecycle/integrity, scope limits, and unresolved areas.
- YAML files structure objects, relationships, and lifecycle/integrity mappings consistently, with stable identifiers and evidence references.
- Open questions collect TBDs, conflicts, upstream gaps, pending decisions, and dependencies.

READ_SCOPE
- {{CARD_DIR}} and source materials explicitly declared in the source manifest.

WRITE_SCOPE
- {{CARD_DIR}}/analysis/data-model-analysis.md
- {{CARD_DIR}}/analysis/data-objects.yaml
- {{CARD_DIR}}/analysis/data-relationships.yaml
- {{CARD_DIR}}/analysis/data-lifecycles.yaml
- {{CARD_DIR}}/analysis/open-questions.md

RULES
- Keep identifiers and evidence references consistent across all five documents.
- Distinguish evidence, inference, TBD, conflict, and open question; do not turn recommendations into decisions without support.
- Preserve gaps where upstream rules or source evidence are missing; do not rewrite upstream authority.
- Keep this conceptual/logical: do not specify physical schema, DDL, migrations, ORM, APIs, architecture, implementation, provider, or technical pipeline.
- No handoff is required: this is the final phase.

FORBIDDEN
- Do not run or initiate implementation or a downstream workflow.
- Do not add unsupported facts to make YAML fields appear complete.

FAIL_CONDITIONS
- Fail if any required output is absent or empty, or if documents contradict each other.
- Fail if evidence references or material uncertainties are lost during consolidation.
