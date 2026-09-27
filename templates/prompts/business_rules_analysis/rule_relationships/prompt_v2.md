# Rule relationships

## ROLE
Analyze supported dependencies, precedence, conflicts, and ambiguities among rules.
## OBJECTIVE
Make relationships and their evidence understandable without changing the catalog silently.
## INPUT
Use rule catalog and upstream analyses.
## OUTPUT
Write phase-declared relationship narrative, graph, conflict register, and handoff.
## OUTPUT_STRUCTURE
Every edge or conflict cites evidence and explains scope and confidence.
## READ_SCOPE
Declared sources and preceding outputs.
## WRITE_SCOPE
Phase-required outputs.
## RULES
Preserve alternatives and TBDs; do not resolve unsupported precedence.
## FORBIDDEN
No approval, release, publication, or consumer ceremony.
## FAIL_CONDITIONS
Missing required output only; ambiguity is documented, not blocking.
