# SKILL: EAW Continuous Improvement — lessons

## Objetivo

Guiar o operador a capturar aprendizados de execuções reais de forma estruturada
e indexada por track/fase, para identificação de padrões ao longo do tempo.

Esta skill é **opt-in e manual**. Não é executada automaticamente.

## Estrutura de artefatos no workspace

```
$EAW_WORKDIR/
  ci_feedback/
    <track_id>/
      <phase_id>/
        feedback_<CARD_ID>.md      ← operador/agente preenche manualmente
    _synthesis/
      <track_id>_<phase_id>.md     ← orquestrador escreve após análise cross-card
    _backlog/
      improvement_suggestions.md   ← itens que justificam entrada no backlog formal
```

## Formato de `feedback_<CARD_ID>.md`

```markdown
# CI Feedback — <CARD_ID> / <track> / <phase>
Data: <YYYY-MM-DD>

## Prompt issues
(problemas com o prompt renderizado da fase)

## Runtime issues
(comportamentos inesperados do runtime EAW)

## Missing context
(contexto que faltou para o agente executar bem)

## Artifact contract issues
(problemas com nomes, schema ou completude de artefatos)

## Skill/trap suggestions
(nova trap a documentar, ajuste de skill, regra nova)

## Suggested backlog items
(melhorias que justificam card formal)

## Token/cost observations
(fase custosa demais, prompt muito longo, iterações desnecessárias)
```

## Classificação dos aprendizados

O orquestrador decide o destino de cada sugestão:

| Tipo de aprendizado | Destino |
|---------------------|---------|
| Trap operacional recorrente | `skills/EAW_operator/traps.md` |
| Regra de execução | `skills/EAW_operator/card_execution.md` |
| Regra de workspace | `skills/EAW_operator/workspace.md` |
| Problema de prompt/template | backlog de template |
| Problema de runtime | backlog de runtime |
| Caso específico do card | permanece em `out/<CARD>/` |
| Sugestão contraditória entre fases | análise adicional do orquestrador |

## Como usar — passo a passo

1. Ao final de um card (ou fase crítica), o operador ou orquestrador avalia a execução
2. Se houver observações relevantes, cria `$EAW_WORKDIR/ci_feedback/<track>/<phase>/feedback_<CARD>.md`
3. Preenche as seções aplicáveis (seções vazias = sem observação para aquela categoria)
4. Periodicamente, o orquestrador lê todos os feedbacks de um track/phase e sintetiza padrões
5. Síntese vai para `_synthesis/<track>_<phase>.md`
6. Itens recorrentes (2+ cards) são candidatos a `_backlog/improvement_suggestions.md` ou backlog formal

## Como sintetizar (orquestrador)

```
Para: $EAW_WORKDIR/ci_feedback/<track>/<phase>/
Leia todos os feedback_*.md
Identifique:
  - Sugestões recorrentes (aparecem em 2+ cards)
  - Conflitos entre feedbacks de fases adjacentes
  - Ruído local vs problema sistêmico
Escreva síntese em: _synthesis/<track>_<phase>.md
Decida: backlog formal, traps, skill, template ou descarte
```

## Limites absolutos

- NÃO criar CLI ou automação antes de evidência de padrão (Parte 2 — spike futura)
- NÃO modificar runtime com base em sugestão de card único
- NÃO tratar feedback de agente como decisão — é sinal, não autoridade
- NÃO duplicar conteúdo de `traps.md` — feedback é insumo, trap é destino confirmado
