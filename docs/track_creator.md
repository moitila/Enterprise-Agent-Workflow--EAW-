# track_creator — EAW Track

## Descrição

`track_creator` é a track EAW para criação e revisão de outras tracks EAW. Guia o
operador desde a coleta do requisito (intake) até a validação final da nova track,
passando por design, blueprinting de prompts, planejamento, execução e validação.

## Fases

A track possui **6 fases** em sequência:

| Fase                    | Artefato de saída                         | Responsabilidade                                              |
|-------------------------|-------------------------------------------|---------------------------------------------------------------|
| `intake`                | `investigations/00_intake.md`             | Coleta factual: objetivo, problema, resultado esperado, restrições |
| `track_design`          | `investigations/10_track_design.md`       | Design: fases, transições, phase.skills, magnitude, handoff   |
| `prompt_design`         | `investigations/20_prompt_design.md`      | Blueprint de prompts por fase                                 |
| `implementation_planning` | `implementation/00_scope.lock.md`, `implementation/10_change_plan.md` | Scope lock + change plan |
| `implementation_executor` | `implementation/20_patch_notes.md`      | Criação dos artefatos da track conforme o change plan         |
| `validation`            | `investigations/90_validation_report.md`  | Validação estrutural, phase.skills, registro, workflow        |

## Como usar

```bash
# Criar um card na track track_creator
cd /path/to/eaw
export EAW_WORKDIR=/path/to/.eaw
./scripts/eaw card MINHA-TRACK-NOVA --track track_creator "Criar track de onboarding"

# Avançar fases
./scripts/eaw next MINHA-TRACK-NOVA
```

## Scaffold de intake

Quando um card `track_creator` é criado, o runtime copia o scaffold
`templates/intake_track_creator.md` para `CARD_DIR/investigations/00_intake.md`.

O scaffold possui 8 seções:
- `## Objetivo da Track`
- `## Problema`
- `## Resultado Esperado`
- `## Restricoes Operacionais`
- `## Fontes Disponiveis`
- `## Riscos Conhecidos`
- `## Sugestoes do Usuario`
- `## Questoes em Aberto`

A fase `intake` exige as 5 seções obrigatórias (`required_headings`):
`Objetivo da Track`, `Problema`, `Resultado Esperado`, `Restricoes Operacionais`,
`Questoes em Aberto`.

## Resolução de template por track

O runtime detecta o tipo de card lendo o campo `card_state.track_id` do arquivo
`state_card_*.yaml` no `CARD_DIR`. Se `templates/intake_<track_id>.md` existir, esse
template é usado para o scaffold. Caso contrário, a lógica legada
(bug/spike/repo_onboarding/feature) é ativada como fallback.

A lógica de resolução é idêntica em `eaw_detect_card_template_type`
(`scripts/commands/eaw_commands.sh`) e `eaw_phase_completion_detect_card_template_type`
(`scripts/lib/phase_completion.sh`).

## phase.read_sources e placeholders portáteis

Cada fase declara `phase.read_sources` aninhado sob `phase:` no YAML da fase
(`tracks/track_creator/phases/<fase>.yaml`). Os itens usam placeholders portáteis:

```yaml
phase:
  read_sources:
    - "{{RUNTIME_ROOT}}/docs/WORKFLOW_YAML_CONTRACT.md"
    - "{{CARD_DIR}}/investigations"
```

Placeholders suportados: `{{RUNTIME_ROOT}}`, `{{CARD_DIR}}`, `{{OUT_DIR}}`,
`{{EAW_WORKDIR}}`. O runtime resolve cada placeholder para o path absoluto
correspondente antes de injetar o bloco `READ_SOURCES:` no prompt do agente.

Veja `docs/WORKFLOW_YAML_CONTRACT.md` (seção "Phase Read Sources Block") para
o contrato completo.

## Referências

- `tracks/track_creator/track.yaml` — definição da track e transições
- `tracks/track_creator/phases/` — YAMLs de cada fase
- `templates/prompts/track_creator/` — prompts soberanos por fase
- `templates/intake_track_creator.md` — scaffold de intake
- `docs/WORKFLOW_YAML_CONTRACT.md` — contrato de phase.read_sources
- `docs/PROMPT_GOVERNANCE.md` — contrato de prompts e READ_SCOPE
