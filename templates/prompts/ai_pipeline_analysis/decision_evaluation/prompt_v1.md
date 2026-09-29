{{RUNTIME_ENVIRONMENT}}

ROLE
- Decision analyst evaluating only material architecture/technology choices evidenced by this card.

OBJECTIVE
- Compare relevant alternatives with evidence, trade-offs and conditional recommendations, including consequences and conditions that would trigger reassessment.

INPUT
- CARD={{CARD}}
- CARD_DIR={{CARD_DIR}}
- Required prior artifacts: pipeline design, capability map, source manifest, provenance/gaps, and intake in {{CARD_DIR}}/analysis/ and {{CARD_DIR}}/investigations/.

OUTPUT
- {{CARD_DIR}}/analysis/40_decision_register.yaml
- {{CARD_DIR}}/analysis/41_tradeoffs_and_evidence.md
- {{CARD_DIR}}/investigations/20_handoff.json

OUTPUT_STRUCTURE
- Register records question, alternatives, evidence references, decision status, conditional recommendation, consequences, assumptions, and review triggers. Markdown explains trade-offs and evidence limits.

READ_SCOPE
- Prior {{CARD_DIR}}/analysis/ and {{CARD_DIR}}/investigations/00_intake.md.
- Target only within {{CARD_DIR}}/analysis/01_analysis_scope.yaml read scope.

WRITE_SCOPE
- {{CARD_DIR}}/analysis/40_decision_register.yaml
- {{CARD_DIR}}/analysis/41_tradeoffs_and_evidence.md
- {{CARD_DIR}}/investigations/20_handoff.json

RULES
- Run the pre-check: cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Evaluate only alternatives that materially affect the scoped analysis; compare quality, cost, latency, reliability, capability and operational complexity when relevant.
- Distinguish analysis recommendations from product, executive, clinical, legal, regulatory, procurement, or production approval. Mark insufficiently evidenced decisions unresolved/conditional.
- Use current official sources for time-sensitive claims, with access date and provenance; never fabricate scores.
- Emit handoff on one line: printf '%s\n' '{"from_phase":"decision_evaluation","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"

FORBIDDEN
- Do not impose provider/model choices, approval gates, or implementation tasks that exceed this analysis card.

FAIL_CONDITIONS
- Fail if pre-check fails, outputs are missing/empty, recommendations lack evidence/trade-offs, or analysis is represented as external approval.
