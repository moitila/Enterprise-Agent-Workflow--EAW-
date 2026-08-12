# Cenário 6 — Backlog condicionado: NEEDS_EVIDENCE gera spike, nunca feature

## Propósito

Demonstrar que uma decisão NEEDS_EVIDENCE não pode gerar item de feature ou bug — apenas item de spike investigativa.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** A criação de `eaw_contract_auditor` como skill separada resolve a dor de auditoria de contratos, ou a skill existente `eaw_prompt_creator` pode ser estendida?
- **Decisão bloqueada:** Não podemos criar nem estender sem saber se skill existente é extensível e se catálogo centralizado é necessário.

### Findings (resumo)
- F-01: `eaw_prompt_creator` skill v1 não possui seção de auditoria contratual — gap confirmado.
- F-02: `skills/registry.yaml` não possui skill com função de auditoria contratual.
- F-03: Extensão de `eaw_prompt_creator`: tecnicamente possível (é um arquivo markdown), mas não há precedente de skills com mais de uma responsabilidade primária — risco de coesão.
- F-04: Criação de `eaw_contract_auditor`: mecanismo de skills suporta (basta criar arquivo + registrar), mas impacto em fases que declaram skills não foi verificado — como skills são declaradas nas fases? Quais fases precisariam declarar a nova skill?
- **Intenção não recuperada:** Como o sistema de skills foi projetado para evolução (adição de novas skills vs. extensão de existentes).
- **Limite da evidência:** F-03 e F-04 não são suficientes para decidir — intenção de design do sistema de skills não recuperada.

### Gate de suficiência
- Para extensão de skill: pergunta 1 (intenção contratual?): NÃO (como skills evoluem — não documentado)
- Para nova skill: pergunta 2 (contratos consultados?): SIM, mas não responde a pergunta
- Resultado: ambas as alternativas → **NEEDS_EVIDENCE**

## Saída esperada

### technical_decision
- Extensão de eaw_prompt_creator: NEEDS_EVIDENCE
- Criação de eaw_contract_auditor: NEEDS_EVIDENCE
- Status: DECISION_DEFERRED

### backlog_handoff (demonstra regra crítica)
- NENHUM item de feature "criar eaw_contract_auditor"
- NENHUM item de bug/hardening "estender eaw_prompt_creator"
- SP-01: Spike investigativa — "Recuperar intenção de design do sistema de skills EAW: como skills devem evoluir (extensão vs. criação), quais fases declaram skills, impacto de nova skill"
- Seção "Regras de backlog aplicadas": NEEDS_EVIDENCE gera spike, não feature — explicitamente declarado
- Status da spike: REQUER_NOVA_SPIKE
