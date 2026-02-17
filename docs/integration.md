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
- Exit code: `0` for success/warnings, `2` for validation errors.
- `doctor` prints resolved directories, tool availability, and config status, ending with `STATUS: OK|WARN|ERROR` (always exits `0`).

## Upgrade instruction

```bash
./scripts/eaw init --workdir "$PWD/.eaw" --upgrade
```

- Does not overwrite `repos.conf` or `search.conf` unless `--force`.
- For `eaw.conf`, creates it when missing.
- If `eaw.conf` is outdated or missing `config_version`, writes `eaw.conf.new` with the required version example.
