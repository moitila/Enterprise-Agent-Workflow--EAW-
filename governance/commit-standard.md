# EAW Commit Standard (ECS)

## Name

EAW Commit Standard (ECS)

## Motivation (architectural)

Commits are primary engineering artifacts in enterprise repositories: they represent intent, risk, and the minimal unit of traceability. ECS complements Conventional Commits by attaching a compact metadata block that makes risk, scope and phase explicit. This enables deterministic automation (changelogs, audits, triage) and reduces ambiguity during reviews.

## Problem addressed

- Unclear risk posture attached to commits
- Difficulty automating triage and release decisions
- Limited traceability between commit and higher-level decision records

ECS solves these by enforcing a minimal, machine-parseable metadata contract.

## Formal structure (mandatory)

Header (first line) — Conventional Commits compatible:

  <type>(<work-type>): <short-summary>

Where `<type>` ∈ {`feat`, `fix`, `refactor`, `docs`, `chore`, `test`} and `<work-type>` ∈ {`feature`, `spike`, `bug`}.

Body (metadata block) — REQUIRED fields (labels are exact and case-sensitive):

  [Risk-Level]: <low|medium|high>
  [Impact-Scope]: <local|module|cross-module|system>
  [Phase]: <analysis|implementation|validation>
  [EAW-ID]: <card-id>

Fields may appear in any order in the body but must be present and non-empty.

## Permitted values (table)

| Field         | Allowed values |
|---------------|----------------|
| Risk-Level    | low, medium, high |
| Impact-Scope  | local, module, cross-module, system |
| Phase         | analysis, implementation, validation |
| Work-Type     | feature, spike, bug |

## Examples (valid)

```
feat(feature): introduce governance layer with ECS enforcement

[Risk-Level]: low
[Impact-Scope]: module
[Phase]: implementation
[EAW-ID]: 000000

Decision:
- Introduce formal commit governance model
- Enforce via git commit hook

Risk Notes:
- No runtime impact
- Developer workflow change only
```

```
fix(bug): add guard for missing config value

[Risk-Level]: medium
[Impact-Scope]: local
[Phase]: analysis
[EAW-ID]: 1024

Reproduction steps: ...
```

## Examples (invalid)

- Missing any of the required metadata lines (e.g. no `[Risk-Level]:`)
- Using `feature(feature): ...` instead of `feat(feature): ...` in header
- Invalid `Risk-Level` value (e.g. `critical`)
- Empty `[EAW-ID]:` value

## Governance & traceability

ECS enforces that each commit carries minimal governance context. Tooling (hooks, CI, changelog generation) can parse this metadata to:

- Triage PRs by risk and scope
- Connect commits to EAW dossiers or decision records (via `EAW-ID`)
- Automate release policies (block high-risk system-scoped commits without additional gates)

This reduces manual process friction while preserving auditability for regulated environments.

## Strategic justification for enterprise

ECS strikes a balance between operational rigor and developer ergonomics. It is intentionally concise to maximize adoption while providing the signals necessary for enterprise governance: explicit risk, explicit scope, phase semantics, and a link to the authoritative decision record.
