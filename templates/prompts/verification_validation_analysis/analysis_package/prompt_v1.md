{{RUNTIME_ENVIRONMENT}}

## Phase: `analysis_package` (final)

ROLE
- Analysis documentation packager selecting authorized product destinations and persisting the final V&V analysis through the runtime delivery contract.

OBJECTIVE
- Consolidate the reviewed, source-grounded analysis into a coherent report, traceability matrix, and decisions/questions documents; select delivery targets explicitly based on card objective and observed conventions, then persist through the runtime-derived allowlist.

INPUT
- `CARD={{CARD}}`, `CARD_DIR={{CARD_DIR}}`, `CONFIG_SOURCE={{CONFIG_SOURCE}}`
- Required intake and all outputs/handoffs through critical review.
- Runtime `TARGET_DELIVERY_CANDIDATES`, `TARGET_DELIVERY_DECLARED_PATHS`, `ANALYSIS_DELIVERY_HELPER`, and `ANALYSIS_DELIVERY_PHASE_FILE` when supplied.
- Relevant existing target documentation conventions, within declared read scope.

READ_SCOPE
- Prior `{{CARD_DIR}}/investigations/00_intake.md` and all `{{CARD_DIR}}/analysis/` outputs.
- Candidate root documentation needed to establish naming/path conventions, using only role=`target` roots from `{{CONFIG_SOURCE}}`; do not treat EAW runtime documentation as product evidence merely because EAW is a target.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/70_package_handoff.md`
- Product documents only at exact destinations derived by the delivery helper from explicit `DELIVERY_TARGETS` and runtime-declared paths.

OUTPUT
- Product-facing V&V report, traceability matrix, and decisions/questions document(s) at semantically named paths selected from available destination conventions; no card ID in product paths.
- `{{CARD_DIR}}/analysis/70_package_handoff.md`.

OUTPUT_STRUCTURE
- Product documents preserve evidence IDs/locators, provenance, coverage and status, observed/inferred/unknown distinctions, separate verification and validation, applicable special/AI evaluation, decisions, questions, critical findings/dispositions, and limitations.
- Handoff begins with a YAML `DELIVERY_TARGETS:` list of exact keys from `TARGET_DELIVERY_CANDIDATES`; records exact persisted paths, measured byte sizes, included/omitted material, unresolved questions, `ANALYSIS_STATUS`, `COVERAGE_STATUS`, `REQUIRED_AVAILABLE_NOT_EXAMINED`, and `PERSISTENCE_STATUS`.
- Report completion only for the status supported by examined sources and verified persisted files. It is a record, not proof of persistence or a runtime gate.
- Product-facing content must not expose phase names, prompt mechanics, card state, EAW paths, orchestration commands, or internal implementation details unless strictly needed as technical evidence provenance.

RULES
- Run standard pre-check. Read and validate `{{CONFIG_SOURCE}}`; choose only suitable role=`target` candidates based on objective and observed conventions. Never select all roots by default or derive delivery from the evidence-source manifest.
- Before target writes, create `{{CARD_DIR}}/analysis/70_package_handoff.md` declaring the explicit `DELIVERY_TARGETS` list. Source `ANALYSIS_DELIVERY_HELPER` and invoke `eaw_delivery_persist_selected_file` with source, destination, `{{CONFIG_SOURCE}}`, the runtime-provided `ANALYSIS_DELIVERY_PHASE_FILE`, `{{CARD_DIR}}/implementation/00_scope.lock.md`, `{{CARD}}`, and the handoff path, in that order.
- Do not create or edit a manual allowlist and do not write directly to target. Persist only exact paths in the helper-derived `TARGET_DELIVERY_ALLOWLIST`; honor scope-lock restrictions. If the helper or scope prevents delivery, record the blocker and do not bypass it.
- Verify every claimed persisted path exists and measure its size before reporting `PERSISTENCE_STATUS: PERSISTED`. Preserve review findings; do not claim publication, approval, test execution, certification, compliance, or release readiness.

FORBIDDEN
- Writing outside the handoff and helper-authorized target paths; direct target writes; choosing delivery by source membership; adding implementation or release gates; leaking EAW orchestration into product documentation; claiming unsupported coverage or completion.

FAIL_CONDITIONS
- Fail if any required prior artifact is unavailable, destination candidates or runtime helper contract are absent/ambiguous, handoff with explicit targets is missing, any target write bypasses helper-derived authorization, a claimed persisted document is absent, or final content drops material provenance, limitations, or critical findings. If delivery is blocked, report a specific incomplete status in the handoff path declared in `WRITE_SCOPE`.

## skills
- `[]` (implicit `eaw_workspace` only).

## handoff
- Terminal phase. No next-phase handoff JSON is required by the design; `70_package_handoff.md` records the delivery selection and outcome. Runtime completion remains governed by declared artifacts and the standard final transition.

## Structural checks applied

- All ten design phases have a corresponding block in the same order.
- Every intermediate phase declares its handoff in `OUTPUT`, `WRITE_SCOPE`, and `FAIL_CONDITIONS`; the final packaging phase is terminal and uses the delivery handoff instead of inventing a next transition.
- Artifact producer/consumer paths correspond to `10_track_design.md`; each output path is authorized in the phase's `WRITE_SCOPE`.
- Canonical double-brace placeholders are used throughout operational paths. Literal shell commands are examples for execution, not single-brace template references.
- No prompt requests test implementation, execution, certification, compliance determination, or release approval.
- Delivery selection and persistence are delegated to the existing runtime contract; no manual source allowlist or direct product write is introduced.
