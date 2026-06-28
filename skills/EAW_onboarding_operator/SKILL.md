---
name: eaw_onboarding_operator
description: Operate on EAW onboarding artifacts — read, assess drift, and patch published onboarding without re-running the full repo_onboarding track. Use when reading onboarding context for a repo, detecting drift between a repo and its published onboarding, updating specific onboarding files, or understanding the structure and semantics of the EAW onboarding workspace.
---

# EAW Onboarding Operator

Use this skill when the task involves reading or updating onboarding artifacts published in `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/`.

This skill is not a substitute for the `repo_onboarding` track. Use the track to generate a new onboarding from scratch. Use this skill to understand, assess, or surgically update an existing one.

## Onboarding Workspace Structure

Published onboarding lives under:

```
$EAW_WORKDIR/context_sources/onboarding/<repo_key>/
```

Where `repo_key` is the identifier from `repos.conf` (column 1: `<name>|<path>|<role>`).

### Canonical file layout

| File | Purpose | Required? |
|------|---------|-----------|
| `INDEX.md` | Reading order, repo identity, what this onboarding covers | Conventional |
| `provenance.md` | Origin card, track, phase, date, files published, stability notes | Conventional |
| `00_overview.md` | What the repo is, stack, objective, main areas | Core |
| `10_architecture.md` | Module structure, runtime flow, key components | Core |
| `20_entrypoints.md` | How the runtime resolves and materializes prompts | Domain |
| `30_data_flow.md` | Full card execution flow, state transitions | Domain |
| `40_integrations.md` | External deps: git, rg, awk, bash, CI | Domain |
| `50_persistence.md` | State files, artifacts, EAW_WORKDIR layout | Domain |
| `60_conventions.md` | Naming, structure, shell style | Domain |
| `61_code_style_and_lint.md` | Lint, formatting, language-specific rules | Domain |
| `65_implementation_patterns.md` | Canonical patterns for phase.yaml, prompt binding | Domain |
| `66_canonical_examples.md` | Real examples extracted from the codebase | Domain |
| `67_reuse_rules.md` | What must not be copied, what must be referenced | Domain |
| `70_debug_playbook.md` | Where to start, traps, critical functions | Domain |
| `80_execution_contract.md` | Allowed actions, forbidden areas, rollback, validation | Operational |
| `81_agent_quickstart.md` | Minimal reading list and pre-check for an agent starting a card | Operational |
| `repo_ai_context.md` | Native AI context sources (copilot-instructions, AGENTS.md, etc.) | Optional |

Not all repos will have all files. Read `INDEX.md` first to discover what exists.

### Provenance fields (in provenance.md)

| Field | Meaning |
|-------|---------|
| `Card de origem` | Card that generated this onboarding |
| `Track` | `repo_onboarding` |
| `Data de geração` | When `repo_onboarding_build` ran |
| `Repositório alvo` | repo_key |
| `Observações de estabilidade` | Areas in flux; when to regenerate |

Use `provenance.md` to assess whether the onboarding is stale relative to recent commits.

## How the Runtime Consumes Onboarding

Onboarding context is loaded into a card via `phase.context.onboarding_template`. The value is a logical identifier (e.g. `execution_guardrails`, `architecture_first`, `debug_first`) that maps to a template in `templates/context/onboarding/<template_name>/template_v1.md`.

The template instructs the runtime to:
1. Source files from `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/`
2. Materialize a curated artifact under `out/<CARD>/context/onboarding/`

The runtime resolves `repo_key` from `repos.conf` for the card's target repo. The agent does **not** read `context_sources/` directly during card execution — it reads the materialized artifact at `out/<CARD>/context/onboarding/`.

Exception: during `repo_onboarding_*` phases and during onboarding refresh/patch work, the agent reads `context_sources/onboarding/<repo_key>/` directly.

## Reading Onboarding (Minimal Order)

For any card on a repo that has published onboarding:

1. Resolve `repo_key` from `repos.conf`
2. Check that `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` exists
3. Read `INDEX.md` — verify reading order and what files exist
4. Read `81_agent_quickstart.md` — minimal pre-check for the current task
5. Read `80_execution_contract.md` — allowed/forbidden actions, rollback
6. Read domain files relevant to the current task (not all files)

Never read all files indiscriminately. Use `INDEX.md` to scope reading to the task.

## Assessing Drift

Drift occurs when the repo has changed significantly since the onboarding was generated but the published artifacts still reflect the old state.

### Drift signals

| Signal | How to detect |
|--------|--------------|
| `provenance.md` date is old | Compare date to recent `git log --since=<date>` |
| Files mentioned in onboarding no longer exist | `test -f <path>` for each path cited |
| Architecture description contradicts current code | Read `10_architecture.md` vs current source |
| `repo_ai_context.md` absent but `.github/` present | D1-C WARN path |
| `80_execution_contract.md` references deprecated patterns | Cross-check with current `65_implementation_patterns.md` |
| `provenance.md` notes "áreas em evolução" that are now resolved | Check if cited cards completed |

### Drift severity levels

| Level | Description | Action |
|-------|-------------|--------|
| `STALE_MINOR` | Dates old, paths still valid, patterns still accurate | Patch `provenance.md` only |
| `STALE_MODERATE` | Some files outdated, structure intact | Patch affected files; update provenance |
| `STALE_MAJOR` | Core architecture changed, patterns invalid | Re-run `repo_onboarding` track |
| `MISSING_ARTIFACT` | Expected file absent | Produce missing artifact and add to provenance |

Never declare `STALE_MAJOR` without evidence from the codebase. Read the relevant sections before classifying.

## Patching Onboarding (Surgical Update)

Use surgical patching when drift is `STALE_MINOR` or `STALE_MODERATE`. Never patch when drift is `STALE_MAJOR` — re-run the track instead.

### Patch rules

1. Read the current file before writing
2. Preserve all sections not affected by drift
3. Update only the section(s) with confirmed drift
4. Update `provenance.md`:
   - Add a new entry with date, card, what changed, and why
   - Do not remove previous provenance entries
5. Do not regenerate the entire file unless all sections are stale
6. Do not change `INDEX.md` section ordering unless a file is being added or removed
7. If adding a new file: add it to `INDEX.md` and `provenance.md`

### Write scope for patching

When patching, write scope is:
```
$EAW_WORKDIR/context_sources/onboarding/<repo_key>/<affected_file>
$EAW_WORKDIR/context_sources/onboarding/<repo_key>/provenance.md
```

Never write outside `context_sources/onboarding/<repo_key>/` during a patch operation.

### Provenance update format (patch entry)

```markdown
## Patch — <CARD_ID>

| Campo | Valor |
|-------|-------|
| **Card** | `<CARD_ID>` |
| **Data** | <YYYY-MM-DD> |
| **Fase** | `<phase_id>` |
| **Tipo** | `STALE_MINOR` / `STALE_MODERATE` / `MISSING_ARTIFACT` |

**Arquivos alterados:**

| Arquivo | Alteração |
|---------|-----------|
| `<file>` | <breve descrição da mudança> |

**Motivo:** <descrição objetiva do drift detectado>
```

## repo_ai_context.md Contract

When `repo_ai_context.md` is present, it contains:

| Section | Content |
|---------|---------|
| `## Fontes IA nativas encontradas` | Table: Fonte \| Path \| Provider \| Status |
| `## Status de confiança por fonte` | Table: Fonte \| Confiança \| Notas |
| `## Regras para agentes EAW` | Derived rules — not a literal copy of source files |
| `## Lacunas identificadas` | What was not found or assessed |
| `## Recomendação de uso no EAW` | How to apply in context bundles and execution |

When `repo_ai_context.md` is absent:
- Check if `.github/`, `AGENTS.md`, `CLAUDE.md`, or `.windsurfrules` exist in the repo
- If they do: the file is missing due to drift — classify as `MISSING_ARTIFACT`
- If they don't: absence is correct — no AI context sources to document

## Guardrails

- never write to the repo source files during onboarding operations
- never delete existing onboarding files without declaring it in provenance
- never regenerate all files when only a subset is stale
- never classify `STALE_MAJOR` without reading the relevant source code
- never invent paths in `INDEX.md` that do not correspond to real files
- never update `provenance.md` without citing the card and date
- never read `context_sources/` for a repo not declared in `repos.conf`
- never assume `repo_key` — always derive from `repos.conf` column 1
- never confuse `out/<CARD>/context/onboarding/` (curated copy for card execution, sourced from repo onboarding) with `context_sources/onboarding/<repo_key>/` (published, shared, per-repo — generated once and updated via refresh)

## Pre-check Before Any Operation

```bash
# 1. Confirm EAW_WORKDIR
test -d "$EAW_WORKDIR" || fail "EAW_WORKDIR not set or not a directory"

# 2. Resolve repo_key from repos.conf
# repos.conf format: <name>|<path>|<role>
repo_key=$(awk -F'|' '$3=="target" {print $1; exit}' "$EAW_WORKDIR/config/repos.conf")

# 3. Confirm onboarding exists
onboarding_dir="$EAW_WORKDIR/context_sources/onboarding/$repo_key"
test -d "$onboarding_dir" || fail "No published onboarding for $repo_key"

# 4. Read INDEX.md
test -f "$onboarding_dir/INDEX.md" || warn "INDEX.md absent — onboarding may be incomplete"

# 5. Read provenance.md
test -f "$onboarding_dir/provenance.md" || warn "provenance.md absent — cannot assess staleness"
```
