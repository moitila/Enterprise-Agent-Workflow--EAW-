# Enterprise Agent Workflow (EAW)

EAW is an agentic workflow framework for governing work by card, track, phase, prompt and artifact. It provides deterministic execution through workflow tracks, phase contracts, per-card state, prompt governance, context collection and auditable artifacts — so teams can operate AI with rigor in any knowledge-work process.

The built-in tracks are software-engineering-oriented, but the model is not limited to software. Any process that can be described through phases, prompts and YAML contracts can be governed with EAW.

## What is EAW

EAW helps operators turn a request into a governed execution flow. The runtime resolves the selected `track`, persists workflow state in `card_state.track_id` and `current_phase`, binds phase prompts through `ACTIVE`, collects repository context from target repos, and writes deterministic artifacts under `out/<CARD>/` for traceability and review.

## Operational Roles

EAW separates three distinct roles:

| Role | Responsibility |
|------|----------------|
| **Human requester** | Defines objective, context, constraints and intent. Chooses the track, feeds the card ingest area, and reviews artifacts. |
| **EAW operator / orchestrator** | Runs the CLI (`doctor`, `tracks`, `card`, `next`, `status`). Controls phase progression and delivers the rendered phase prompt to the isolated agent. Today this is typically a human assisted by Copilot or another AI assistant. |
| **Isolated phase agent** | Receives the rendered phase prompt. Produces the artifacts required by the phase contract. Does **not** run the CLI. Does **not** decide phase transitions. |

> EAW is not limited to software engineering. Tracks can be created for any process that can be described through phases, prompts and YAML contracts.

## Agentic Execution Model

After each `./scripts/eaw next <CARD>`, the runtime materializes the phase prompt at:

```
out/<CARD>/prompts/<phase_alias>.md
```

This prompt is the handoff artifact to the isolated agent responsible for that phase. The agent reads the prompt, executes the phase work, writes the required artifacts back into the card directory, and returns control to the EAW operator.

The operator then calls `./scripts/eaw next <CARD>` again. The runtime validates the phase artifacts, advances `current_phase`, and materializes the next prompt — repeating until the track reaches completion.

Artifacts produced by isolated agents are written under `out/<CARD>/` in directories declared by the phase contract (`investigations/`, `implementation/`, `context/`, etc.). The operator never modifies these artifacts manually — they are the authoritative output of the phase.

## Architecture

Canonical architecture document: `docs/ARCHITECTURE.md`.

## Installation (bash)

Ensure you have `bash`, `git`, `mktemp`, and optionally `rg` (ripgrep) installed.

```bash
# make scripts executable (on Unix)
chmod +x scripts/eaw scripts/lib.sh
```

## Quickstart

EAW is operated through an agentic workflow. The human defines the goal; the EAW operator/orchestrator runs the CLI; the isolated phase agent executes each phase using the generated prompt.

> **Do not edit `tracks/`, `templates/`, `scripts/` or runtime contracts during normal card execution.** Track and prompt changes are framework maintenance tasks, not part of regular card use.

```bash
# 1. Initialize or validate the workspace
./scripts/eaw doctor

# 2. See available tracks
./scripts/eaw tracks

# 3. Create a card with the appropriate track
./scripts/eaw card <CARD> --track <TRACK> "<TITLE>"

# 4. Advance the card — generates the phase prompt
./scripts/eaw next <CARD>

# 5. Deliver the generated prompt to an isolated agent
# Prompt is at: out/<CARD>/prompts/<phase_alias>.md

# 6. Repeat next + agent until the card completes
./scripts/eaw status <CARD>
```

These commands are run by the **EAW operator/orchestrator**, not by the isolated phase agent.

## Documentation Map

Read the repository in this order if you want the full model:

- `Manifesto`: `docs/manifesto.md` - philosophy, problem statement, and engineering posture
- `Conceptual Model`: `docs/CONCEPTUAL_MODEL.md` - product positioning and the mental model that connects the system layers
- `Architecture`: `docs/ARCHITECTURE.md` - runtime architecture, modules, and invariants
- `Workflow YAML Contract`: `docs/WORKFLOW_YAML_CONTRACT.md` - declarative workflow model for `track`, `phase`, and `card_state`
- `Prompt Governance`: `docs/PROMPT_GOVERNANCE.md` - prompt binding, `ACTIVE`, and provenance
- `Contract`: `docs/CONTRACT.md` - public output, behavior, and compatibility contract

## Available Tracks

Run `./scripts/eaw tracks` to list all installed tracks. Current tracks:

| Track | Use when | Not when |
|-------|----------|----------|
| `spike` | You need to investigate before deciding | You already know exactly what to change |
| `feature` | The functional demand is clear and scoped | The question is still exploratory |
| `feature_dynamic` | Feature with dynamic context collection enabled | Static context is sufficient |
| `bug` | There is a defect with symptoms, logs or evidence | It is a new feature in disguise |
| `bug_ONBOARD` | Bug investigation requires onboarding a new repo first | Repo is already onboarded |
| `repo_onboarding` | EAW needs to learn a new repository | An onboarding already exists for that repo |
| `repo_onboarding_refresh` | An existing onboarding may be outdated | You want to regenerate everything from scratch |
| `ARCH_REFACTOR` | Architectural refactoring with governed phases | Small or non-architectural change |
| `ARCH_REFACTOR_ONBOARD` | Arch refactor that requires onboarding the target repo first | Repo is already onboarded |
| `standard` | Generic flow with no specialized track | A more specific track fits better |

## Feeding a Card

Every card starts with raw material in the ingest directory:

```
$EAW_WORKDIR/out/<CARD>/ingest/
```

Place there the original request, prints, logs, links, constraints and business context. Example:

```bash
mkdir -p "$EAW_WORKDIR/out/1001/ingest"

cat > "$EAW_WORKDIR/out/1001/ingest/raw_card_explication.md" <<'EOF'
Original request:
...

Context:
...

Constraints:
...
EOF
```
The file name is flexible, but `raw_card_explication.md` is the recommended convention used by EAW operator skills.

The ingest material is consumed by the first phase of the track. Do not put code or runtime artifacts there — only the human-provided context.

## Runtime Reference

> The following sections describe EAW's runtime internals, lifecycle contracts and YAML model. If you are **using** EAW (not maintaining or extending it), jump to [Bootstrap / Getting Started](#bootstrap--getting-started).

`track` is the primary workflow classification for a card. The runtime stores the selected value in `card_state.track_id` and resolves the official workflow from `tracks/<track>/track.yaml`.

The declarative lifecycle advances through `current_phase` and `track.transitions`. `./scripts/eaw card <CARD> --track <TRACK>` materializes the initial phase declared by the selected track as soon as the card is created. `./scripts/eaw next <CARD>` first materializes the current phase, then evaluates the declared `completion` contract for that same phase, remains in place when required artifacts are still missing or still contain only scaffold/template content, and only then applies `track.transitions` and materializes the destination phase. Phases may also declare prompt artifacts directly in `outputs.prompts`, which the runtime materializes under `out/<CARD>/prompts/` using the declared alias as the filename (`<alias>.md`) while preserving compatibility prompt artifacts. The public CLI centers on `next`, `run`, `complete`, `validate`, `doctor`, and prompt-governance commands.

`./scripts/eaw run <CARD>` is the deterministic orchestration entrypoint for executing a card end-to-end through the declared workflow. It uses `./scripts/eaw next <CARD>` as the only progression mechanism, persists `out/<CARD>/runtime/run_state.yaml` and `out/<CARD>/runtime/execution.log`, and names terminal outcomes with `stop_reason`. Wave 1 is intentionally minimal: no `--resume`, `--from`, `--dry-run`, automatic retry, extra metrics, or new runtime architecture are part of the documented contract.

Current phase semantics:
- entering a phase means the card state now points to that declarative workflow phase;
- `./scripts/eaw card <CARD> --track <TRACK>` materializes the initial declarative phase immediately after card creation;
- `./scripts/eaw next <CARD>` materializes the current phase, validates that phase against `phase.completion`, stays on the same `current_phase` when required artifacts are missing or unfilled, and otherwise performs the declarative state transition before materializing the destination phase;
- `next` is the primary lifecycle interface for declared phase progression.

Future phase-driven note:
- the current phase-driven executor is incremental: it scaffolds declared outputs, materializes `outputs.prompts` under `out/<CARD>/prompts/`, emits compatibility prompt artifacts for the built-in prompt phases, and records execution in `execution.log`;
- future iterations can refine pre-conditions, completion criteria, and the distinction between manual and automatic phases without requiring new top-level commands.

## Bootstrap / Getting Started

Para inicializar um novo workspace EAW, passe a skill `bootstrap_operator` ao seu agente.
O agente executa todos os passos — não é necessário configurar nada manualmente nem criar um card.

```
Skill: skills/bootstrap_operator/SKILL.md
```

| Passo | O que o agente faz |
|-------|--------------------|
| `init_workspace` | `eaw init --workdir <path>` |
| `configure_env` | `export EAW_WORKDIR=<path>` + persistência em shell config |
| `configure_repos` | edita `repos.conf` com os repos declarados |
| `validate_repos` | `git -C <path> rev-parse` para cada repo |
| `validate_env` | `eaw validate` + `eaw doctor` |


If you are on Windows and using PowerShell, run via `bash`:

```powershell
bash ./scripts/eaw init
bash ./scripts/eaw card 999999 --track bug "Smoke test"
```

## Output structure

- `out/<CARD>/<TYPE>_<CARD>.md` — the generated dossier; this filename is a deterministic compatibility convention, while workflow classification remains `track` / `card_state.track_id`
- `out/<CARD>/investigations/00_intake.md` — intake for investigation flow
- `out/<CARD>/investigations/10_baseline.md` — baseline checklist and initial evidence
- `out/<CARD>/investigations/20_findings.md` — findings and collected artifacts
- `out/<CARD>/investigations/30_hypotheses.md` — hypotheses and validation plan
- `out/<CARD>/investigations/40_next_steps.md` — final diagnosis, risks, and action plan
- `out/<CARD>/prompts/<prompt_alias>.md` — phase-driven prompt artifact generated from `outputs.prompts`; the file name matches the declared alias exactly
- `out/<CARD>/execution.log` — deterministic phase execution log (`phase|status|duration_ms|note`)
- `out/<CARD>/runtime/run_state.yaml` — `eaw run` state snapshot with `attempt`, `status`, `track_id`, `current_phase`, `phase_status`, `stop_reason`, and timestamp
- `out/<CARD>/runtime/execution.log` — `eaw run` operational log with per-attempt entries such as `attempt=N|status=<...>|card=<...>|...`
- `out/<CARD>/execution_journal.jsonl` — structured Execution Journal in JSON Lines; one event per phase with fields `card_id`, `track`, `phase`, `timestamp`, `agent`, `mode`, `status`, `duration_ms` (see `docs/EXECUTION_JOURNAL.md`)

Decision note:
- `outputs.prompts` is optional in the general contract.
- Phases that generate prompts should declare them explicitly in `outputs.prompts`.
- Internal/tooling phases that do not generate prompts should omit `outputs.prompts`.
- Prompt artifacts are materialized only under `out/<CARD>/prompts/`; `investigations/` and `implementation/` keep only phase work artifacts.

## Context Pack

The context model is active and documented for incremental adoption.
Use `context` in `phase.yaml` to declare runtime-collected evidence, keep onboarding optional, and verify the materialized artifacts under `out/<CARD>/context/onboarding/` and `out/<CARD>/context/dynamic/`.
The canonical contract is `docs/CONTEXT_MODEL.md`; the migration path with examples copiaveis diretamente, checklist de migracao, track por track, fase por fase, sem bootstrap and bootstrap opcional lives in `docs/CONCEPTUAL_MODEL.md`.

## Config

- `config/repos.conf` — map of repoKey to path with optional role (created by `eaw init` from `repos.example.conf`)
- `config/search.conf` — symbol search patterns (created by `eaw init`)

Edit `config/repos.conf` to point to your local repositories.
- Legacy format: `key|path` (defaults to role `target`)
- New format: `key|path|role`, where `role` is `target` or `infra`
- Only `target` repositories are processed during context and search collection.

## No proprietary code

This repository contains no proprietary code or internal names. It is intentionally generic and suitable for public release.

## Roadmap

- Next: expand CI-oriented validation orchestration for deterministic checks.
- Next: evolve contract documentation coverage for new execution phases without CLI breakage.
- Next: incrementally expand automated smoke coverage while preserving deterministic output.

Released versions and historical changes are tracked in `CHANGELOG.md`.

## Diagnostics

- `./scripts/eaw doctor` — reports resolved directories, tools, and config status.
- `./scripts/eaw preflight <CARD>` — validates EAW_WORKDIR, repos.conf (.git checks), runtime root and phase prompts before execution.
- `./scripts/eaw validate` — validates config and template contract.
- `./scripts/eaw doctor-hardening` — advanced hardening diagnostics for prompt binding and canonical smoke checks.

## PT-BR

EAW é um framework agentic de workflow para governar trabalho por card, track, fase, prompt e artefato. O runtime combina `track`, `phase`, estado por card em `card_state.track_id` e `current_phase`, governança de prompts por `ACTIVE`, coleta de contexto e artefatos auditáveis em `out/<CARD>/`.

Para usar: `./scripts/eaw init`, depois `./scripts/eaw card <CARD> --track <TRACK> ["<TITLE>"]`, avance o lifecycle com `./scripts/eaw next <CARD>` quando quiser progredir a fase declarada. O valor escolhido em `--track` torna-se `card_state.track_id`, o workflow oficial e resolvido por `tracks/<track>/track.yaml` e a proxima fase vem de `track.transitions`.

Semantica atual de fase:
- entrar em uma fase significa que o estado do card agora aponta para aquela fase declarativa do workflow;
- `./scripts/eaw next <CARD>` materializa a fase atual, valida o contrato de conclusao (phase.completion) e so avanca para a proxima fase quando os artefatos obrigatorios estao completos;

Nota sobre modelo phase-driven futuro:
- o executor phase-driven atual e incremental: cria artefatos declarados, emite prompts das fases conhecidas e registra a execucao em `execution.log`;
- iteracoes futuras podem refinar pre-condicoes, criterio de conclusao e a distincao entre fases manuais e automaticas sem exigir novo comando top-level.

### Caminho de Migracao

- Prefira `./scripts/eaw next <CARD>` como comando principal do lifecycle.
- Na CLI publica atual, a conclusao da fase e aplicada por `phase.completion` quando `next` executa. O repositorio nao documenta hoje um comando publico `./scripts/eaw complete <CARD>`, entao a documentacao deve descrever o contrato de conclusao em vez de um passo extra de CLI.

## Commit Governance (ECS)

This repository uses the EAW Commit Standard (ECS) to ensure commits are traceable and auditable. ECS is compatible with Conventional Commits and requires a small metadata block in the commit body.

To install the repository hook locally (Ubuntu / Linux / WSL):

```bash
chmod +x scripts/install-hooks.sh
bash scripts/install-hooks.sh
```

After installing, commits will be validated. Example of a valid commit message:

```
feat(feature): introduce EAW Commit Standard (ECS)

[Risk-Level]: low
[Impact-Scope]: module
[Phase]: implementation
[EAW-ID]: 000000

Decision:
- Add commit governance model
```

Why ECS matters: it makes risk explicit at commit time, enables deterministic automation and improves auditability for enterprise workflows.

## Governance Layer

The repository includes a dedicated Governance Layer (`/governance`) that codifies the EAW Commit Standard (ECS) and provides git hooks and installation scripts to enforce it locally.

- `governance/commit-standard.md` — formal specification of ECS
- `governance/hooks/commit-msg` — commit-msg hook that validates ECS metadata
- `governance/scripts/install-hooks.sh` — installer for the governance hooks

Install the governance hooks (Ubuntu / Linux / WSL):

```bash
chmod +x governance/scripts/install-hooks.sh
bash governance/scripts/install-hooks.sh
```

If a hook already exists, run the installer with `--force` to overwrite.

Why this matters: making risk and scope explicit at commit time enables deterministic CI gating, review triage, and stronger audit trails required by enterprise governance.
