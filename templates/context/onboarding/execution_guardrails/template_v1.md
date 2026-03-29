# Onboarding Template: execution_guardrails

OBJECTIVE
- Consolidar restricoes operacionais, regras de seguranca e limites de alteracao que devem orientar a execucao no repositorio.

INPUT
- Source onboarding material from `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/`.
- Materialized artifact target under `out/<CARD>/context/onboarding/`.

OUTPUT
- Produce a readable onboarding artifact centered on allowed actions, forbidden areas, validation expectations, and rollback considerations.
- Preserve explicit repository guardrails and escalation conditions when present in the onboarding source.

READ_SCOPE
- Prefer repository guardrails, ownership boundaries, required checks, deployment cautions, and rollback notes.
- Ignore temporary exceptions that are not stable policy.

RULES
- Keep the output readable by an engineer.
- Separate stable repository facts from runtime-derived context.
- Preserve provenance to the onboarding source material.
- Do not reference `phase.yaml` by direct path binding.
