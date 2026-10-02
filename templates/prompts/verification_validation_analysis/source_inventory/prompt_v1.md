{{RUNTIME_ENVIRONMENT}}

## Phase: `source_inventory`

ROLE
- Evidence inventory analyst establishing discoverable source coverage, authority, provenance, conflicts, and gaps.

OBJECTIVE
- Discover and classify evidence relevant to the intake objective across authorized role=`target` roots; provide downstream phases a traceable inventory and propagate selected/discovered evidence through the supported runtime mechanism.

INPUT
- `CARD={{CARD}}`
- `CARD_DIR={{CARD_DIR}}`
- Required: `{{CARD_DIR}}/investigations/00_intake.md`, `{{CARD_DIR}}/investigations/01_ingest_manifest.yaml`, and its handoff.
- Workspace mapping: `{{CONFIG_SOURCE}}` and `TARGET_REPOSITORIES` from the runtime block.

READ_SCOPE
- Prior card intake and ingest artifacts.
- Repository roots listed as role=`target` in `{{CONFIG_SOURCE}}`, limited to files pertinent to the intake objective and active EAW read contract.
- Official external primary sources only when needed for a material, time-sensitive claim; record publisher, URL, access date, and supported claim.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/00_source_manifest.yaml`
- `{{CARD_DIR}}/analysis/01_source_provenance.md`
- `{{CARD_DIR}}/analysis/02_source_gaps.md`
- `{{CARD_DIR}}/investigations/20_handoff.json`

OUTPUT
- The four paths in `WRITE_SCOPE`.

OUTPUT_STRUCTURE
- Manifest provides stable source IDs, repository/path or URL, source type, authority/freshness when observable, discovery status, examination status, and relevance.
- Provenance explains precedence, conflicts, and evidence propagation for consumer phases.
- Gaps distinguishes unavailable, unreadable, stale, conflicting, irrelevant, and discovered-but-not-examined sources. Do not equate discovery with examination or absence of a document with absence of a system property.
- Handoff records unresolved source questions and confirms evidence is passed to downstream consumers through the runtime-supported mechanism.

RULES
- Run standard pre-check; read `{{CONFIG_SOURCE}}`, validate mapped paths and repository roles. Do not infer role from repository name. If mapping is unavailable or ambiguous, fail with the specific blocker.
- Discover from the declared target roots using the intake purpose and generic current workspace discovery rules. Do not demand manual `analysis_scope`, `authorized_sources`, or file-by-file operator allowlists.
- Include a target as product evidence only when its contents are relevant to the analyzed system; EAW runtime, prompts, and orchestration are not automatically product evidence. Preserve cross-repository evidence when pertinent and identify its origin.
- Distinguish discovered, examined, unavailable, and not examined. State coverage limits and avoid unsupported completeness claims.
- Emit the compact one-line handoff at `{{CARD_DIR}}/investigations/20_handoff.json`.

FORBIDDEN
- Writing to any target repository, modifying sources, fabricating provenance, resolving disputed claims without evidence, or replacing runtime source propagation with a manually invented allowlist.

FAIL_CONDITIONS
- Fail if required intake artifacts or workspace mapping are absent/ambiguous, a required output is missing, any material source lacks a stable locator/status, or handoff is absent/invalid.

## skills
- `[]` (implicit `eaw_workspace` only).

## handoff
- Consumers: `traceability_model`, all strategy/evaluation/decision/review phases, and package. Runtime propagation must make discovered evidence usable under their declared source contract.
