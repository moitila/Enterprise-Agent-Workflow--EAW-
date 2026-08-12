# Cenário 1 — GO: Evidência suficiente para implementar integralmente

## Propósito

Demonstrar que quando evidência é suficiente, a spike produz classificação GO e backlog de implementação autorizado.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** O gate `eaw_card_enforce_mandatory_analysis_audit` deveria filtrar por `track_id` além de `phase_id` para evitar falsos positivos em tracks sem investigação?
- **Decisão bloqueada:** Não podemos decidir se adicionar `track_id` ao gate sem saber se o contrato atual intenciona que o gate seja global ou por track.
- **Critérios de suficiência:** Quando soubermos (a) a intenção do contrato original do gate e (b) se há mecanismo existente de filtragem por track.

### Findings (resumo)
- F-01: Gate lê apenas `phase_id`, sem `phase.track_id` — evidência em `phase_completion.sh` L429.
- F-02: `track.yaml` declara estrutura de fases mas não contém campo `exempt_from_audit` — mecanismo de isenção inexistente no YAML.
- F-03: `docs/PHASE_CONTRACT_ENGINEERING.md` seção 4.2 declara: "mandatory audit deve verificar track context antes de aplicar" — intenção contratual recuperada.
- **Contrato declarado:** Sim, encontrado.
- **Intenção recuperada:** Sim.
- **Limite da evidência:** Não há commits de histórico que mostrem quando o gate foi adicionado.

### Gate de suficiência (technical_decision)
1. Intenção contratual recuperada? SIM (F-03, doc seção 4.2)
2. Contratos consultados? SIM (PHASE_CONTRACT_ENGINEERING.md)
3. Inputs/prerequisites/outputs diferenciados? SIM
4. Hipóteses concorrentes avaliadas? SIM (H1: bug no runtime; H2: contrato ausente — eliminada por F-03)
5. Hipóteses descartadas falsificadas? SIM (H2 descartada via F-03)
6. Solução reutiliza mecanismo existente? SIM (adicionar `track_id` no call site do gate existente)
7. Cria novo schema/estado/skill/track? NÃO
8. Evidência suficiente para ampliação? SIM
9. Compatibilidade avaliada? SIM (tracks que já têm fase investigativa não são afetadas)
10. Existe alternativa menor? SIM (a menor é adicionar parâmetro `track_id` ao gate existente)
11. Dentro do escopo original? SIM

### Classificação
- Alternativa: Adicionar `track_id` ao gate existente **→ GO**

## Saída esperada

### technical_decision
- Gate de suficiência: todas as 11 perguntas respondidas "sim"
- Classificação: GO
- Justificativa citando F-01, F-03

### backlog_handoff
- BL-01 com Status da decisão: GO
- Tipo correto: Bug
- Evidência autorizadora: F-01, F-03
- Menor mudança possível: adicionar parâmetro track_id ao call site
- NEEDS_EVIDENCE não gera feature
- NO_GO não gera item
