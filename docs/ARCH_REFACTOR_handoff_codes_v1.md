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
| `all_informational` | `true` | `NO_DOMINANT_HYPOTHESIS` |

**Regra de precedência** (para casos de múltiplos campos satisfeitos simultaneamente):

1. `NO_CODE_DEVIATION` — prioridade mais alta (ausência de desvio supera os demais)
2. `ADHERENCE_CONFIRMED` — prioridade intermediária
3. `INFORMATIONAL_ONLY` — prioridade mais baixa

**Nota**: O mapeamento é 1-para-1 em execução normal. Casos de múltiplos campos ativos simultaneamente são edge-cases; a precedência acima garante determinismo. Casos sem nenhum campo ativo não emitem code e a fase `hypotheses` não é skipável.

**Code adicional**: `NO_DOMINANT_HYPOTHESIS`

**Descrição**: Todas as hipóteses levantadas pela fase `hypotheses` são informacionais e não existe hipótese dominante acionável para orientar o planejamento.

**Condição de emissão**: O envelope final da fase indica `all_informational: true`.

**Semântica para skip_when**: O code é consumido por `planning` como sinal de ausência de hipótese dominante e evita o reuso de `INFORMATIONAL_ONLY`, que permanece associado semanticamente a `findings`.

**Nota de nomenclatura**: `HYPOTHESES_NOT_REQUIRED` aparece como redacao de origem/drift no backlog; neste catalogo, a forma canonica mantida e `NO_DOMINANT_HYPOTHESIS`.

---

## Estrutura do 20_handoff.json

O artefato `20_handoff.json` é produzido como output de orquestração no formato de envelope do runtime. Estrutura:

```json
{"from_phase":"<PHASE>","status":"completed","messages":[],"codes":["<CODE>"]}
```

Quando nenhum code se aplica (fluxo completo, sem skip):

```json
{"from_phase":"<PHASE>","status":"completed","messages":[],"codes":[]}
```

**Campo `from_phase`**: identificador da fase que emitiu o handoff (ex: `findings`, `hypotheses`).
**Campo `status`**: fixo como `"completed"` para emissão normal.
**Campo `messages`**: array de mensagens auxiliares (vazio na maioria dos casos).
**Campo `codes`**: array contendo zero ou um code do catálogo: `NO_CODE_DEVIATION`, `INFORMATIONAL_ONLY`, `ADHERENCE_CONFIRMED`, `NO_DOMINANT_HYPOTHESIS`.

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

Este catálogo é **v1.1 — estendido por card 624**. Para adicionar novos codes:
1. Criar card de modificação da ARCH_REFACTOR com escopo de extensão do catálogo
2. Documentar novo code neste arquivo (nova versão)
3. Atualizar `skip_when` em `track.yaml`
4. Atualizar tabela de mapeamento campo→code

---

## Extensão v1.1 — Card 624

### `SIMPLE_ALIGNMENT`

**Descrição**: O intake classificou o card como `ALINHAMENTO_A_PADRAO` com escopo trivial (até 2 arquivos, desvios informacionais, direção local clara). A investigação via findings é desnecessária porque o alinhamento é simples e determinístico.

**Emissor**: fase `intake` (diferente dos 3 codes v1, que são emitidos por `hypotheses`/`findings`)

**Transição**: `intake → findings` no track `ARCH_REFACTOR_ONBOARD`

**Condição de emissão**: Todos os critérios abaixo atendidos simultaneamente:
1. Classificação do contexto: `ALINHAMENTO_A_PADRAO`
2. Escopo de no máximo 2 arquivos no mesmo módulo
3. Desvios exclusivamente informacionais (sem mudança de comportamento)
4. Direção arquitetural local clara, única e inequívoca
5. Sem ambiguidades relevantes que exijam investigação

**Semântica para skip_when**: A fase `findings` não agrega valor quando o intake já determinou alinhamento simples com escopo trivial. O card pode avançar diretamente para `hypotheses` (que por sua vez pode ser skipado pelos codes v1 se findings anterior também emitiu skip).

**Nota**: Este code opera em cascata com os codes v1. Se `SIMPLE_ALIGNMENT` pular `findings`, o próximo `eaw next` avaliará `findings → hypotheses` e poderá pular também se os codes propagados corresponderem.

---

## Rastreabilidade da extensão v1.1

- **Card de origem**: 624
- **Track de execução**: ARCH_REFACTOR_ONBOARD
- **Hipótese base**: H1 (skip_when suficiente), H2 (2 skip_when para fluxo LITE)

---

## Rastreabilidade

- **Card de origem**: 622
- **Track de execução**: ARCH_REFACTOR_ONBOARD
- **Direções arquiteturais**: D-L1, D-L2, D-L3, D-L4 (investigations/00_intake.md do card 622)
- **Cards dependentes**: `614A` (enforcement de skip_when no engine)

---

## Extensão v1.2 — Card 626 (Feature Track)

### Reutilização no Feature Track

**Card de origem**: 626
**Track**: feature
**Transição**: `findings → hypotheses`

Os 3 codes originais do catálogo v1 (`NO_CODE_DEVIATION`, `INFORMATIONAL_ONLY`, `ADHERENCE_CONFIRMED`) são reutilizados no feature track para a transição `findings → hypotheses`.

**Diferenças em relação ao ARCH_REFACTOR:**

| Aspecto | ARCH_REFACTOR | Feature Track |
|---|---|---|
| Emissor | fase `hypotheses` ou `findings` | fase `findings` |
| Transição | `findings → hypotheses` | `findings → hypotheses` |
| Artefato | `investigations/20_handoff.json` | `investigations/20_handoff.json` |
| Prompt que emite | hypotheses prompt | findings prompt v5 |

**Semântica**: Quando a fase `findings` do feature track não identifica desvios relevantes (apenas observações informacionais, conformidade confirmada ou ausência de desvios de código), a fase `hypotheses` é pulada via `skip_when`. O planning (prompt v6) tolera a ausência de `30_hypotheses.md` quando há evidência de skip legítimo.

**Estrutura do 20_handoff.json**: Idêntica ao catálogo v1 (type, code, text), com inclusão de `NO_DOMINANT_HYPOTHESIS` quando aplicável.

**Precedência de codes**: Idêntica ao catálogo v1 (NO_CODE_DEVIATION > ADHERENCE_CONFIRMED > INFORMATIONAL_ONLY). `NO_DOMINANT_HYPOTHESIS` é emitido por um critério próprio da fase `hypotheses` e não compete com os codes de `findings`.

### Rastreabilidade da extensão v1.2

- **Card de origem**: 626
- **Track de execução**: feature
- **Hipóteses base**: H1 (reutilizar codes ARCH_REFACTOR), H2 (adaptar findings + skip_when), H3 (planning tolera skip)

---

## Extensão v1.3 — Card AR-03

### `TRIVIAL_SCOPE`

**Descrição**: O planning determinou que o escopo de implementação é trivial: superfície pequena e local, sem dependências cruzadas relevantes e sem necessidade de `implementation_planning` elaborado.

**Emissor**: fase `planning`

**Transição**: `planning → implementation_planning` na track `ARCH_REFACTOR_ONBOARD`

**Condição de emissão**: Todos os critérios abaixo atendidos simultaneamente:
1. Escopo afeta exatamente 1 arquivo ou uma superfície muito pequena (até 2 arquivos no mesmo módulo)
2. Todos os desvios identificados são informacionais, sem mudança de comportamento
3. Não há ambiguidade arquitetural relevante e o impacto é local

**Semântica para skip_when**: `implementation_planning` é pulado; o `implementation_executor` recebe o alinhamento produzido em `40_next_steps.md` e os artefatos mínimos já materializados pelo planning.

### Rastreabilidade da extensão v1.3

- **Card de origem**: AR-03
- **Track de execução**: ARCH_REFACTOR_ONBOARD
- **Hipóteses base**: H1 (implementação parcial entre superfícies), H2 (pedido residual de alinhamento)

---

## Extensão v1.4 — Card AR-05

### `NO_DOMINANT_HYPOTHESIS`

**Descrição**: A fase `hypotheses` não encontrou hipótese dominante acionável; o conjunto de hipóteses é apenas informacional e não deve ser reclassificado como `INFORMATIONAL_ONLY`.

**Emissor**: fase `hypotheses`

**Transição**: `hypotheses → planning` na track `ARCH_REFACTOR_ONBOARD`

**Condição de emissão**: O envelope final da fase indica `all_informational: true` no artefato `10_phase_output.json`.

**Semântica para skip_when**: `planning` consome o code como sinal de ausência de hipótese dominante e mantém o alinhamento arquitetural sem ampliar escopo nem criar novo contrato.

### Rastreabilidade da extensão v1.4

- **Card de origem**: AR-05
- **Track de execução**: ARCH_REFACTOR_ONBOARD
- **Hipóteses base**: H1 (envelope final da fase), H2 (code próprio de handoff), H3 (repasse até planning)
