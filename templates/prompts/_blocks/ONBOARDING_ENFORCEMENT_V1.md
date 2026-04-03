# BLOCK: ONBOARDING_ENFORCEMENT_V1

MANDATORY CONTEXT CONSUMPTION

Before consulting onboarding, resolve exactly one target repository for the current card.

Resolution rules:

- Use only the card artifacts already allowed for the phase plus `TARGET_REPOS`.
- Accept repository key, absolute path, repository folder name, or explicit textual reference from the card as resolution evidence.
- If zero candidates remain, STOP.
- If more than one candidate remains, STOP.
- After resolving the repository, derive `resolved_repo_key` from the single matching entry in `TARGET_REPOS`.

You MUST read and use the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/

Priority reading order:

1. INDEX.md
2. 81_agent_quickstart.md
3. 80_execution_contract.md

Then, depending on the task:

Architecture:
- 10_architecture.md
- 20_entrypoints.md
- 30_data_flow.md

Patterns:
- 65_implementation_patterns.md
- 66_canonical_examples.md
- 67_reuse_rules.md

Constraints:
- 60_conventions.md
- 61_code_style_and_lint.md

Debug:
- 70_debug_playbook.md

You MUST base all reasoning on these files.
Do NOT proceed with generic assumptions.

---

REPOSITORY PATTERN ALIGNMENT (MANDATORY)

Before proposing any change:

1. Identify existing pattern
2. Locate canonical example (66_canonical_examples.md)
3. Verify reuse possibility (67_reuse_rules.md)

Rules:

- Prefer reuse over creation
- Prefer extension over duplication
- Do NOT introduce new patterns if equivalent exists
- Follow repository structure, naming and layering

If deviating:

- Explain why existing patterns are insufficient

---

EXECUTION CONTRACT (MANDATORY)

Follow:

{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/80_execution_contract.md

Including:

Before:
- Validate entrypoints and flow
- Confirm affected layers

During:
- Follow repository patterns
- Respect local conventions
- Respect global constraints (Checkstyle / IntelliJ)

After:
- Ensure consistency
- Avoid structural inconsistencies

---

EVIDENCE-BASED REASONING

For every proposal:

- Cite at least one canonical file (full path)
- Reference onboarding section used
- Explain how pattern applies

No opinion-based reasoning allowed.

---

FAIL CONDITIONS

- If onboarding is not consulted -> STOP
- If `resolved_repo_key` is not uniquely resolved from the card and `TARGET_REPOS` -> STOP
- If no canonical reference is provided -> STOP
- If reasoning is not evidence-based -> STOP
