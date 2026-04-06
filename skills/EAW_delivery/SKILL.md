---
name: eaw-delivery
description: Last-mile delivery governance for EAW cards. Use when preparing PRs, triaging CI failures, enforcing commit message standards, responding to code reviews, or validating cross-repo merge ordering. This skill covers the gap between "phase execution done" and "code merged".
---

# EAW Delivery

Use this skill when the task is to take completed card artifacts to production through PR, CI, and review cycles.

This skill governs delivery mechanics, not phase execution or prompt design.

## What This Skill Produces

- PR templates derived from card artifacts
- CI failure triage reports (pre-existing vs. introduced vs. flaky)
- commit message governance (format validation, AB#/SO- linkage)
- structured responses to code review comments (human or AI)
- push readiness checklists including cross-repo dependency ordering

## Core Rule

Every delivery artifact must be traceable to the card's execution outputs.

A PR description must describe what the code actually does, not what was planned. CI triage must be based on evidence (git blame, branch comparison), not assumption. Review responses must address the specific concern raised, not provide generic defenses.

## Commit Message Governance

### Format

```
type (scope): description [AB#NNN][SO-NNN]
```

- **type**: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`
- **scope**: module or component name, lowercase
- **AB#NNN**: Azure DevOps work item (User Story or Task, never Change Request directly)
- **SO-NNN**: Service Order reference (when applicable)

### Rules

- the commit message must reference only linkable work item types (User Story, Task)
- Change Requests (CR) are linked at the Azure DevOps board level, not in commit messages
- if `AB#` validation fails on push, verify the work item type in Azure DevOps before changing the message
- typos in AB# format (e.g., `[AB[#NNN]` instead of `[AB#NNN]`) must be caught before push
- when amending a commit that has already been pushed, use `--force-with-lease`, never `--force`

## PR Template

### Derivation workflow

1. Read the card's documentation artifacts (`out/<CARD>/docs/`, `out/<CARD>/investigations/`)
2. Read the actual `git diff` of the branch
3. Cross-reference: does the diff match the documented intent?
4. Produce the PR description from what the code **does**, supplemented by what the documentation **explains**

### Structure

- **Title**: `type(scope): one-line summary [AB#NNN]`
- **What changed**: list of concrete changes (file-level or module-level)
- **Why**: business justification from card context
- **How it works**: brief technical explanation of the approach
- **Testing**: what was tested, how, known gaps
- **Coexistence**: if the change lives alongside existing behavior, explain the activation mechanism
- **References**: link to technical documentation, card artifacts

### Guardrails

- never describe DTO fields, API parameters, or class names that don't exist in the actual code
- never copy documentation verbatim without verifying against the diff
- if a field was renamed or removed during implementation, the PR must reflect the final state
- the PR description is the public contract of the change — accuracy is non-negotiable

## CI Triage

### Classification

When CI fails after push, classify each failure:

| Classification | Criteria | Action |
|---------------|----------|--------|
| **pre-existing** | Failure exists on the base branch (main/dev) before our changes | Document, do not fix in this PR |
| **introduced** | Failure only appears on our branch, in code we changed | Fix before merge |
| **expected-dependency** | Failure because upstream repo not yet published/merged | Document, merge upstream first |
| **flaky** | Failure is intermittent, passes on retry, not in our code | Document, flag for infra team |

### Workflow

1. Get the CI build log
2. Identify each distinct failure (test name, compilation error, etc.)
3. For each failure:
   - check `git log` / `git blame` — did our commit introduce the failing code?
   - check if the same test fails on the base branch
   - check if the failure is a missing class/dependency from another repo in the card
4. Produce `ci_triage.md` with classification table

### Rules

- never classify as "pre-existing" without checking the base branch
- never classify as "introduced" without confirming the failing code is in our diff
- compilation failures due to unpublished dependencies are "expected-dependency", not bugs
- if a test class name contains `TestRunnerAutomation` or similar infra markers, check if it's a known flaky suite before assuming regression

## Review Response

### When responding to human reviews

- address each comment individually
- if the reviewer is right, fix and confirm
- if the reviewer misunderstood, explain with code reference (file + line)
- never argue — either fix or clarify with evidence

### When responding to AI reviews (Copilot, CodeRabbit, etc.)

- verify the AI's claim against actual code before accepting
- AI reviews often flag patterns that are intentional — explain the design choice if valid
- common false positives from AI:
  - "redundant provider call" — may be intentional for lazy evaluation
  - "missing null check" — may be guaranteed by framework contract
  - "field not used" — may be used via reflection or serialization
- if the AI is right, fix silently. If wrong, dismiss with one-line explanation.

## Cross-Repo Dependency Ordering

When a card spans multiple repositories:

1. Read `repos.conf` for the active repo set
2. Identify dependency direction from build files (`build.gradle`, `package.json`, `pom.xml`)
3. Determine merge/publish order:
   - **upstream first**: repos that produce libraries/artifacts consumed by others
   - **downstream last**: repos that consume the published artifacts
4. Document the ordering in the push checklist

### Rules

- never merge downstream before upstream is published
- if CI fails on downstream because upstream isn't published yet, classify as "expected-dependency"
- if forced to push downstream first (e.g., for PR creation), document that CI will fail until upstream merges
- `repos.conf` repo aliases are the canonical names — use them consistently across all delivery artifacts

## Push Readiness Checklist

Before declaring a branch ready for merge, verify:

- [ ] commit message follows format: `type (scope): description [AB#NNN][SO-NNN]`
- [ ] commit history is clean (single commit or logical sequence, no merge noise)
- [ ] PR description matches actual code diff
- [ ] CI passes, or all failures are classified (pre-existing / expected-dependency / flaky)
- [ ] review comments are addressed (fixed or explained)
- [ ] cross-repo dependencies: upstream repos merged/published first
- [ ] no local-only files committed (build configs, IDE files, SNAPSHOT versions)
- [ ] branch name follows repo conventions

## Guardrails

- never force-push without evidence that history was corrupted or needs amendment
- never use `--no-verify` to bypass pre-push hooks
- never merge with unaddressed review comments
- never claim CI is "green" when failures are merely classified as pre-existing — disclose them
- never commit files that should remain local (SNAPSHOT versions, local build overrides)
- never create a PR without reading the actual diff first
- the delivery skill does not modify phase artifacts — it only reads them for context

## EAW-Specific Notes

- Card artifacts live in `out/<CARD>/`. Read them, never write back into them from delivery.
- `repos.conf` is the source of truth for repo identity and aliases.
- If the card used isolated agents per phase, each agent's output is already in artifacts — use those as PR evidence.
- The execution journal (`execution_journal.jsonl`) can provide timing and status for "Testing" section of PR.
- Delivery is the bridge between EAW's governed execution and the team's git/CI/review workflow.

## Fast Checklist

Before finalizing any delivery artifact, confirm:

- PR description matches the actual diff, not just the design docs
- every CI failure has a classification with evidence
- commit messages pass format validation
- cross-repo ordering is documented if multiple repos are involved
- review responses address specific concerns, not generic patterns
- no local/temporary files are staged for commit