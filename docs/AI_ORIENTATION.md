# EAW — AI Orientation Policy

This document declares the formal AI orientation policy for the EAW framework
repository. It exists to make explicit what has been operationally true but
never formally recorded: how EAW orients AI agents, and why specific orientation
artifacts are absent, minimal, or forbidden.

For the architectural foundation referenced throughout this document, see
[`docs/EAW_POSITIONING.md`](EAW_POSITIONING.md).

---

## 1. Skills as the Primary AI Orientation Mechanism

EAW orients AI agents through **skills** — structured markdown documents injected
directly into the agent context for a specific phase or operation. Skills are the
primary and authoritative mechanism for AI orientation in this repository.

**Why skills, not global orientation files:**

| Property | Global file (CLAUDE.md, AGENTS.md) | Skill |
|----------|-------------------------------------|-------|
| Scope | Entire repository, every session | Specific phase or operation |
| Granularity | Monolithic | Per-role, per-track, per-phase |
| Versioning | Single file, no phase binding | Individual files, declared in `phase.skills` |
| Context injection | Passive (loaded by client) | Active (delivered by operator per phase) |
| Drift risk | High (grows stale silently) | Low (bounded by card contract) |

The EAW model is a **deterministic context engineering system** (see
`docs/EAW_POSITIONING.md`, section 2): context is separated between stable
`onboarding` and operational `dynamic_context`, and injected per phase under
explicit contracts. A global orientation file is architecturally incompatible
with this model — it would conflate stable onboarding with dynamic phase
context, and deliver indiscriminate context to every agent session regardless
of the actual phase being executed.

**Current skills registry** (`skills/registry.yaml`): 11 skills covering
workspace operation, card execution, card creation, delivery, review, prompt
creation, track creation, repo onboarding, spike operations, workspace
bootstrap, and ADO connector.

Skills are the correct unit of AI orientation in EAW. They are granular,
versioned, contextual by card type, and delivered with explicit operator
intent. No global orientation file replicates or replaces this mechanism.

---

## 2. AGENTS.md in Target Repos — Minimal Complement Only

Repos operated by EAW as `target` repositories may optionally carry an
`AGENTS.md` file for clients that load it automatically (e.g., Codex).

**Permitted content (maximum):**

1. Repository identification (name, purpose, one sentence).
2. A reference to the EAW skills mechanism as the authoritative source of AI
   orientation (link or pointer to this document or to the EAW runtime root).
3. An explicit instruction not to reproduce skill content inline.

**Forbidden content:**

- Copies or paraphrases of EAW skill content.
- Phase-specific instructions (these belong in skills, not in AGENTS.md).
- Operational parameters (EAW_WORKDIR, repos.conf paths, token setup).
- Any content that would duplicate what the operator delivers via skills.

**Governance:** The creation, content, and lifecycle of `AGENTS.md` in target
repos is governed by the `repo_ai_context_assessment` phase of the
`repo_onboarding` track, which produces a `repo_ai_context.md` artifact per
onboarding card. No `AGENTS.md` should be created in a target repo outside
that process.

**This card (BL-04)** produces only this policy. It does not create any
`AGENTS.md` in any repository.

---

## 3. Absence of CLAUDE.md in the EAW Repository — Explicit Decision

`CLAUDE.md` does **not** exist in this repository. This is an explicit
architectural decision, not an omission.

**Justification:**

The EAW repository is a **control plane** (see `docs/EAW_POSITIONING.md`,
section 4), not a product repo or a target repo. Its AI orientation is
delivered entirely through the skills mechanism described in section 1 above.
A `CLAUDE.md` file would:

- Deliver context globally to every agent session, regardless of phase —
  violating the deterministic, phase-bounded context model of EAW.
- Duplicate content already versioned and governed in individual skill files.
- Create a second source of truth for operator behavior, with no phase binding
  and no contract to validate it against.
- Impose a monolithic orientation layer on top of a system explicitly designed
  to be modular and phase-scoped.

**Declaration:** `CLAUDE.md` will not be created in the EAW repository.
If orientation behavior for a new EAW role or operation is needed, the correct
action is to create or update a skill under `skills/`, register it in
`skills/registry.yaml`, and declare it in the relevant `phase.skills` contract.

---

## 4. Criterion for New AI Orientation Files in Target Repos

When a target repo may benefit from an AI orientation file, the criterion is:

> **Reference EAW skills. Do not create proprietary orientation content.**

Concretely:

- The file (if created) must reference the EAW skills mechanism as the
  authoritative source — not define its own orientation logic.
- The evaluation of whether a file is needed, its content, and its lifecycle
  are governed by the `repo_onboarding` track (`repo_ai_context_assessment`
  phase).
- Content must not exceed the maximum defined in section 2 above.
- Files must not be created as ad-hoc decisions outside the onboarding process.

The rationale: proprietary orientation content in target repos creates drift,
duplicates governance, and makes the AI orientation surface incoherent across
repos. The EAW skills system already provides the right mechanism — target repo
files should only point to it.

---

## Policy Summary

| Artifact | EAW repo | Target repo |
|----------|----------|-------------|
| `CLAUDE.md` | **Will not be created** (explicit decision, see section 3) | Not governed by this policy; follow target repo conventions |
| `AGENTS.md` | **Will not be created** (skills replace this) | Allowed, minimal only (see section 2) |
| `.cursorrules` / `.windsurfrules` | Not applicable | Not governed by this policy |
| Skills (`skills/`) | **Primary mechanism** (see section 1) | N/A — delivered by EAW operator |
| `repo_ai_context.md` | N/A | Produced per onboarding card by `repo_onboarding` track |
