# Architecture

EAW separates concerns across two layers: conceptual and operational.

- Conceptual layer: defines work types, decision boundaries, and deterministic output contracts. It describes the rituals for features, spikes, and bugs and how artifacts should be structured for auditability.

- Operational layer: the tooling and automation that collect context, scaffold artifacts, and enforce deterministic outputs. The CLI provided in `scripts/eaw` is part of this layer.

Pipeline

1. Intent: engineer creates a card (feature/spike/bug).
2. Context capture: EAW collects repository state and change artifacts deliberately.
3. Analysis: engineer or assistive AI fills structured markdown following the templates.
4. Decision: explicit deliverable with outcome, risk, and next steps.
5. Implementation & Validation: code changes are applied separately and validated.

Separation of phases prevents early collapse into coding and enforces traceability.

CLI

The CLI is a simple, deterministic helper that:
- Initializes local config from examples (`eaw init`).
- Generates a dossier for a card (`eaw feature|spike|bug <CARD> "<TITLE>"`).
- Collects context from configured repositories into `out/<CARD>/context/<repoKey>/`.

The CLI is intentionally simple and shell-based to remain portable and auditable.
