# Enterprise Agent Workflow (EAW)

EAW is a deterministic AI-assisted engineering system for governing work by card. It combines workflow tracks, phase contracts, per-card state, prompt governance, context collection, and auditable artifacts so engineering teams can use AI with rigor in complex systems.

## What is EAW

EAW helps engineers turn a card into a governed execution flow. The runtime resolves the selected `track`, persists workflow state in `card_state.track_id` and `current_phase`, binds phase prompts through `ACTIVE`, collects repository context from target repos, and writes deterministic artifacts under `out/<CARD>/` for traceability and review.

## Architecture

Canonical architecture document: `docs/ARCHITECTURE.md`.

## Documentation Map

Read the repository in this order if you want the full model:

- `Manifesto`: `docs/manifesto.md` - philosophy, problem statement, and engineering posture
- `Conceptual Model`: `docs/CONCEPTUAL_MODEL.md` - product positioning and the mental model that connects the system layers
- `Architecture`: `docs/ARCHITECTURE.md` - runtime architecture, modules, and invariants
- `CLI`: `docs/CLI.md` - public command contract for lifecycle and validation commands
- `Runtime Contracts`: `docs/RUNTIME_CONTRACTS.md` - lifecycle, envelopes, finalization, and runtime/operator boundary
- `Validation`: `docs/VALIDATION.md` - validation command scopes and non-guarantees
- `Workflow YAML Contract`: `docs/WORKFLOW_YAML_CONTRACT.md` - declarative workflow model for `track`, `phase`, and `card_state`
- `Prompt Governance`: `docs/PROMPT_GOVERNANCE.md` - prompt binding, `ACTIVE`, and provenance
- `Contract`: `docs/CONTRACT.md` - public output, behavior, and compatibility contract

## Installation (bash)

Ensure you have `bash`, `git`, `mktemp`, and optionally `rg` (ripgrep) installed.

```bash
# make scripts executable (on Unix)
chmod +x scripts/eaw scripts/lib.sh
```

## Quickstart

```bash
# from repo root
./scripts/eaw init
./scripts/eaw card 589 --track feature "Document context model adoption"
./scripts/eaw next 589
./scripts/eaw validate workflow --track feature
./scripts/eaw smoke
```

Safe quickstart notes:

- do not overwrite official files under `tracks/` during quickstart;
- use an installed track and let the runtime materialize the current phase;
- use `./scripts/eaw next <CARD>` for normal lifecycle progression;
- use `./scripts/eaw complete <CARD>` when you need to mark the current phase complete explicitly after required artifacts already exist;
- use `docs/CLI.md`, `docs/RUNTIME_CONTRACTS.md`, and `docs/VALIDATION.md` as the public command and lifecycle contracts.

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

## Migration Path

- Prefer `./scripts/eaw next <CARD>` as the primary lifecycle command.
- `./scripts/eaw complete <CARD>` is a supported public command for explicit current-phase completion after required artifacts already exist.
- On the final phase, `next` can auto-close when validation gates pass; `complete` is the explicit operator completion path.
- See `docs/CLI.md` and `docs/RUNTIME_CONTRACTS.md` for the difference between `next`, `complete`, and `run`.

## Test Scopes

- `./scripts/eaw smoke` executes the configured smoke wrapper scope. See `docs/TEST_STRATEGY.md` for the current suite composition.
- `./scripts/eaw test` executes a broader deterministic scope. See `docs/VALIDATION.md` for validation command scope and `docs/TEST_STRATEGY.md` for test wrapper scope.
- `tests/phase_engine_lifecycle.sh` is a dedicated lifecycle/integration-light suite for the phase engine. It is executed from the lifecycle aggregate suite.
- Category wrappers are organized under:
  - `tests/smoke/`
  - `tests/integration/`
  - `tests/lifecycle/`
  - `tests/golden/`

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
Use `context` in `phase.yaml` to declare runtime-collected evidence. Onboarding has a sovereign workspace source at `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/` and is preferably consumed by reference through the context block. Runtime-derived dynamic context may be materialized under `out/<CARD>/context/dynamic/`.
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
- `./scripts/eaw validate` — validates workspace config, prompt availability, selected template contracts, card workflow summaries, and specific artifact gates. It is not a universal proof that a card is complete; see `docs/VALIDATION.md`.
- `./scripts/eaw doctor-hardening` — advanced hardening diagnostics for prompt binding and canonical smoke checks.

## PT-BR

EAW é um sistema determinístico de engenharia assistida por IA para governar trabalho por card. O runtime combina `track`, `phase`, estado por card em `card_state.track_id` e `current_phase`, governança de prompts por `ACTIVE`, coleta de contexto e artefatos auditáveis em `out/<CARD>/`.

Para usar: `./scripts/eaw init`, depois `./scripts/eaw card <CARD> --track <TRACK> ["<TITLE>"]`, avance o lifecycle com `./scripts/eaw next <CARD>` quando quiser progredir a fase declarada. O valor escolhido em `--track` torna-se `card_state.track_id`, o workflow oficial e resolvido por `tracks/<track>/track.yaml` e a proxima fase vem de `track.transitions`.

Semantica atual de fase:
- entrar em uma fase significa que o estado do card agora aponta para aquela fase declarativa do workflow;
- `./scripts/eaw next <CARD>` executa a transicao declarativa de estado e depois executa a fase de destino com base nos outputs declarados e nos bindings de prompt do runtime;

Nota sobre modelo phase-driven futuro:
- o executor phase-driven atual e incremental: cria artefatos declarados, emite prompts das fases conhecidas e registra a execucao em `execution.log`;
- iteracoes futuras podem refinar pre-condicoes, criterio de conclusao e a distincao entre fases manuais e automaticas sem exigir novo comando top-level.

### Caminho de Migracao

- Prefira `./scripts/eaw next <CARD>` como comando principal do lifecycle.
- `./scripts/eaw complete <CARD>` e comando publico suportado para marcar explicitamente a fase atual como completa quando os artefatos obrigatorios ja existem.
- Na fase final, `next` pode fazer auto-close quando as validacoes passam; `complete` e o caminho explicito do operador.

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

## AI Integration Mode (EAW Mode D)

EAW Mode D provides a deterministic path to integrate an external AI/assistant into the engineering workflow by generating structured prompts and auditable phase artifacts in a reproducible output folder.

This prompt pipeline coexists with the declarative lifecycle, where the runtime keeps per-card state in `current_phase` and advances the official workflow through `./scripts/eaw next <CARD>` based on `track.transitions`.

The EAW shell runtime does not own LLM execution. It prepares deterministic phase execution surfaces: prompts, context blocks, runtime environment, validation gates, and state transitions. Agent execution is performed by the operator or orchestrator using the generated phase prompt and declared contracts.

Workflow (example):

1. Create a card: `./scripts/eaw card 12345 --track feature "Short title"`
2. Fill the dossier following the template sections.
3. Advance the card with `./scripts/eaw next 12345` so the declared phase surface and prompt artifacts are materialized.

This produces deterministic files under `out/12345/`:

- `feature_12345.md` — original dossier filename retained for deterministic compatibility; workflow classification still comes from `track` / `card_state.track_id`
- `prompts/<prompt_alias>.md` — prompt artifacts to feed to an assistant
- `TEST_PLAN_12345.md` — deterministic test plan produced by the analysis

5. Run each phase with your chosen agent or Codex process using the generated prompt, then capture required phase outputs back under `out/12345/` according to the phase contract. The generated artifacts are deterministic and versionable.

Why Mode D: it standardizes how AI is given context and how outputs are captured for traceability, making AI-assisted changes auditable and safe for enterprise environments.
