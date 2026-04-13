---
name: eaw-creative-research
description: Build structured creative research for EAW creative pipelines. Use when a card needs references, cultural notes, anti-cliche evidence, symbol mapping, or a research brief that will feed ideation and world definition.
---

# EAW Creative Research

Use this skill when the task is to collect, organize, or review research for a creative pipeline in EAW.

This skill is for semantic research design, not for final narrative writing or runtime wiring.

## What This Skill Produces

- structured research briefs
- reference maps
- cultural and symbolic note sets
- anti-cliche guardrails
- evidence-backed creative inputs for later prompt work

## Core Rule

Research must be reusable by a future prompt or track decision.

Do not collect facts without a reuse path.
Do not write prose filler.
Do not confuse research with final creative output.

## Workflow

1. Resolve the active workspace with the `workspace` skill and `repos.conf`.
2. Define the creative target in one sentence.
3. Gather evidence in bounded themes:
   - culture
   - symbol
   - aesthetic
   - custom
   - reference
4. Split the notes into:
   - Observation: what is directly supported by evidence
   - Interpretation: what those observations may imply
5. Mark what is reusable, what is risky, and what is still uncertain.
6. Produce a compact brief that a prompt-authoring skill can consume without guessing.

## Minimum Contract

A valid research output should make these points explicit:

- what was researched
- why it matters for the creative pipeline
- which observations are supported by evidence
- which claims are still tentative
- what should be avoided as cliche, exotization, or surface reading

## Guardrails

- never write the final narrative as if it were research
- never blur sourced facts and creative invention
- never treat a single reference as a full design
- never ignore the workspace authority or the active `repos.conf`
- never create runtime logic or track wiring
- avoid cliche by checking whether the note adds evidence or only mood
- avoid exotization by preferring grounded context over spectacle
- avoid surface-level readings when a deeper pattern is available

## Companion Skills

Use with:

- `workspace`
- `EAW_prompt_creator` when the result will feed a governed phase prompt
- `EAW_track_creator` when the result influences a track contract
