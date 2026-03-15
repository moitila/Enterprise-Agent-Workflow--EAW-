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
./scripts/eaw card 123 --track standard
./scripts/eaw card 124 --track bug "Fix race condition"
./scripts/eaw intake 123
./scripts/eaw next 123
./scripts/eaw analyze 123
./scripts/eaw smoke
./scripts/eaw test
```

`track` is the primary workflow classification for a card. The runtime stores the selected value in `card_state.track_id` and resolves the official workflow from `tracks/<track>/track.yaml`.

The declarative lifecycle advances through `current_phase` and `track.transitions`. `./scripts/eaw next <CARD>` is the command that moves a card to its next declared phase and executes the destination phase in a phase-driven way, but only after the current phase satisfies its declared `completion` contract. Phases may also declare prompt artifacts directly in `outputs.prompts`, which the runtime materializes under `out/<CARD>/prompts/` using the declared alias as the filename (`<alias>.md`) while preserving compatibility prompt artifacts. `intake`, `analyze`, and `implement` remain aggregated prompt-oriented commands that coexist for compatibility and AI-assisted execution flows.

Current phase semantics:
- entering a phase means the card state now points to that declarative workflow phase;
- `./scripts/eaw next <CARD>` blocks when the current phase is incomplete according to `phase.completion`, otherwise it performs the declarative state transition and executes the destination phase using the phase YAML outputs and the runtime prompt bindings;
- `intake`, `analyze`, and `implement` remain the compatibility commands that materialize the prompt-oriented work associated with those phases.

Future phase-driven note:
- the current phase-driven executor is incremental: it scaffolds declared outputs, materializes `outputs.prompts` under `out/<CARD>/prompts/`, emits compatibility prompt artifacts for the built-in prompt phases, and records execution in `execution.log`;
- future iterations can refine pre-conditions, completion criteria, and the distinction between manual and automatic phases without requiring new top-level commands.

## Test Scopes

- `./scripts/eaw smoke` executes the baseline smoke suite only (`tests/smoke/smoke_baseline.sh`).
- `./scripts/eaw test` executes a broader deterministic scope (`smoke + integration + lifecycle + golden`).
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
- `out/<CARD>/investigations/findings_agent_prompt.md` — findings prompt artifact generated by analyze
- `out/<CARD>/investigations/hypotheses_agent_prompt.md` — hypotheses prompt artifact generated by analyze
- `out/<CARD>/investigations/planning_agent_prompt.md` — planning prompt artifact generated by analyze
- `out/<CARD>/investigations/intake_agent_prompt.round_<N>.md` — deterministic intake prompt artifact
- `out/<CARD>/investigations/implementation_planning_agent_prompt.md` — canonical implementation planning prompt artifact generated by implement
- `out/<CARD>/investigations/implementation_executor_agent_prompt.md` — canonical implementation executor prompt artifact generated by implement
- `out/<CARD>/implementation/implementation_planning_agent_prompt.md` — compatibility mirror of implementation planning prompt
- `out/<CARD>/implementation/implementation_executor_agent_prompt.md` — compatibility mirror of implementation executor prompt
- `out/<CARD>/execution.log` — deterministic phase execution log (`phase|status|duration_ms|note`)
- `out/<CARD>/context/<repoKey>/git-status.txt` — git status
- `out/<CARD>/context/<repoKey>/git-diff.patch` — diff

Decision note:
- `outputs.prompts` is optional in the general contract.
- Phases that generate prompts should declare them explicitly in `outputs.prompts`.
- Internal/tooling phases that do not generate prompts should omit `outputs.prompts`.
- Compatibility prompt artifacts under `investigations/` and `implementation/` may coexist with `out/<CARD>/prompts/` while the legacy flow remains supported.
- `out/<CARD>/context/<repoKey>/changed-files.txt` — changed file list
- `out/<CARD>/context/<repoKey>/rg-symbols.txt` — symbol search hits

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
- `./scripts/eaw validate` — validates config and template contract.
- `./scripts/eaw doctor-hardening` — advanced hardening diagnostics for prompt binding and canonical smoke checks.

## PT-BR

EAW é um sistema determinístico de engenharia assistida por IA para governar trabalho por card. O runtime combina `track`, `phase`, estado por card em `card_state.track_id` e `current_phase`, governança de prompts por `ACTIVE`, coleta de contexto e artefatos auditáveis em `out/<CARD>/`.

Para usar: `./scripts/eaw init`, depois `./scripts/eaw card <CARD> --track <TRACK> ["<TITLE>"]`, avance o lifecycle com `./scripts/eaw next <CARD>` quando quiser progredir a fase declarada, e use `./scripts/eaw intake <CARD>`, `./scripts/eaw analyze <CARD>` e `./scripts/eaw implement <CARD>` como macrocomandos agregados de prompts e compatibilidade. O valor escolhido em `--track` torna-se `card_state.track_id`, o workflow oficial e resolvido por `tracks/<track>/track.yaml` e a proxima fase vem de `track.transitions`.

Semantica atual de fase:
- entrar em uma fase significa que o estado do card agora aponta para aquela fase declarativa do workflow;
- `./scripts/eaw next <CARD>` executa a transicao declarativa de estado e depois executa a fase de destino com base nos outputs declarados e nos bindings de prompt do runtime;
- `intake`, `analyze` e `implement` seguem como comandos agregados de compatibilidade que materializam o trabalho orientado a prompts dessas fases.

Nota sobre modelo phase-driven futuro:
- o executor phase-driven atual e incremental: cria artefatos declarados, emite prompts das fases conhecidas e registra a execucao em `execution.log`;
- iteracoes futuras podem refinar pre-condicoes, criterio de conclusao e a distincao entre fases manuais e automaticas sem exigir novo comando top-level.

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

EAW Mode D provides a deterministic path to integrate an external AI/assistant into the engineering workflow by generating complete, structured prompts and producing a test plan and action plan in a reproducible output folder.

This prompt pipeline is an aggregated compatibility flow for AI-assisted execution. It coexists with the declarative lifecycle, where the runtime keeps per-card state in `current_phase` and advances the official workflow through `./scripts/eaw next <CARD>` based on `track.transitions`.

Workflow (example):

1. Create a card: `./scripts/eaw card 12345 --track feature "Short title"`
2. Fill the dossier following the template sections.
3. Populate `out/12345/intake/` with evidence files (logs, screenshots, traces).

```bash
./scripts/eaw intake 12345
```

4. Generate the analysis prompt artifacts:

```bash
./scripts/eaw analyze 12345
```

This produces deterministic files under `out/12345/`:

- `feature_12345.md` — original dossier filename retained for deterministic compatibility; workflow classification still comes from `track` / `card_state.track_id`
- `investigations/findings_agent_prompt.md` — findings prompt to feed to an assistant
- `investigations/hypotheses_agent_prompt.md` — hypotheses prompt to feed to an assistant
- `investigations/planning_agent_prompt.md` — planning prompt to feed to an assistant
- `TEST_PLAN_12345.md` — deterministic test plan produced by the analysis
- `context/` — repository context captured earlier

5. Copy the generated prompts under `out/12345/investigations/`, run each phase with your chosen agent, and capture outputs back into `out/12345/dev/` as needed (manual step). The generated artifacts are deterministic and versionable.

Why Mode D: it standardizes how AI is given context and how outputs are captured for traceability, making AI-assisted changes auditable and safe for enterprise environments.
