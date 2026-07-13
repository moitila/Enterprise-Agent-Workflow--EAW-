# EAW — Getting Started

EAW (Executable Agentic Workflow) is a **tool-agnostic, human-mediated workflow
framework**. It governs work through **cards**, **tracks**, **phases**, and
**rendered prompts** — it does not execute agents directly. Understanding this
distinction is the single most important prerequisite for operating EAW.

---

## The Three Roles

| Role | What they do | What they do NOT do |
|---|---|---|
| **Human requester** | Formulates the initial request, reviews artifacts, validates results | Does not operate the CLI, does not execute phases |
| **EAW operator / orchestrator** | Runs the CLI, creates cards, delivers rendered prompts to agents, reviews artifacts, advances phases | Does not execute the phase directly — delivers the prompt to an isolated agent |
| **Isolated phase agent** | Receives the rendered prompt for a specific phase, produces artifacts, returns them to the operator | Does not govern the card workflow, does not advance state in EAW |

> In early use, the **human requester** and the **EAW operator** are often the same person.

---

## The Core Cycle

```
initial request
     ↓
ingest/raw_card_explication.md
     ↓
card + track + phase
     ↓
eaw next <CARD>
     ↓
rendered phase prompt (out/<CARD>/prompts/)
     ↓
[manual handoff by operator]
     ↓
isolated agent session (separate)
     ↓
artifacts produced
     ↓
human review + EAW validation
     ↓
next phase or card complete
```

The key insight: **EAW generates the rendered prompt. The operator delivers it.
The agent executes it. EAW validates the result.** These are distinct steps,
distinct actors, and distinct responsibilities.

---

## Key Vocabulary

| Concept | Operational definition |
|---|---|
| **card** | The governed unit of work — a delimited request that traverses phases until complete |
| **track** | The execution path — defines which workflow family applies to the card |
| **phase** | One step in the card's flow — each phase has its own rendered prompt and expected artifacts |
| **ingest** | The canonical entry zone for the raw request — always `ingest/raw_card_explication.md` |
| **rendered prompt** | The instruction materialized by EAW for a specific phase — a derived view, not the original request |
| **artifact** | Any verifiable output produced by the isolated agent and brought back into the card |
| **next** | The CLI command that advances the phase and materializes the next rendered prompt |
| **preflight** | Pre-advance check of the workspace and card state — confirms readiness |
| **status** | Current view of the card: which phase, what has been produced, what remains |
| **isolated agent** | The separate agent session that executes one phase — does not govern the card |

> For the full vocabulary (14 concepts including `operator`, `allowlist`, `handoff`, `skill`),
> see `docs/CONCEPTUAL_MODEL.md`.

> For operational definitions of advanced concepts (`write_allowlist`, `scope.lock`,
> `handoff.json`, `phase.skills`, `preflight` vs `doctor`),
> see [`docs/CONCEPTS.md`](CONCEPTS.md).

## Repository Roles

Each repository registered in `repos.conf` carries a role that determines how EAW treats it during card execution:

| Role | Behavior | When to use |
|---|---|---|
| `target` | Included in `TARGET_REPOSITORIES`; the implement agent may write to files within this repo (subject to WRITE_ALLOWLIST) | Any repo where the card will produce changes |
| `infra` | Excluded from `TARGET_REPOSITORIES`; treated as runtime infrastructure, not modified by card agents | The EAW runtime itself, shared tooling, or repos that are read-only context for the card |

**When to change a role**: change `target` → `infra` if the repo is runtime infrastructure that card agents must not modify. Change `infra` → `target` if the card needs to produce artifacts (docs, code, config) inside that repo — and declare the target paths explicitly in `implementation/10_change_plan.md` (Involved Files section).

> Note: a missing role in `repos.conf` defaults to `target`. Source: `docs/CONTRACT.md`.

> For the AI orientation policy of this framework (skills as primary AI context mechanism,
> `CLAUDE.md` absence rationale, `AGENTS.md` guidance for target repos), see
> [docs/AI_ORIENTATION.md](AI_ORIENTATION.md).

---

## Common Misconceptions

### 1. "The agent operates the EAW."
**Wrong.** The operator/orchestrator operates the CLI. The isolated agent executes a single
phase when given the rendered prompt — it does not govern the workflow.

### 2. "If I chatted with the agent, the card already advanced."
**Wrong.** A conversation is not official state. Advancement requires verifiable artifacts
and EAW validation. A chat session that produced no artifacts does not move the card.

### 3. "The rendered prompt is the original request."
**Wrong.** The rendered prompt is a phase-specific projection. The original request lives
in `ingest/raw_card_explication.md` and must remain the canonical source of intent.

### 4. "I can put the initial request anywhere."
**Wrong.** The canonical location is `ingest/raw_card_explication.md`. This rule exists
to prevent intent from being scattered across chat, terminal, notes, and memory.

### 5. "Preflight is enough to guide me through EAW."
**Wrong.** Preflight validates operational readiness — it does not explain roles, the cycle,
or what the operator is supposed to do next conceptually. Both are necessary.

---

## Next step

→ **[docs/QUICKSTART.md](QUICKSTART.md)** — Zero to first card, step by step.
