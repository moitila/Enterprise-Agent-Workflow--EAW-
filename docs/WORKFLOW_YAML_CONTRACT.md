# EAW Workflow YAML Contract

Version: 1.0

Purpose
-------
This document formalizes the YAML contract used by the EAW workflow engine for tracks, phases, and card state. It documents the current runtime behavior without changing CLI or execution semantics.

Status
------
- Official documentation target for card 538.
- The repository installs an official runtime tree under `tracks/standard/`.
- Backward-compatible with the current runtime model based on `out/<CARD>/intake/**`.
- `out/<CARD>/fixtures/**` are validation artifacts only and are not permanent runtime configuration.
- Compatibilidade com o modelo atual e requisito explicito deste contrato.
- `out/<CARD>/fixtures/**` nao sao configuracao permanente do runtime.

Scope
-----
This contract covers:
- the equivalent logical structures of `track.yaml`, `phase.yaml`, and card state;
- the meaning of `initial_phase`, `final_phase`, `phases`, `transitions`, and `prompt.path`;
- the current compatibility model implemented by the runtime;
- the minimum structure needed for a user to create a new track without reading shell code.

Indentation Rules
-----------------
- Use spaces, not tabs.
- Use two spaces per mapping level.
- List items are indented under their parent key with two additional spaces.
- Top-level roots used by the runtime are `track:`, `phase:`, and `card_state:`.

Canonical Logical Structure
---------------------------
The logical contract can be represented as:

```text
tracks/<track>/track.yaml
tracks/<track>/phases/*.yaml
tracks/<track>/card_state.yaml
```

Equivalent current runtime compatibility model:

```text
out/<CARD>/intake/track_*.yaml
out/<CARD>/intake/phase_*.yaml
out/<CARD>/intake/state_card_*.yaml
```

The current runtime in `scripts/commands/eaw_commands.sh` resolves the official repository tree first and keeps the compatibility model above as a fallback for per-card workflow artifacts. This document uses `track.yaml`, `phase.yaml`, and `card_state.yaml` as logical names, while explicitly preserving the current runtime-compatible file naming used today.

Track Contract
--------------
Required root:

```yaml
track:
  id: standard
  name: Standard Track
  description: Canonical workflow
  initial_phase: intake
  final_phase: implementation_executor
  phases:
    - intake
    - findings
    - hypotheses
    - planning
    - implementation_planning
    - implementation_executor
  transitions:
    intake:
      next: findings
```

Required fields:
- `track.id`
- `track.initial_phase`
- `track.final_phase`
- `track.phases`
- `track.transitions`

Optional fields:
- `track.name`
- `track.description`
- `track.rules`
- `track.initial_outputs`

Rules:
- `track.initial_phase` must be listed in `track.phases`.
- `track.final_phase` must be listed in `track.phases`.
- Every non-final phase must have `transitions.<phase>.next`.
- `track.final_phase` must not define a `next` transition.
- Transition sources and targets must exist in `track.phases`.
- Duplicate phases and duplicate transition sources are invalid.
- Historical aliases may be normalized by runtime helpers:
  - `hypoteses` -> `hypotheses`
  - `planing` -> `planning`
  - `implement_planing` -> `implementation_planning`

Phase Contract
--------------
Required root:

```yaml
phase:
  id: findings
  name: Findings
  description: Analyze intake evidence
  prompt:
    active: 1
    path: templates/prompts/default/findings/prompt_v<active>.md
  outputs:
    create_directories:
      - investigations
    create_artifacts:
      - investigations/20_findings.md
  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - investigations/20_findings.md
```

Required fields:
- `phase.id`
- `phase.prompt.path`

Optional fields:
- `phase.name`
- `phase.description`
- `phase.prompt.active`
- `phase.outputs`
- `phase.completion`

Rules:
- Each phase file must expose one `phase.id`.
- Each phase referenced by `track.phases` must have a matching phase config file.
- `prompt.path` must be resolvable via the ACTIVE prompt metadata.
- Valid prompt path patterns are derived from runtime-supported forms such as:
  - `templates/prompts/<track>/<phase>/prompt_v<active>.md`
  - `prompts/<track>/<phase>/prompt_v<active>.md`
- The runtime derives prompt binding from `prompt.path` and validates that the path is resolvable.

Card State Contract
-------------------
Logical name:
- `card_state.yaml`

Current runtime-compatible filename pattern:
- `state_card_*.yaml`

Required root:

```yaml
card_state:
  card_id: CARD_538
  track_id: standard
  current_phase: intake
  previous_phase: null
  phase_status: in_progress
  completed_phases: []
  created_at: "2026-03-13T00:00:00Z"
  updated_at: "2026-03-13T00:00:00Z"
```

Required fields currently validated by runtime:
- `card_state.track_id`
- `card_state.current_phase`

Observed optional fields:
- `card_state.card_id`
- `card_state.previous_phase`
- `card_state.phase_status`
- `card_state.completed_phases`
- `card_state.created_at`
- `card_state.updated_at`

Rules:
- `card_state.track_id` must match `track.id`.
- `card_state.current_phase` must exist in `track.phases`.
- If present and not `null`, `card_state.previous_phase` must exist in `track.phases`.
- `card_state.completed_phases` must not contain duplicates.
- Every completed phase must exist in `track.phases`.
- When `eaw next <CARD>` runs, the runtime updates `previous_phase`, `current_phase`, and `completed_phases` based on `track.transitions`.

Field Meanings
--------------
- `initial_phase`: first workflow phase allowed by the track.
- `final_phase`: terminal workflow phase; it must not declare a `next` transition.
- `phases`: ordered set of valid phase identifiers for the track.
- `transitions`: deterministic mapping from the current phase to the next phase.
- `prompt.path`: path used to bind a phase to a prompt family and ACTIVE candidate.

Validation Behavior Observed in Runtime
---------------------------------------
The current runtime validates at least the following:
- the official tree under `tracks/<track>/` when a card state points to an installed track;
- exactly one `track_*.yaml` file in the card intake directory;
- exactly one `state_card_*.yaml` file in the card intake directory;
- at least one `phase_*.yaml` file in the card intake directory;
- presence and consistency of required track and card state fields;
- consistency between `track.phases`, phase files, and `track.transitions`;
- prompt binding and ACTIVE resolution for every declared phase;
- final-phase behavior when `current_phase == final_phase`.

Creating a New Track Without Reading Code
-----------------------------------------
1. Define the logical track structure with one track file and one phase file per phase.
2. Choose explicit phase IDs and keep them consistent across `track.phases`, `transitions`, and phase file names.
3. Set `initial_phase` to the first phase and `final_phase` to the terminal phase.
4. Add `transitions.<phase>.next` for every non-final phase.
5. For each phase, define `phase.id` and a valid `prompt.path` that resolves through ACTIVE.
6. Create the card state file with matching `track_id` and an initial `current_phase`.
7. In the current runtime model, place compatibility files under `out/<CARD>/intake/` using:
   - `track_<name>.yaml`
   - `phase_<phase>.yaml`
   - `state_card_<name>.yaml`

Compatibility Notes
-------------------
- This document does not change the current runtime behavior.
- The current runtime resolves `tracks/<track>/track.yaml` and `tracks/<track>/phases/*.yaml` as the official source when the referenced track is installed in the repository.
- The current runtime remains compatible with the per-card model under `out/<CARD>/intake/**` as an explicit fallback.
- `state_card_*.yaml` under `out/<CARD>/intake/**` remains the mutable per-card state document for workflow progression.
- `out/<CARD>/fixtures/**` are useful for validation and tests, but they are not permanent runtime configuration.
- If product language refers to `card_state.yaml`, this should be read as the logical state document; current runtime compatibility still relies on `state_card_*.yaml`.

Non-Goals
---------
- This document does not introduce multi-track runtime support beyond what is already implemented.
- This document does not migrate existing cards automatically.
- This document does not modify prompt resolution, parser behavior, or CLI commands.
