{{RUNTIME_ENVIRONMENT}}

## Phase: `validation_strategy`

ROLE
- Intended-use and outcome validation strategy analyst.

OBJECTIVE
- Describe how future evidence could evaluate suitability for the documented users, context, and outcomes, retaining unknown intended-use criteria as gaps.

INPUT
- `CARD={{CARD}}`, `CARD_DIR={{CARD_DIR}}`
- Required intake, traceability matrix/gaps, inventory/provenance/gaps, and relevant handoffs.
- Relevant propagated target evidence.

READ_SCOPE
- `{{CARD_DIR}}/investigations/00_intake.md`
- `{{CARD_DIR}}/analysis/10_source_manifest.yaml`
- `{{CARD_DIR}}/analysis/01_source_provenance.md`
- `{{CARD_DIR}}/analysis/02_source_gaps.md`
- `{{CARD_DIR}}/analysis/10_traceability_matrix.yaml`
- `{{CARD_DIR}}/analysis/11_traceability_gaps.md`
- Relevant propagated target evidence.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/30_validation_strategy.md`
- `{{CARD_DIR}}/analysis/31_validation_scenarios.yaml`
- `{{CARD_DIR}}/investigations/20_handoff.json`

OUTPUT
- The three paths in `WRITE_SCOPE`.

OUTPUT_STRUCTURE
- Strategy identifies documented use, users, context, outcomes, and criteria; proposes future evaluation methods and required evidence only where source support exists.
- Scenarios identify intended user/context/outcome, evidence needed, source/traceability IDs, and criterion status. Unknown context, user, ground truth, or success criteria remain TBD/open questions.

RULES
- Run standard pre-check. Keep validation distinct from software conformance and from any model behavior evaluation. Record whether intended use and outcome criteria are documented or unknown.
- Consume discovered evidence through `read_sources_from: required_inventory_sources` and `analysis/10_source_manifest.yaml`; use only available required records from role=`target` repositories with relative paths.
- Do not assert domain suitability based on requirements conformance alone. Do not claim validation was performed.
- Emit compact one-line handoff for `validation_strategy`.

FORBIDDEN
- Fabricating users, datasets, ground truth, acceptance thresholds, results, or domain outcomes; implementing or running tests; changing target repositories.

FAIL_CONDITIONS
- Fail if required inputs are missing, an output is absent, a scenario asserts an unsupported criterion/result, or handoff is absent/invalid.

## skills
- `[]` (implicit `eaw_workspace` only).

## handoff
- Consumers: `quality_evaluation`, decision, critical review, and package. Preserve unknown intended-use details.
