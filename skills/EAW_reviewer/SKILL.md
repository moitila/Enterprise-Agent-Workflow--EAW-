---
name: eaw-reviewer
description: Post-execution review of EAW cards. Use when a card finished execution and you need to produce a review report, derive improvement backlogs, generate executive journals for PO/managers, or create technical handoffs for developers. This skill governs what happens AFTER phases complete, not during.
---

# EAW Reviewer

Use this skill when the task is to review a completed (or partially completed) card execution and produce structured post-execution artifacts.

This skill is for post-execution analysis, not for running phases or creating tracks.

## What This Skill Produces

- review reports with classified evidence from card execution
- improvement backlogs derived from execution evidence
- executive journals for PO and managers (commercial tone, no code)
- technical handoffs for developers (implementation-ready context)
- tier-classified cards with deterministic criteria and dependency graphs

## Core Rule

Every finding in a review or backlog must trace back to a concrete artifact, log entry, or observable event from the card execution.

Never derive a card, finding, or recommendation from opinion, intuition, or general best practice alone. The evidence must exist in `out/<CARD>/` or in the operator's documented observations.

## Inputs

Before starting a review, gather:

- `out/<CARD>/` — full artifact tree (phase outputs, prompts, execution_journal.jsonl)
- operator observations — what the operator noticed during execution (bugs, friction, workarounds)
- `repos.conf` — to understand repo scope
- PR feedback, CI logs, review comments — if the card reached delivery

If `execution_journal.jsonl` is absent or incomplete, note it as a finding but do not block the review.

## Workflow

1. **Inventory execution artifacts**
   - list all files under `out/<CARD>/`
   - check `execution_journal.jsonl` for phase events (started, completed, failed)
   - note any empty or template-only artifacts that passed phase completion

2. **Collect operator observations**
   - ask or read documented friction points, workarounds, runtime bugs
   - cross-reference with artifacts — did the artifact capture the issue?

3. **Classify findings**
   Each finding gets:
   - `id`: sequential (F-001, F-002, ...)
   - `type`: one of `runtime_bug`, `contract_violation`, `missing_artifact`, `friction`, `improvement`, `documentation_gap`
   - `severity`: one of `blocker`, `high`, `medium`, `low`
   - `evidence`: file path, log line, or operator observation reference
   - `description`: what happened
   - `recommendation`: what should change

4. **Derive backlog (if applicable)**
   - group related findings into candidate cards
   - assign tier using deterministic criteria:
     - **Tier 0**: blocks next card execution (runtime crash, data loss)
     - **Tier 1**: contract violation or silent failure (wrong output accepted, validation skipped)
     - **Tier 2**: friction or inefficiency (manual workaround needed, confusing output)
     - **Tier 3**: improvement or polish (better defaults, clearer messages)
   - each card needs: title, tier, justification, source finding(s), estimated scope
   - build dependency graph between derived cards

5. **Produce output artifacts**
   Choose which outputs are needed based on audience:
   - `review_report.md` — full evidence-based review (always)
   - `backlog.md` — derived improvement cards (when findings warrant)
   - `journal_<CARD>.md` — executive/PO version (when requested)
   - `handoff.md` — technical developer version (when requested)

## Output Style

### review_report.md

Structure:
- Executive summary (3-5 lines, what the card did, key outcome)
- Findings table (id, type, severity, description, evidence)
- Statistics (phases executed, artifacts produced, findings by severity)
- Recommendations (prioritized)

### backlog.md

Structure:
- Architecture decisions (if any emerged from the review)
- Card table (id, title, tier, justification, dependencies)
- Dependency graph (text-based DAG)
- Phase attack order (which cards to tackle first)
- Risks

### journal_<CARD>.md

Rules:
- commercial/executive tone — no code, no file paths, no technical jargon
- focus on business value delivered, practical benefits, coexistence with existing behavior
- reference technical documentation for details, do not inline it
- suitable for PO, product managers, stakeholders

### handoff.md

Rules:
- technical tone — file paths, class names, method signatures are expected
- focus on what the next developer needs to know to continue the work
- include: what changed, what was not changed and why, known limitations, test status

## Guardrails

- never derive a backlog card without traceable evidence
- never mix executive and technical tone in the same artifact
- never assign a tier without applying the deterministic criteria above
- never produce a backlog without a dependency graph
- never claim a phase succeeded if `execution_journal.jsonl` shows FAIL or absence
- never assume artifacts are valid just because they exist — check for empty/template-only content
- never include code snippets in a journal for PO
- never omit evidence references in a review report finding

## Audience Routing

| Artifact | Audience | Tone | Code allowed |
|----------|----------|------|--------------|
| review_report.md | Engineering team | Technical | Yes |
| backlog.md | Engineering lead | Mixed (structured) | Minimal |
| journal_<CARD>.md | PO / Managers | Commercial | No |
| handoff.md | Developers | Technical | Yes |

## EAW-Specific Notes

- The review reads from `out/<CARD>/` but never writes back into the card's phase artifacts.
- Review outputs go to `out/<CARD>/reviews/` or to a location specified by the operator.
- `execution_journal.jsonl` is the source of truth for what the runtime executed.
- If the runtime accepted empty artifacts, that is itself a finding (type: `runtime_bug` or `contract_violation`).
- The reviewer does not re-execute phases. It evaluates what was produced.
- Treat `repos.conf` as the source of truth for repo scope. If a card touched repos not in `repos.conf`, flag it.

## Fast Checklist

Before finalizing any review artifact, confirm:

- every finding has an evidence reference
- every backlog card has a tier with justification
- the dependency graph covers all derived cards
- executive artifacts contain zero code or file paths
- technical artifacts contain actionable paths and names
- the review does not depend on informal context not captured in artifacts