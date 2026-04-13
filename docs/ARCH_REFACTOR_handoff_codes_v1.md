# ARCH_REFACTOR Handoff Codes Catalog — v1

**Versão**: v1
**Track**: ARCH_REFACTOR
**Origem**: card 622 (`ARCH_REFACTOR_ONBOARD`)
**Data**: 2026-04-11
**Status**: fechado (v1 — extensível via card futuro)

---

## Propósito

Este catálogo define os codes estáveis de handoff para o track `ARCH_REFACTOR`, usados na camada de orquestração de transição (`20_handoff.json`). Os codes são produzidos pela fase `hypotheses` e consumidos pela lógica de transição `skip_when` declarada em `track.yaml`.

A separação em dois contratos é mandatória (D-L3):
1. **`phase_output`** — domínio interno da fase `hypotheses` (campos: `code_deviation_count`, `deviation_type`, `adherence`)
2. **`20_handoff.json`** — camada de orquestração com codes estáveis para transição

Os campos de domínio interno **não podem** ser referenciados diretamente por `skip_when`. O `skip_when` opera exclusivamente sobre codes do catálogo.

---

## Catálogo de Codes

### `NO_CODE_DEVIATION`

**Descrição**: Nenhum desvio de código foi detectado durante a fase `hypotheses`. A análise confirmou conformidade de código sem desvios identificáveis.

**Condição de emissão**: O output interno da fase indica ausência de desvio de código (`code_deviation_count: 0`).

**Semântica para skip_when**: A fase `hypotheses` não agrega valor quando não há desvio a investigar. O card pode avançar diretamente para `planning`.

---

### `INFORMATIONAL_ONLY`

**Descrição**: As observações da fase `hypotheses` são informacionais — descrevem o estado atual sem prescrever ação arquitetural. Não há hipótese acionável.

**Condição de emissão**: O output interno da fase indica que as observações são de natureza informacional sem prescrição arquitetural (`deviation_type: informational_only`).

**Semântica para skip_when**: Hipóteses informacionais não adicionam incerteza residual relevante ao planejamento. O card pode avançar para `planning` sem loss de informação.

---

### `ADHERENCE_CONFIRMED`

**Descrição**: A fase `hypotheses` confirmou que o artefato analisado adere ao padrão alvo. Nenhuma hipótese de desvio foi identificada.

**Condição de emissão**: O output interno da fase indica conformidade completa com o padrão de referência (`adherence: all_confirmed`).

**Semântica para skip_when**: Conformidade confirmada não gera hipóteses úteis. O card pode avançar para `planning` diretamente.

---

## Mapeamento campo→code

Tabela explícita de mapeamento entre campos de domínio interno (`phase_output`) e codes estáveis de handoff:

| Campo `phase_output` | Valor | Code `20_handoff.json` |
|---|---|---|
| `code_deviation_count` | `0` | `NO_CODE_DEVIATION` |
| `deviation_type` | `informational_only` | `INFORMATIONAL_ONLY` |
| `adherence` | `all_confirmed` | `ADHERENCE_CONFIRMED` |

**Regra de precedência** (para casos de múltiplos campos satisfeitos simultaneamente):

1. `NO_CODE_DEVIATION` — prioridade mais alta (ausência de desvio supera os demais)
2. `ADHERENCE_CONFIRMED` — prioridade intermediária
3. `INFORMATIONAL_ONLY` — prioridade mais baixa

**Nota**: O mapeamento é 1-para-1 em execução normal. Casos de múltiplos campos ativos simultaneamente são edge-cases; a precedência acima garante determinismo. Casos sem nenhum campo ativo não emitem code e a fase `hypotheses` não é skipável.

---

## Estrutura do 20_handoff.json

O artefato `20_handoff.json` é produzido pela fase `hypotheses` como output de orquestração. Estrutura mínima:

```json
{
  "type": "recommendation",
  "code": "<CODE>",
  "text": "<descrição legível da condição que gerou o code>"
}
```

**Campo `type`**: fixo como `"recommendation"` para esta versão.
**Campo `code`**: um dos 3 values do catálogo: `NO_CODE_DEVIATION`, `INFORMATIONAL_ONLY`, `ADHERENCE_CONFIRMED`.
**Campo `text`**: string livre descrevendo a condição específica observada na execução.

---

## Uso em skip_when

O campo `skip_when` declarado em `transitions.findings` do `track.yaml` referencia os codes deste catálogo:

```yaml
transitions:
  findings:
    next: hypotheses
    skip_when:
      - NO_CODE_DEVIATION
      - INFORMATIONAL_ONLY
      - ADHERENCE_CONFIRMED
```

**Status de enforcement**: `skip_when` é declarativo (v1). O engine atual não interpreta este campo — ele é normativo para documentar a intenção de skip. Enforcement de runtime está planejado para o card `614A`.

---

## Extensibilidade

Este catálogo é **v1 — fechado**. Para adicionar novos codes:
1. Criar card de modificação da ARCH_REFACTOR com escopo de extensão do catálogo
2. Documentar novo code neste arquivo (nova versão: `v2`)
3. Atualizar `skip_when` em `track.yaml`
4. Atualizar tabela de mapeamento campo→code

---

## Rastreabilidade

- **Card de origem**: 622
- **Track de execução**: ARCH_REFACTOR_ONBOARD
- **Direções arquiteturais**: D-L1, D-L2, D-L3, D-L4 (investigations/00_intake.md do card 622)
- **Cards dependentes**: `614A` (enforcement de skip_when no engine)
