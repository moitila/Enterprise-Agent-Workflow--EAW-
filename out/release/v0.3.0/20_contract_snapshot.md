# Contract Snapshot — v0.3.0 (observable)

## Observable CLI commands
Fonte observável: `./scripts/eaw --help` e `scripts/eaw`.

- `init [--workdir <path>] [--force] [--upgrade]`
- `feature <CARD> "<TITLE>"`
- `spike <CARD> "<TITLE>"`
- `bug <CARD> "<TITLE>"`
- `prompt <CARD>`
- `analyze <CARD>`
- `ingest <CARD> <file-path>`
- `validate`
- `doctor`

## Observable output/artifact contract (`out/<CARD>/`)
Fontes observáveis: `README.md`, `docs/CONTRACT.md`, `docs/architecture.md`, `docs/deterministic-output.md`, `scripts/eaw`.

Artefatos principais (dependendo do comando executado):
- `out/<CARD>/<type>_<CARD>.md` (`feature_`, `bug_`, `spike_`)
- `out/<CARD>/execution.log`
- `out/<CARD>/investigations/00_intake.md`
- `out/<CARD>/investigations/10_baseline.md`
- `out/<CARD>/investigations/20_findings.md`
- `out/<CARD>/investigations/30_hypotheses.md`
- `out/<CARD>/investigations/40_next_steps.md`
- `out/<CARD>/context/<repoKey>/git-status.txt`
- `out/<CARD>/context/<repoKey>/git-diff.patch`
- `out/<CARD>/context/<repoKey>/changed-files.txt`
- `out/<CARD>/context/<repoKey>/rg-symbols.txt`
- `out/<CARD>/AI_PROMPT_<CARD>.md` (quando `analyze` roda)
- `out/<CARD>/inputs/` (quando `ingest` é usado)
- `out/<CARD>/agent_prompt.md` (persistido por `prompt`)

## `prompt` IO contract (stdout vs stderr)
Evidência de execução local: `./scripts/eaw prompt 100016`.

- `stdout`: imprime o conteúdo completo do agent prompt (ex.: cabeçalho `=== EAW AGENT PROMPT (...) CARD ... ===`, variáveis e instruções).
- `stderr`: imprime linha de persistência `Wrote <OUT_DIR>/<CARD>/agent_prompt.md`.
- `exit code`: `0` na execução observada.
