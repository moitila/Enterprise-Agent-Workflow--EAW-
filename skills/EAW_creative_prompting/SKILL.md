---
name: eaw-creative-prompting
description: Design creative prompts for EAW phases that need exploration, divergence, comparison, consolidation, or validation. Use when a card needs prompt shape decisions for ideation, world building, production design, or script work.
---

# EAW Creative Prompting

Use this skill when the task is to design or review a prompt for a creative pipeline in EAW.

This skill governs prompt semantics and tone, not workflow wiring.

## What This Skill Produces

- prompt drafts for creative phases
- prompt mode selection guidance
- constraints for exploratory versus consolidatory work
- prompt structures that reduce drift
- handoff-aware prompt sections for later phases

## Core Rule

Choose the prompt mode before choosing the wording.

Exploration, comparison, consolidation, and validation are different prompt jobs.
Do not mix them unless the contract explicitly says the phase must do both.

## Prompt Modes

- `exploratory`: expand possibilities and surface candidates
- `divergent`: widen the search space and stress assumptions
- `comparative`: compare options under explicit criteria
- `consolidatory`: narrow to the chosen direction and stabilize it
- `validatory`: test whether the output satisfies the declared contract

## Workflow

1. Resolve the active workspace with the `workspace` skill.
2. Read the governing EAW contract if the prompt will live inside a real phase.
3. Determine the phase role before drafting wording.
4. Decide the prompt mode and make it explicit in the structure.
5. Anchor the prompt to the required artifacts and the next handoff.
6. Add constraints that prevent vague creative output.
7. Add validation criteria that can be checked without subjective guessing.

## Minimum Contract

A valid creative prompt should specify:

- objective
- allowed scope
- forbidden drift
- expected artifact
- handoff target
- validation rule

## Boundary With EAW Prompt Governance

This skill does not replace `EAW_prompt_creator`.

- `EAW_prompt_creator` governs the phase contract, prompt binding, and workflow shape.
- `EAW_creative_prompting` governs the creative mode and content behavior inside that contract.

## Guardrails

- never treat a vague prompt as creative by default
- never collapse exploratory and consolidatory intent into one unspecified request
- never bypass the workspace authority or `repos.conf`
- never define prompt behavior that depends on an unstated runtime detail
- never create track wiring or runtime logic

## Companion Skills

Use with:

- `workspace`
- `EAW_prompt_creator`
- `EAW_track_creator` when the prompt influences phase or track design
