Enterprise Agent Workflow (EAW) – Architecture
1. Architectural Overview

Enterprise Agent Workflow (EAW) is structured around a dual-layer model:

Conceptual Architecture Layer

Operational Execution Layer

This separation ensures that the framework is not merely a tooling approach, but a disciplined engineering methodology.

2. Conceptual Architecture Layer

This layer defines the theoretical foundation of EAW.

It answers:

Why structured AI workflows are necessary in enterprise environments

How risk-aware AI integration should be designed
Enterprise Agent Workflow (EAW) — Architecture

## 1. Architectural overview

Enterprise Agent Workflow (EAW) is structured around a dual-layer model:

- Conceptual architecture layer
- Operational execution layer

This separation ensures the framework is both a disciplined engineering methodology and an implementable toolset.

## 2. Conceptual architecture layer

This layer defines the theoretical foundation of EAW and answers:

- Why structured AI workflows are necessary in enterprise environments
- How risk-aware AI integration should be designed
- What guarantees must exist before implementation begins

### 2.1 Work-type differentiation model

EAW defines three primary work types:

| Type    | Objective                  | Risk profile  | Engineering ritual required         |
|---------|----------------------------|---------------|------------------------------------|
| Feature | Introduce new behavior     | Medium–High   | Impact analysis + regression mapping |
| Spike   | Reduce uncertainty         | Low–Medium    | Evidence gathering                 |
| Bug     | Restore expected behavior  | High (localized) | Minimal safe correction          |

Each type enforces a distinct analysis and decision process.

### 2.2 Context engineering model

In enterprise systems, context must be deliberate. EAW defines context as a structured collection of:

- Repository state
- Change diffs
- Affected files
- Sensitive patterns
- Test-surface indicators
- Risk signals

Context is not chat memory — it is engineered input used to drive deterministic analysis.

### 2.3 Deterministic output contracts

All AI-assisted work must produce structured artifacts. EAW enforces:

- Markdown-based structured dossiers
- Defined sections and ordering
- Explicit assumptions and risk mapping
- Traceable reasoning and references to collected context

Unstructured AI output is not considered valid engineering output under the EAW contract.

## 3. Operational execution layer

The operational layer implements the conceptual model via lightweight CLI tooling and deterministic collectors.

### 3.1 CLI design philosophy

The `eaw` CLI enforces:

- Explicit work-type selection (`feature | spike | bug`)
- Automatic context collection from configured repositories
- Deterministic dossier generation from templates
- Separation between analysis and execution

Example:

```
eaw feature 682400 "Timezone hierarchy handling"
```

Generates (deterministic):

- `out/682400/feature_682400.md` — the dossier (lowercase filename by contract)
- `out/682400/context/<repoKey>/git-status.txt`
- `out/682400/context/<repoKey>/git-branch.txt`
- `out/682400/context/<repoKey>/git-commit.txt`
- `out/682400/context/<repoKey>/git-diff.patch`
- `out/682400/context/<repoKey>/changed-files.txt`
- `out/682400/context/<repoKey>/rg-symbols.txt` (search hits)

> Note: filenames are lowercase (`feature_*`, `spike_*`, `bug_*`) to remain consistent and machine-parseable.

### 3.2 Phase separation model

EAW enforces strict phase isolation:

1. Understanding
2. Analysis
3. Risk mapping
4. Decision
5. Implementation
6. Validation

Implementation must not precede structured analysis.

### 3.3 Risk surface identification

Operational scripts collect early signals such as:

- Modified core files
- Changes in shared modules
- Presence of sensitive keywords
- Potential regression zones

This shifts AI assistance from reactive to preventive.

## 4. Enterprise design principles

EAW follows four core principles:

- Predictability over improvisation
- Structure over conversation
- Risk-awareness over velocity
- Traceability over intuition

## 5. Positioning

EAW is not:

- A prompt collection
- An AI wrapper
- A code generation shortcut

EAW is a structured framework for integrating AI into enterprise engineering workflows.

## 6. Operational requirements & behavior

- Required: `git` (used to collect repository state and diffs).
- Optional: `rg` (ripgrep). If `rg` is available, EAW uses it to collect symbol hits; if not available, the CLI will fall back to `grep` where possible, or write `rg-symbols.txt` containing `MISSING_TOOL` to indicate the missing capability.
- Config: `config/repos.conf` maps `repoKey|path` and must point to accessible local repositories (relative or absolute).

This section documents expected tools and the CLI's fallback behavior so operators know how to adapt the environment.

## 7. Future extensions

Planned architectural evolutions include:

- CI integration mode
- Risk scoring engine
- Change blast-radius estimator
- Test-surface predictor
- Tool orchestration layer
