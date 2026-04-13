---
name: eaw-creative-governance
description: Govern handoffs, boundaries, and artifact sovereignty for EAW creative pipelines. Use when a card needs cross-track contracts, pilot gates, or rules that prevent one creative track from silently taking over another.
---

# EAW Creative Governance

Use this skill when the task is to design or review boundaries between creative tracks in EAW.

This skill governs contracts between creative phases and tracks, not the content-writing itself.

## What This Skill Produces

- handoff checklists
- boundary rules between tracks
- artifact sovereignty maps
- pilot gate definitions
- risk notes for drift and overlap

## Core Rule

Each track must own a distinct responsibility.

If a track can silently redo another track's work, the governance is weak.

## Workflow

1. Resolve the active workspace with the `workspace` skill.
2. Identify the track boundary that needs protection.
3. List the artifacts that are sovereign for the current track.
4. List the artifacts that must be accepted from the previous track without redefinition.
5. Define the gate that proves the current track is safe to expand.
6. Record what the track is not allowed to do.
7. Produce a handoff rule that a future card can apply without reinterpretation.

## Minimum Contract

A valid governance output should specify:

- upstream handoff
- downstream handoff
- accepted artifacts
- rejected overlap
- pilot gate
- residual risk

## Boundary Model

The Coringas pipeline uses the following governance pattern:

- `creative_ideation` explores and selects direction.
- `world_definition` stabilizes the chosen world model.
- `production_design` translates the world into production decisions.
- `script_finalization` consolidates the final script packet.

The governance skill must prevent these overlaps:

- ideation writing the final script
- world definition rewriting the ideation brief
- production design redoing worldbuilding
- script finalization inventing new world rules

## Relationship To EAW Governance Skills

This skill does not replace `EAW_prompt_creator` or `EAW_track_creator`.

- `EAW_prompt_creator` governs the phase and prompt contract.
- `EAW_track_creator` governs track wiring, installation, and workflow validation.
- `EAW_creative_governance` governs semantic responsibility and handoff integrity inside the creative domain.

## Guardrails

- never let a pilot gate disappear
- never let a handoff become an implicit assumption
- never let a track absorb another track's scope
- never use the active runtime root as a write target for the Coringas backlog
- never create runtime logic while writing governance

## Companion Skills

Use with:

- `workspace`
- `EAW_prompt_creator`
- `EAW_track_creator`
- `EAW_creative_research`
- `EAW_creative_prompting`
