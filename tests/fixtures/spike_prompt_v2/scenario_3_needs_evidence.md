# Cenário 3 — NEEDS_EVIDENCE: Contrato não recuperado, decisão bloqueada → spike, não feature

## Propósito

Demonstrar que quando o contrato não foi recuperado, a decisão produz NEEDS_EVIDENCE e gera uma spike investigativa, nunca uma feature direta.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** O campo `track_id` deveria ser obrigatório no `mandatory audit` para todas as tracks, ou apenas para tracks sem fase investigativa?
- **Decisão bloqueada:** Não podemos alterar o gate sem saber a intenção original do contrato.
- **Critérios de suficiência:** Quando soubermos a intenção do contrato do gate E se existe precedente de filtragem por track.

### Findings (resumo)
- F-01: Gate lê apenas `phase_id` — comportamento atual confirmado.
- F-02: Busca em `docs/` — `PHASE_CONTRACT_ENGINEERING.md`, `CONTRACT.md`, `WORKFLOW_YAML_CONTRACT.md` lidos. Nenhum menciona intenção sobre filtragem por `track_id`.
- F-03: Cards anteriores: busca em histórico — nenhum card de decisão técnica sobre este gate encontrado.
- **Contrato declarado:** NÃO encontrado para filtragem por track.
- **Intenção recuperada:** NÃO recuperada.
- **Limite da evidência:** A ausência de contrato não prova que a filtragem por track não seja uma invariante global não documentada.

### Gate de suficiência
- Pergunta 1 (intenção contratual recuperada?): NÃO
- Pergunta 2 (contratos aplicáveis consultados?): SIM — mas não encontraram resposta
- Resultado: **NEEDS_EVIDENCE** para ambas as alternativas (filtragem global / filtragem por track)

## Saída esperada

### technical_decision
- Alternativa "filtragem por track_id": NEEDS_EVIDENCE — intenção não recuperada
- Alternativa "manter gate global": NEEDS_EVIDENCE — sem contrato que confirme intenção global
- Status global: DECISION_DEFERRED — lacuna: intenção do contrato do gate não encontrada
- Conclusão legítima: "Ainda não há evidência suficiente para implementar" — não é falha da spike

### backlog_handoff
- NENHUM item de feature ou bug de implementação
- SP-01: Spike investigativa — "Recuperar intenção arquitetural do gate mandatory_audit: consultar histórico de commits, autores do gate, decisão técnica que o introduziu"
- Status da spike: REQUER_NOVA_SPIKE
