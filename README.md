# Enterprise Agent Workflow (EAW)

EAW is a lightweight, deterministic workflow for generating engineering dossiers for features, spikes, and bugs. It focuses on context engineering, deterministic outputs, and risk-aware decision making.

## What is EAW

EAW helps engineers collect repository context and produce structured Markdown artifacts for traceability and safer engineering in complex systems.

## Installation (bash)

Ensure you have `bash`, `git`, and optionally `rg` (ripgrep) installed.

```bash
# make scripts executable (on Unix)
chmod +x scripts/eaw scripts/lib.sh
```

## Quickstart

```bash
# from repo root
./scripts/eaw init
./scripts/eaw feature 12345 "Short title"
./scripts/eaw spike 23456 "Research question"
./scripts/eaw bug 99999 "Short bug title"
```

If you are on Windows and using PowerShell, run via `bash`:

```powershell
bash ./scripts/eaw init
bash ./scripts/eaw bug 999999 "Smoke test"
```

## Output structure

- `out/<CARD>/<TYPE>_<CARD>.md` — the generated dossier
- `out/<CARD>/investigations/00_intake.md` — intake for investigation flow
- `out/<CARD>/investigations/10_baseline.md` — baseline checklist and initial evidence
- `out/<CARD>/investigations/20_findings.md` — findings and collected artifacts
- `out/<CARD>/investigations/30_hypotheses.md` — hypotheses and validation plan
- `out/<CARD>/investigations/40_next_steps.md` — final diagnosis, risks, and action plan
- `out/<CARD>/context/<repoKey>/git-status.txt` — git status
- `out/<CARD>/context/<repoKey>/git-diff.patch` — diff
- `out/<CARD>/context/<repoKey>/changed-files.txt` — changed file list
- `out/<CARD>/context/<repoKey>/rg-symbols.txt` — symbol search hits

## Config

- `config/repos.conf` — map of repoKey to path with optional role (created by `eaw init` from `repos.example.conf`)
- `config/search.conf` — symbol search patterns (created by `eaw init`)
- `config/content.conf` (optional, experimental) — content-pack gate for `eaw prompt`

`config/content.conf` supports:
- `content_enabled=true|false` (default behavior is legacy/disabled when file is missing)
- `default_lang=<lang>` (used only when `content_enabled=true`; fallback order is `EAW_LANG -> default_lang -> pt-br`)

When `content_enabled=true`, `eaw prompt` validates `content/<lang>/pack.meta` with:
- `content_pack_version=1`
- `lang=<lang>`

If the pack is missing/invalid, the command fails with `exit != 0` and an `stderr` message prefixed with `EAW_CONTENT_ERROR:`.

Edit `config/repos.conf` to point to your local repositories.
- Legacy format: `key|path` (defaults to role `target`)
- New format: `key|path|role`, where `role` is `target` or `infra`
- Only `target` repositories are processed during context and search collection.

## No proprietary code

This repository contains no proprietary code or internal names. It is intentionally generic and suitable for public release.

## Roadmap

- v0.1: Basic scaffolding, deterministic output, context capture (this release)
- v0.2: Plugin architecture, richer collectors, JSON output contract, CI validation

## PT-BR

EAW é um fluxo de trabalho leve para gerar dossiês determinísticos (features, spikes, bugs). Use `./scripts/eaw init` e depois `./scripts/eaw feature|spike|bug`.

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

EAW Mode D provides a deterministic path to integrate an external AI/assistant into the engineering workflow by generating a complete, structured prompt, ingesting evidence, and producing a test plan and action plan in a reproducible output folder.

Workflow (example):

1. Create a card: `./scripts/eaw feature 12345 "Short title"`
2. Fill the dossier following the template sections.
3. Ingest evidence (logs, screenshots, traces):

```bash
./scripts/eaw ingest 12345 path/to/smoke-log.txt
```

4. Generate the AI prompt and analysis artifacts:

```bash
./scripts/eaw analyze 12345
```

This produces deterministic files under `out/12345/`:

- `feature_12345.md` — original dossier
- `AI_PROMPT_12345.md` — complete prompt to feed to an assistant
- `TEST_PLAN_12345.md` — deterministic test plan produced by the analysis
- `context/` — repository context captured earlier
- `inputs/` — ingested evidence files

5. Copy `AI_PROMPT_12345.md` to your chosen agent, run the analysis, and capture outputs back into `out/12345/dev/` as needed (manual step). The generated artifacts are deterministic and versionable.

Why Mode D: it standardizes how AI is given context and how outputs are captured for traceability, making AI-assisted changes auditable and safe for enterprise environments.
