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

Onboarding is **not copied per card**. It lives in `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` and agents read it directly from there.

The agent resolves `repo_key` from `repos.conf` and reads the onboarding files directly from `context_sources/`. No per-card copy is created.

## Reading Onboarding (Minimal Order)

For any card on a repo that has published onboarding:

1. Resolve `repo_key` — see **Pre-check Before Any Operation** below
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
- never assume `repo_key` — always derive from intake or card artifacts; `repos.conf` is for confirmation
- never pick `repo_key` by taking the first `target` in `repos.conf` — a workspace can have many targets; only the operator knows which one this card is about
- if `repo_key` cannot be determined from available context, **ask the operator before proceeding**
- never look for onboarding inside `out/<CARD>/` — it is not copied per card; always read from `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/`

## Pre-check Before Any Operation

```bash
# 1. Confirm EAW_WORKDIR
test -d "$EAW_WORKDIR" || fail "EAW_WORKDIR not set or not a directory"

# 2. Resolve repo_key — in priority order:
#
#   a) Card artifacts from a previous phase (e.g. drift_report.md header "**Repo analisado:**")
#   b) Files in $CARD_DIR/intake/ — text written by the operator declaring which repo this card is about
#      Extract the last path segment: /home/user/dev/emr-tasy-plsql -> emr-tasy-plsql
#   c) If intake/ is empty and no prior artifacts exist: list TARGET_REPOSITORIES from RUNTIME_ENVIRONMENT
#      and ASK the operator which repo this card should operate on — do not pick one silently
#
# repos.conf is used only to CONFIRM that the resolved repo_key exists as a target:
repo_key=<resolved via steps above>
grep -qP "^${repo_key}\|" "$EAW_WORKDIR/config/repos.conf" || fail "$repo_key not found in repos.conf"

# 3. Confirm onboarding exists
onboarding_dir="$EAW_WORKDIR/context_sources/onboarding/$repo_key"
test -d "$onboarding_dir" || fail "No published onboarding for $repo_key"

# 4. Read INDEX.md
test -f "$onboarding_dir/INDEX.md" || warn "INDEX.md absent — onboarding may be incomplete"

# 5. Read provenance.md
test -f "$onboarding_dir/provenance.md" || warn "provenance.md absent — cannot assess staleness"
```

> **If you cannot determine `repo_key` from intake or card artifacts, stop and ask the operator.**
> Do not guess. Do not pick the first target from `repos.conf`. A workspace has many repos — only
> the operator knows which one this card is about.

## Resolução de repo_key quando TARGET_REPOSITORIES é inconsistente

O runtime pode injetar `TARGET_REPOSITORIES` com nome e path de repos diferentes quando `repos.conf` tem múltiplos `target`. Exemplo de rendering incorreto: `eaw => /home/user/dev/emr-tasy-plsql` (nome de um repo, path de outro).

Nesse caso, o Pre-check acima já é suficiente — ele não usa `TARGET_REPOSITORIES` diretamente para derivar `repo_key`. Porém, se a etapa (a) ou (b) não resolverem e você precisar usar `TARGET_REPOSITORIES` como fallback, aplique o seguinte algoritmo:

```
1. Para cada entry em TARGET_REPOSITORIES (formato "nome => path"):
   a. Tentar: context_sources/onboarding/<nome>/ existe no disco?
      Se sim → repo_key = <nome>
   b. Se não: extrair último segmento do path → tentar como repo_key
      ex: /home/user/dev/emr-tasy-plsql → emr-tasy-plsql
      Se context_sources/onboarding/emr-tasy-plsql/ existe → repo_key = emr-tasy-plsql
2. Se nenhuma entrada resolver → parar e reportar ao operador; nunca inferir
3. Se mais de uma entrada resolver → parar e reportar ao operador; nunca inferir
```

**Regra absoluta:** nunca derivar `repo_key` de `TARGET_REPOSITORIES` sem confirmar que o diretório de onboarding correspondente existe em disco. O nome renderizado pelo runtime pode estar errado.
