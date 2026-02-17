# EAW Compatibility Policy

## Compatibility Policy

### 1) EAW Versioning (SemVer)

- `MAJOR`
  - Breaking changes in CLI behavior or command interface.
  - Structural changes in output layout.
  - Command removals.
- `MINOR`
  - New commands.
  - New optional flags.
  - New backward-compatible behaviors.
- `PATCH`
  - Internal fixes.
  - Adjustments with no contract impact.

### 2) Configuration Versioning

- Configuration compatibility is controlled by `config_version`.
- `REQUIRED_CONFIG_VERSION` defines the minimum supported config version.
- Any change that requires manual config updates must increment `REQUIRED_CONFIG_VERSION`.
- Upgrade flows must never overwrite user config automatically.

### 3) Workspace Mode Contract

When `EAW_WORKDIR` is defined:

- Workspace configuration is mandatory.
- Core config is not used as fallback.
- Templates:
  - Workspace override is optional.
  - Fallback to core templates is allowed.

### 4) Output Contract

- The `out/<card>/` structure is stable within the same `MAJOR` version.
- Any structural output layout change requires a `MAJOR` bump.

### 5) Upgrade Policy

- `init --upgrade` is assisted and non-destructive.
- `.new` files are generated when needed.
- Config files are never overwritten without `--force`.

### Backward Compatibility Guarantee

The EAW project guarantees:
- No breaking changes within the same MAJOR version.
- Workspace mode and legacy mode remain supported unless explicitly deprecated in a MAJOR release.
