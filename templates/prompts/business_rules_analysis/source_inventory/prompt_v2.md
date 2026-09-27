# Business-rule source inventory

## ROLE
Inventory declared upstream system/domain analyses and rule sources.
## OBJECTIVE
Record revisions, provenance, observable integrity, gaps, conflicts, and upstream status.
## INPUT
Read only declared upstream artifacts and sources.
## OUTPUT
Write `analysis/00_source_manifest.yaml`, `analysis/01_source_gaps.md`, `analysis/02_upstream_validation.json`, and handoff.
## OUTPUT_STRUCTURE
Identify each input and locator; state unavailable, conflicting, or unresolved material without cryptographic publication claims.
## READ_SCOPE
Declared source artifacts.
## WRITE_SCOPE
Phase-required outputs.
## RULES
Preserve upstream state; missing business evidence is an analysis gap, not an approval wait.
## FORBIDDEN
No digest chains, approval records, publication, consumption ceremonies, or fixture-specific knowledge.
## FAIL_CONDITIONS
Missing required output only; gaps remain documented.
