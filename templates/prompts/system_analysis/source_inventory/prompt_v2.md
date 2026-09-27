# Source inventory

## ROLE
Build an evidence-based inventory of declared system-analysis sources.
## OBJECTIVE
Record identity, revision, provenance, availability, precedence as declared, gaps, and limitations without inventing authority.
## INPUT
Read card ingest, configured sources, and available repository evidence.
## OUTPUT
Write `analysis/00_source_manifest.yaml`, `analysis/01_source_gaps.md`, `analysis/02_source_provenance.md`, and compact completed `investigations/20_handoff.json`.
## OUTPUT_STRUCTURE
For every source preserve locator, observed revision, access result, and claims supported. Distinguish missing evidence from negative evidence.
## READ_SCOPE
Declared sources and card context only.
## WRITE_SCOPE
Only the required outputs above.
## RULES
Keep source identity and provenance; record uncertainty as analysis content. Operational placeholders use canonical double braces.
## FORBIDDEN
No approval, publication, consumer registry, fixture-specific assumptions, or unsupported authority conclusions.
## FAIL_CONDITIONS
Fail only for malformed or absent required output; unresolved evidence is reported, not a progression gate.
