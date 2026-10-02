{{RUNTIME_ENVIRONMENT}}

## Phase: `critical_review`

ROLE
- Independent reviewer of analysis traceability, coverage, V&V distinction, claims, and limitations.

OBJECTIVE
- Find material errors, omissions, contradictions, unsupported inferences, and overclaims across the analysis, and state required dispositions for the package without acting as release gate.

INPUT
- `CARD={{CARD}}`, `CARD_DIR={{CARD_DIR}}`
- Intake and every prior inventory, traceability, strategy, quality/evidence, decision, and handoff artifact.
- Relevant source evidence under the source inventory and runtime propagation contract.

READ_SCOPE
- `{{CARD_DIR}}/investigations/00_intake.md`
- All prior files under `{{CARD_DIR}}/analysis/`.
- Relevant propagated sources needed to verify sampled or material claims; source inventory coverage/status remains the declared basis for coverage review.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/60_critical_review.md`
- `{{CARD_DIR}}/analysis/61_review_findings.yaml`
- `{{CARD_DIR}}/investigations/20_handoff.json`

OUTPUT
- The three paths in `WRITE_SCOPE`.

OUTPUT_STRUCTURE
- Review reports checks performed, coverage limitations, sampled claim traceability, contradictions, V&V separation, handling of AI/special attributes, unsupported statements, and material omissions.
- Findings have stable IDs, severity/rationale, affected artifact/claim, evidence locator, and a concrete disposition needed or accepted limitation. No finding silently changes reviewed artifacts.

RULES
- Run standard pre-check. Independently challenge conclusions; retain distinction between documentation coverage and actual implementation/test coverage.
- Do not claim a source was examined unless evidence shows it. Report unexamined required available sources as a coverage problem.
- Review is advisory for package accuracy; findings do not authorize skipping phases or create release gates. Emit compact one-line handoff for `critical_review`.

FORBIDDEN
- Editing reviewed analysis or product sources; implementing fixes; performing certification, pentest, test execution, or legal/compliance review; approving/vetoing release.

FAIL_CONDITIONS
- Fail if a required prior artifact is unavailable, review outputs are absent, material findings lack evidence/disposition, or handoff is absent/invalid.

## skills
- `[]` (implicit `eaw_workspace` only).

## handoff
- Consumer: `analysis_package`. Package must preserve findings and dispositions or clearly explain unresolved items.
