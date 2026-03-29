# ONBOARDING_TEMPLATE_GOVERNANCE

## Purpose

This document defines the governance rules for versioned onboarding templates in EAW.
Its purpose is to make onboarding template selection, structure, and evolution auditable.

## Scope

This governance applies to the repository-owned template layer under `templates/context/onboarding/`.
It does not govern workspace onboarding content stored under `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/`.

## Repository Contract

Concrete repository elements:
- `templates/context/onboarding/<template_name>/ACTIVE`
- `templates/context/onboarding/<template_name>/template_vN.md`
- `templates/context/onboarding/<template_name>/template_vN.meta`

`ACTIVE` is the operational selector for the versioned onboarding template in each namespace.
The active template must be resolved through the logical template identifier and the local `ACTIVE` file, not by direct path binding in YAML.

## Naming And Versioning

- Namespaces must use stable logical names such as `repo_discovery`, `architecture_first`, `debug_first`, and `execution_guardrails`.
- Versioned template files must follow the pattern `template_vN.md`.
- Versioned metadata files must follow the pattern `template_vN.meta`.
- `ACTIVE` must point to the concrete Markdown file selected for operational use.

## Minimum Template Structure

Each onboarding template must document, at minimum:
- `OBJECTIVE`
- `INPUT`
- `OUTPUT`
- `READ_SCOPE`
- `RULES`

This minimum structure keeps the template readable, reviewable, and operationally consistent.

## Resolution Model

`phase.context.onboarding_template` is a logical identifier, not a file path.
Path-style values are invalid.
The runtime resolves the logical identifier to a namespace under `templates/context/onboarding/` and then uses `ACTIVE` to determine the selected `template_vN.md`.

## Boundary Between Template And Workspace Content

Workspace onboarding content and EAW template rendering are separate concerns.
The workspace provides repository facts from `<EAW_WORKDIR>/context_sources/onboarding/<repo_key>/`.
The template layer defines how that material is organized and presented.
The template must not replace or redefine the workspace content it renders.

## Materialization And Readability

Any declared onboarding context must be materialized before prompt injection.
The resulting artifact must be legivel para engenheiro, with clear structure and provenance to the onboarding source.
If the produced artifact cannot explain what source material was organized and why, the audit trail is incomplete.

## Change Control

- New onboarding templates must be added under `templates/context/onboarding/`.
- Changes must preserve the logical identifier contract used by `phase.context.onboarding_template`.
- Changes must not introduce path direto in YAML.
- Temporary or repository-specific onboarding notes must remain in workspace content, not in the EAW template layer.
