# Onboarding Template: architecture_first

OBJECTIVE
- Destacar arquitetura, limites entre modulos e contratos estruturais do repositorio antes de detalhar implementacoes locais.

INPUT
- Source onboarding material from `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/`.
- Materialized artifact target under `out/<CARD>/context/onboarding/`.

OUTPUT
- Produce a readable onboarding artifact centered on system boundaries, modules, and integration points.
- Surface canonical documentation and architectural conventions when available in the onboarding source.

READ_SCOPE
- Prefer architecture docs, module boundaries, dependency rules, data flow summaries, and repository conventions.
- Ignore speculative redesign notes and transient debugging logs.

RULES
- Keep the output readable by an engineer.
- Separate stable repository facts from runtime-derived context.
- Preserve provenance to the onboarding source material.
- Do not reference `phase.yaml` by direct path binding.
