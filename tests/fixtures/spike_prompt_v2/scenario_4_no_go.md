# Cenário 4 — NO_GO: Alternativa rejeitada, sem backlog de implementação

## Propósito

Demonstrar que uma alternativa rejeitada recebe NO_GO e não gera nenhum item de backlog de implementação.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** A criação de um estado `CONTRACT_BLOCKED` no runtime EAW resolve a dor de gates bloqueados por ausência de contrato?
- **Decisão bloqueada:** Se `CONTRACT_BLOCKED` não for a abordagem correta, não implementar.

### Findings (resumo)
- F-01: Model de estados do runtime (`docs/EXECUTION_JOURNAL.md` seção 3): estados existentes: PENDING, RUNNING, COMPLETED, FAILED, PAUSED. Adicionar CONTRACT_BLOCKED exigiria: novo estado no schema, migração de cards existentes, lógica de retomada, compatibilidade com journal.
- F-02: Alternativa existente: `DECISION_DEFERRED` no `30_technical_decision.md` já captura decisão bloqueada sem alterar o runtime.
- F-03: `docs/WORKFLOW_YAML_CONTRACT.md` seção 2.1: "novos estados de runtime requerem aprovação via card de decisão arquitetural separado com evidência de que os estados existentes são insuficientes".
- **Limite da evidência:** F-02 mostra alternativa menor existente — eliminando justificativa para novo estado.

### Gate de suficiência para `CONTRACT_BLOCKED`
- Pergunta 6 (reutiliza mecanismo existente?): SIM — DECISION_DEFERRED já existe
- Pergunta 7 (cria novo estado?): SIM — `CONTRACT_BLOCKED` é novo estado de runtime
- Pergunta 8 (evidência para ampliação?): NÃO — F-02 mostra alternativa menor funcional
- Pergunta 10 (existe alternativa menor?): SIM — DECISION_DEFERRED + spike derivada
- Resultado: **NO_GO**

## Saída esperada

### technical_decision
- Alternativa `CONTRACT_BLOCKED`: **NO_GO** — rejeitada porque alternativa menor existe (DECISION_DEFERRED) e novo estado exige aprovação arquitetural separada
- Justificativa citando F-01, F-02, F-03
- Gate de suficiência: perguntas 8 e 10 resultam em rejeição

### backlog_handoff
- NENHUM item de implementação para `CONTRACT_BLOCKED`
- Seção "Itens descartados": `CONTRACT_BLOCKED` — NO_GO — motivo: alternativa menor existe, requisito arquitetural não cumprido
- Status da spike: COMPLETA (pergunta respondida: CONTRACT_BLOCKED não é a abordagem)
