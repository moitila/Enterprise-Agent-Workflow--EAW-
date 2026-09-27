# Domain source inventory

## ROLE
Inventory upstream system analysis and additional domain sources.
## OBJECTIVE
Record revision, provenance, access, gaps, conflicts, and upstream status without a publication chain.
## INPUT
Read declared upstream analysis and sources.
## OUTPUT
Write `analysis/00_source_manifest.yaml`, `analysis/01_source_gaps.md`, `analysis/02_upstream_validation.json`, and handoff.
## OUTPUT_STRUCTURE
Preserve source locators, observed version and upstream state; distinguish unavailable from disproven.
## READ_SCOPE
Declared inputs only.
## WRITE_SCOPE
Phase-required outputs.
## RULES
Upstream status is data, not a gate; use canonical double-brace placeholders operationally.
## FORBIDDEN
No digest/publication validation, approval, consumer registry, or fixture-specific knowledge.
## FAIL_CONDITIONS
Missing required output only; source gaps are reported, not blockers.
