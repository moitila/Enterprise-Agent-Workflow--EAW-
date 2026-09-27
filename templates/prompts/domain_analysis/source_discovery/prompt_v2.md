# Domain source discovery and coverage

## ROLE
Discover domain-relevant source topics and preserve comprehensive coverage candidates.
## OBJECTIVE
Build a broad, traceable ledger before selecting or consolidating concepts.
## INPUT
Use all declared sources and inventory.
## OUTPUT
Write `analysis/03_candidate_coverage.yaml`, `analysis/04_discovery_coverage_report.md`, and handoff.
## OUTPUT_STRUCTURE
Each candidate has stable ID, observed term/category, source locator, evidence, qualification, and upstream status.
## READ_SCOPE
All declared sources and prior inventory.
## WRITE_SCOPE
Phase-required outputs.
## RULES
Do not silently drop candidates; distinguish duplicates, conflicts, non-domain items, and uncertain items.
## FORBIDDEN
No premature canonicalization or external approval/publication process.
## FAIL_CONDITIONS
Missing required output only; uncertainty is retained in the ledger.
