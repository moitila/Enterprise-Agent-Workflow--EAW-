# EAW Commit Standard (ECS)

## Name

EAW Commit Standard (ECS)

## Motivation (architectural)

Software engineering in enterprise environments requires strong governance over change artifacts. Commits are first-class traces of intent and risk; they must be structured so that downstream automation, audits and reviewers can deterministically understand risk, scope and phase of work. ECS augments Conventional Commits with a small, mandatory metadata block to improve traceability and enable automated enforcement.

## Scope

This standard applies to all commits that change source, documentation, configuration, and CI in the Enterprise Agent Workflow (EAW) repository.

## Formal structure

The commit message MUST contain:

1. A header (first line) following Conventional Commits style with a constrained work-type namespace:

   <type>(<work-type>): <summary>

   where `<type>` is one of: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`.

2. A metadata block in the commit body containing the following mandatory fields (one per line):

   [Risk-Level]: <value>
   [Impact-Scope]: <value>
   [Phase]: <value>
   [EAW-ID]: <value>

   Fields may appear in any order in the body but must be present exactly with these labels.

## Allowed values

- Risk-Level: `low` | `medium` | `high`
- Impact-Scope: `local` | `module` | `cross-module` | `system`
- Phase: `analysis` | `implementation` | `validation`
- Work-Type (in header parentheses): `feature` | `spike` | `bug`

`EAW-ID` is an opaque identifier used by the team to correlate a commit to an EAW card or decision record. It must be present and non-empty; format rules for EAW-ID are governed by project practice (numeric or alphanumeric) and are intentionally permissive.

## Examples (valid)

Example 1 — feature implementation

feat(feature): introduce EAW Commit Standard (ECS)

[Risk-Level]: low
[Impact-Scope]: module
[Phase]: implementation
[EAW-ID]: 000000

Decision:
- Add commit governance model
- Enforce via git hook

Example 2 — bug analysis

fix(bug): clarify null check in config loader

[Risk-Level]: medium
[Impact-Scope]: local
[Phase]: analysis
[EAW-ID]: 1023

Notes: include reproduction steps in the body after the metadata block.

## Examples (invalid)

- Missing metadata block
- Invalid Risk-Level value (e.g. `[Risk-Level]: critical`)
- Header using non-allowed type or work-type (e.g. `feature(feature): ...` instead of `feat(feature): ...`)
- Empty `[EAW-ID]:` line

## Justification and design rationale

ECS is intentionally compact and compatible with Conventional Commits to maximize tool interoperability (commit linting, changelog generation). The added metadata fields address governance needs: explicit risk-level and impact scope make review triage deterministic; phase tagging clarifies intent (analysis vs implementation); and EAW-ID ties the commit to the higher-level dossier or card for auditability.

This pattern balances developer ergonomics and enterprise requirements: it is lightweight to author, machine-parseable, and enforcible via git hooks and CI checks.

## Enforcement

The repository includes a `hooks/commit-msg` script that enforces ECS at commit time. Install it by running `scripts/install-hooks.sh` or ensure CI runs the same validation.
