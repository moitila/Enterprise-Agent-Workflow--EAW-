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
- `out/<CARD>/context/<repoKey>/git-status.txt` — git status
- `out/<CARD>/context/<repoKey>/git-diff.patch` — diff
- `out/<CARD>/context/<repoKey>/changed-files.txt` — changed file list
- `out/<CARD>/context/<repoKey>/rg-symbols.txt` — symbol search hits

## Config

- `config/repos.conf` — map of repoKey to path (created by `eaw init` from `repos.example.conf`)
- `config/search.conf` — symbol search patterns (created by `eaw init`)

Edit `config/repos.conf` to point to your local repositories. Format is `key|path` per line.

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
