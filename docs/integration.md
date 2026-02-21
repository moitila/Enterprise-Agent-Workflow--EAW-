# EAW integration (workspace mode)

## When to use `EAW_WORKDIR`

Use `EAW_WORKDIR` when you want local workspace-specific configuration and outputs without changing the EAW core tree.

- Core default (backward compatible): no `EAW_WORKDIR`; EAW uses `<repo>/config`, `<repo>/templates`, `<repo>/out`.
- Workspace mode: set `EAW_WORKDIR`; EAW uses `<workdir>/config` and `<workdir>/out`.
- In workspace mode, configuration is mandatory and complete: core `config/` is not used as fallback.
- Templates in workspace mode: EAW uses `<workdir>/templates` when this directory exists; otherwise it falls back to core `<repo>/templates`.

## Recommended `.eaw/` structure

```text
.eaw/
  config/
    repos.conf
    search.conf
  templates/
    feature.md
    bug.md
    spike.md
    intake_bug.md
    intake_feature.md
    intake_spike.md
    10_baseline.md
    20_findings.md
    30_hypotheses.md
    40_next_steps.md
  out/
```

Create this structure with:

```bash
./scripts/eaw init --workdir ./.eaw
```

## Shell export example

```bash
export EAW_WORKDIR="$PWD/.eaw"
./scripts/eaw feature 1234 "Add integration docs"
```

## Config version

`config/eaw.conf` is optional and uses `key=value` format.

Example:

```text
config_version=1
```

Rules:
- If `eaw.conf` is missing, EAW keeps working and `validate` warns that v1 defaults are assumed.
- If `eaw.conf` exists without `config_version`, `validate` prints an upgrade instruction.
- If `config_version` is older than required, `validate` warns and suggests `init --upgrade`.

## Path resolution rules

- Absolute path (`/path/to/repo`): used as-is.
- Home-relative path (`~/repo`): expanded to `$HOME/repo`.
- Relative path in `repos.conf`:
  - with `EAW_WORKDIR` set: resolved relative to workspace root (`$EAW_WORKDIR`)
  - without `EAW_WORKDIR`: resolved relative to EAW core root.

## Diagnostics commands

```bash
EAW_WORKDIR="$PWD/.eaw" ./scripts/eaw validate
EAW_WORKDIR="$PWD/.eaw" ./scripts/eaw doctor
```

- `validate` checks config files, path parsing, repository path existence (warning), and workspace templates.
- `validate` also checks existence and minimal heading integrity for intake templates (`intake_bug.md`, `intake_feature.md`, `intake_spike.md`) in `EAW_TEMPLATES_DIR`.
- Exit code: `0` for success/warnings, `2` for validation errors.
- `doctor` prints resolved directories, tool availability, and config status, ending with `STATUS: OK|WARN|ERROR` (always exits `0`).

## EAW prompt

```bash
EAW_WORKDIR="$PWD/.eaw" ./scripts/eaw prompt 1234
```

- Prints an agent prompt to `stdout` to guide investigation of card `1234`.
- Persists the same prompt content to `out/<CARD>/agent_prompt.md` and prints `Wrote out/<CARD>/agent_prompt.md` to `stderr`.
- Detects card type by `out/<CARD>/{bug,feature,spike}_<CARD>.md` with priority `bug > feature > spike`.
- Expects intake in `out/<CARD>/investigations/00_intake.md`.
- Emits `WARN:` lines when type is ambiguous, intake is missing, or expected headings are missing by card type.

## Upgrade instruction

```bash
./scripts/eaw init --workdir "$PWD/.eaw" --upgrade
```

- Does not overwrite `repos.conf` or `search.conf` unless `--force`.
- For `eaw.conf`, creates it when missing.
- If `eaw.conf` is outdated or missing `config_version`, writes `eaw.conf.new` with the required version example.
