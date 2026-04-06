# Onboarding Template: debug_first

OBJECTIVE
- Priorizar sinais operacionais e caminhos de diagnostico recorrentes do repositorio para reduzir tempo de investigacao.

INPUT
- Source onboarding material from `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/`.
- Materialized artifact target under `out/<CARD>/context/onboarding/`.

OUTPUT
- Produce a readable onboarding artifact focused on observability, common failure modes, and safe local debugging entry points.
- Preserve concrete commands, logs, and troubleshooting checkpoints when present in the onboarding source.

READ_SCOPE
- Prefer known failure modes, troubleshooting steps, diagnostics commands, logs, and environment caveats from the onboarding source.
- Ignore ad hoc fixes that are not part of stable repository guidance.

RULES
- Keep the output readable by an engineer.
- Separate stable repository facts from runtime-derived context.
- Preserve provenance to the onboarding source material.
- Do not reference `phase.yaml` by direct path binding.
