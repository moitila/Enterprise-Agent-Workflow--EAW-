# INGEST_TRANSITION

## Modelo de diretorios durante a transicao

- `out/<CARD>/ingest/` — origem primaria de insumos brutos (quando existir)
- `out/<CARD>/intake/` — fallback temporario compativel

## Estado mutavel do card

- Novos cards: `out/<CARD>/state_card_*.yaml` (raiz do card)
- Cards legados: `out/<CARD>/intake/state_card_*.yaml` (fallback ativo)
- Implementacao: funcao `eaw_load_card_workflow_context` em `scripts/commands/eaw_commands.sh`

## Criterio de encerramento

Ver criterio formal em `docs/WORKFLOW_YAML_CONTRACT.md` (secao End-of-transition criterion).

## Arquivos afetados por esta transicao

- docs/WORKFLOW_YAML_CONTRACT.md
- docs/PROMPT_CONTRACT_INTAKE_v1.md
- tracks/feature/phases/ingest.yaml
- tracks/feature/phases/intake.yaml
- tracks/feature/track.yaml
- scripts/commands/eaw_commands.sh
- scripts/eaw_core.sh
