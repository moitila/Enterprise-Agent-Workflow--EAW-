# Governance Templates

## Para que serve cada template

- `RFC_TEMPLATE.md`: decisões arquiteturais e mudanças grandes no produto.
- `FEATURE_PROPOSAL_TEMPLATE.md`: proposta de feature para o próprio EAW.
- `POSTMORTEM_TEMPLATE.md`: análise de falhas/incidentes e ações de prevenção.
- `RELEASE_PLANNING_v0.3.0_TEMPLATE.md`: planejamento estruturado de release (template, não plano real).

Template complementar:
- `docs/governance/templates/CHAT_BOOTSTRAP_TEMPLATE.md` (bootstrap de conversa e contexto para novas fases).

## Quando usar

- RFC: quando houver impacto de arquitetura, compatibilidade, migração ou contrato.
- Feature Proposal: antes de implementar nova feature.
- Postmortem: após incidente, regressão ou falha relevante.
- Release Planning: antes de iniciar ciclo de release.

## Como preencher

- Preencha seções obrigatórias com evidência objetiva.
- Sempre incluir:
  - Contexto entendido
  - Hipótese
  - Plano em micro-passos
  - Riscos
  - Próximo passo recomendado
- Prefira bullets curtos e auditáveis.

## Convenções de naming e status

- Use datas no formato `YYYY-MM-DD`.
- Use status explícito (`Draft`, `Proposed`, `Accepted`, etc.).
- Para artefatos instanciados, sugerido:
  - `RFC_<slug>.md`
  - `FEATURE_<slug>.md`
  - `POSTMORTEM_<incident-id>.md`
  - `RELEASE_PLAN_<version>.md`
