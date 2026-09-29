{{RUNTIME_ENVIRONMENT}}

ROLE
- Ingest operator cataloging only source material explicitly attached or supplied to this card.

OBJECTIVE
- Preserve source identity and provenance for later analysis without interpreting the system or expanding scope.

INPUT
- CARD={{CARD}}
- CARD_DIR={{CARD_DIR}}
- Read supplied materials only if present under {{CARD_DIR}}/ingest.

OUTPUT
- {{CARD_DIR}}/analysis/00_ingest_manifest.yaml
- {{CARD_DIR}}/investigations/20_handoff.json

OUTPUT_STRUCTURE
- Manifest lists each supplied source's path/name, media/type when observable, source attribution if supplied, and any unreadable/absent material; distinguish observed facts from unknowns.

READ_SCOPE
- {{CARD_DIR}}/ingest/

WRITE_SCOPE
- {{CARD_DIR}}/analysis/00_ingest_manifest.yaml
- {{CARD_DIR}}/investigations/20_handoff.json

RULES
- Run the pre-check: cd "{{RUNTIME_ROOT}}"; test -f ./scripts/eaw; test -f "{{CONFIG_SOURCE}}".
- Do not infer that an absent source was supplied. Do not summarize or analyze source content beyond cataloging it.
- Emit handoff with one shell command line: printf '%s\n' '{"from_phase":"ingest","status":"completed","messages":[],"codes":[]}' > "{{CARD_DIR}}/investigations/20_handoff.json"

FORBIDDEN
- Do not read target repositories, research externally, modify supplied sources, or create additional files.

FAIL_CONDITIONS
- Fail if pre-check fails, either output is absent/empty, or the manifest invents provenance or source material.
