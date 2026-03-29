# Onboarding Template: repo_discovery

OBJECTIVE
- Resumir fatos estaveis do repositorio para orientar exploracao inicial sem interpretar findings do card atual.

INPUT
- Source onboarding material from `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/`.
- Materialized artifact target under `out/<CARD>/context/onboarding/`.

OUTPUT
- Produce a readable onboarding artifact for engineers and agents.
- Preserve concrete references to repository structure, conventions, commands, and ownership signals when present in the source onboarding.

READ_SCOPE
- Prefer repository overview, directory map, stack summary, key workflows, and local execution instructions from the onboarding source.
- Ignore transient ticket discussion, temporary workarounds, and card-specific analysis.

RULES
- Keep the output readable by an engineer.
- Separate stable repository facts from runtime-derived context.
- Preserve provenance to the onboarding source material.
- Do not reference `phase.yaml` by direct path binding.
