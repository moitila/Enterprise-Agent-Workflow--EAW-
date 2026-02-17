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

## Path resolution rules

- Absolute path (`/path/to/repo`): used as-is.
- Home-relative path (`~/repo`): expanded to `$HOME/repo`.
- Relative path in `repos.conf`:
  - with `EAW_WORKDIR` set: resolved relative to workspace root (`$EAW_WORKDIR`)
  - without `EAW_WORKDIR`: resolved relative to EAW core root.
