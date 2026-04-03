---
name: eaw-track-creator
description: Create or revise EAW tracks and phases using the real EAW-tool workflow contract and CLI. Use when adding a new track, adding a phase, wiring transitions, registering a track, validating workflow YAML, or teaching the correct lifecycle for prompt suggestion, validation, proposal, and activation.
---

# EAW Track Creator

Use this skill when the task is to create, revise, register, or teach tracks and phases for the EAW.

This skill is for EAW workflow design and track lifecycle governance, not for executing a card.

## What This Skill Covers

- create a new EAW track under `tracks/<track>/`
- create a new phase under `tracks/<track>/phases/<phase>.yaml`
- wire `track.yaml` with `phases` and `transitions`
- teach the official install and validation flow
- teach the prompt lifecycle supported by the current `EAW-tool`

## Read These Sources First

Before drafting or reviewing a track, read:

- the `repos.conf` of the active execution environment
- the active runtime root docs for tracks and workflow YAML contract
- any prompt-governance or design notes explicitly pointed to by the user for the current workspace

When teaching prompt lifecycle, also read:

- the current runtime implementation of:
  - `validate-prompt`
  - `apply-prompt`
  - `suggest-prompt`
  - `propose-prompt`

Do not hardcode paths from one workspace into the skill.
Resolve them from the active runtime root and current workspace.
Treat `WORKDIR`, `EAW_WORKDIR`, `RUNTIME_ROOT`, and related values as execution-time values resolved by the active runtime.

## Runtime Truths You Must Respect

The current `EAW-tool` expects:

- `tracks/<track>/track.yaml`
- `tracks/<track>/phases/*.yaml`
- optional `tracks/<track>/card_state.yaml` as reference only

The runtime recognizes a track from repository tree plus registry:

- a valid `tracks/<track>/track.yaml`
- at least one `tracks/<track>/phases/*.yaml`
- `track.id` matching the directory name
- registration in `tracks/tracks.yaml` after `eaw tracks install`

Do not teach an imaginary track format.
Use the format the current runtime actually consumes.
Derive every runtime path from the active environment instead of hardcoding workspace-specific locations.

## Minimal Track Contract You Must Follow

Track files must use:

```yaml
config_version: 1

track:
  id: <track_id>
  name: <name>
  description: <description>
  initial_phase: <phase_id>
  final_phase: <phase_id>
  phases:
    - <phase_id>
  transitions:
    <phase_id>:
      next: <phase_id>
```

Required keys:

- `track.id`
- `track.initial_phase`
- `track.final_phase`
- `track.phases`
- `track.transitions`

Recommended keys:

- `track.name`
- `track.description`
- `track.initial_outputs`
- `track.rules`

## Minimal Phase Contract You Must Follow

Phase files must use:

```yaml
config_version: 1

phase:
  id: <phase_id>
  name: <phase_name>
  description: <description>
  prompt:
    active: <N>
    path: templates/prompts/<track>/<phase>/prompt_v<active>.md
  tooling_hints: []
  outputs:
    create_directories: []
    create_artifacts: []
    prompts:
      - <phase_alias>
  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - <artifact>
```

Required runtime fields:

- `phase.id`
- `phase.prompt.path`

Recommended for real tracks:

- `phase.name`
- `phase.description`
- `phase.prompt.active`
- `phase.tooling_hints`
- `phase.outputs`
- `phase.completion`
- `phase.skills`
- `phase.skills`

## Phase Skills Declaration

Phases podem declarar quais skills o agente isolado precisa ao executar a fase:

```yaml
phase:
  id: post_review
  skills:
    - workspace
    - reviewer
```

- `skills` é uma lista de nomes de skills disponíveis no workspace
- Se omitido, o executor assume `[workspace]` como fallback
- `workspace` é sempre incluída automaticamente pelo executor, mesmo se não listada
- As skills não aparecem no prompt da fase — só equipam o agente que vai executar
- Skills disponíveis no EAW: `workspace`, `reviewer`, `delivery`, `prompt_creator`, `track_creator`
- Ao criar phases de review pós-execução, declarar `reviewer`; ao criar phases de entrega (PR, CI), declarar `delivery`

## Creation Workflow

When creating a new track:

1. Define the track goal.
2. Choose phase IDs.
3. Map each phase to a semantic `phase_role` in your design notes.
4. Create `track.yaml` with `initial_phase`, `final_phase`, `phases`, and `transitions`.
5. Create one phase YAML file per phase.
6. Ensure every phase referenced by `track.phases` has a matching file in `phases/`.
7. Ensure every non-final phase has `transitions.<phase>.next`.
8. Ensure `track.id` exactly matches the directory name.
9. Create the prompt directories and candidates expected by `phase.prompt.path`.
10. Register the track with `eaw tracks install`.
11. Validate the workflow with `eaw validate workflow --all` or the relevant command accepted by the runtime.

Before steps 1-11, resolve:

- active runtime root
- active `WORKDIR` / `EAW_WORKDIR` when present in the execution environment
- active `EAW_TRACKS_DIR`
- active `repos.conf`

Never assume repository names or absolute paths from another workspace.

When creating a new phase:

1. Pick a stable `phase.id`.
2. Define the intended `phase_role` in the design notes.
3. Define outputs before writing the prompt.
4. Define completion based on required artifacts.
5. Define `tooling_hints` only when they add operational value.
6. Bind the phase to a real prompt path.
7. Ensure the phase can hand off to the next phase using outputs and contract, not the previous phase name.

## Official CLI Lifecycle You Must Teach

### Track discovery

Use:

```bash
./scripts/eaw tracks
```

This lists valid candidate tracks found under `tracks/`.

### Track registration

Use:

```bash
./scripts/eaw tracks install
```

This is the official install cycle:

- discover candidate directories under `tracks/`
- validate them against the minimum workflow contract
- register valid tracks in `tracks/tracks.yaml`
- reject invalid tracks with actionable reasons

Do not teach that copying a track directory alone makes it official.
The runtime recognizes official tracks from the repository tree plus registry semantics.

### Workflow validation

Use:

```bash
./scripts/eaw validate workflow --all
```

Or the narrower workflow validation accepted by the current runtime when appropriate.

Teach this as the structural validation step for track and phase wiring.

### Prompt family validation

Use:

```bash
./scripts/eaw prompt validate
```

This validates all prompt candidates under the templates tree.

### Prompt candidate validation

Use:

```bash
./scripts/eaw validate-prompt <TRACK> <PHASE> <CANDIDATE>
```

Important current rules from the tool:

- required sections are validated structurally
- required metadata must exist
- metadata version must match candidate version
- required substrings must exist
- forbidden words must be absent

### Prompt suggestion

Use:

```bash
./scripts/eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>
```

Teach this correctly:

- it creates proposal artifacts under `out/<CARD>/proposals/`
- it does not modify `ACTIVE`
- it does not directly change `templates/prompts/`

### Prompt proposal

Use:

```bash
./scripts/eaw propose-prompt <CARD> <TRACK> <PHASE> <BASE_CANDIDATE> <NEW_CANDIDATE>
```

Teach this correctly:

- it creates proposal artifacts in `out/<CARD>/proposals/`
- it copies the base candidate into proposal artifacts
- it updates proposal metadata to the new candidate version
- it does not apply the candidate automatically

### Prompt activation

Use:

```bash
./scripts/eaw apply-prompt <TRACK> <PHASE> <CANDIDATE>
```

Teach this correctly:

- it validates the candidate first
- it updates only `ACTIVE`
- it does not invent missing prompt directories

## Creation Guardrails

- never hardcode workspace-specific directories into the track or the skill instructions
- never create `track.yaml` with `track.id` different from the folder name
- never reference a phase in `track.phases` without a real phase YAML file
- never define a non-final phase without `transitions.<phase>.next`
- never define a final phase with `next`
- never bind a phase prompt to a fake path
- never teach prompt activation without validation
- never confuse `tracks/` discovery with official registration lifecycle
- never depend on phase name alone; use your design notes to map each phase to a semantic role
- never invent runtime commands not present in `EAW-tool`

## What To Output

When asked to create a track, provide:

- the proposed track structure
- the `track.yaml`
- the phase list
- one phase YAML skeleton per phase
- the install and validation commands
- known prompt directories that must exist

When asked to create a phase, provide:

- the target track
- the phase purpose
- the phase YAML
- the prompt path expected by runtime
- required artifacts and completion rule
- transition impacts

When asked to review, provide:

- `APROVADO`, `APROVADO_COM_RESTRICOES`, or `BLOQUEADO`
- critical structural failures first
- registration/validation steps next
- prompt lifecycle issues after that

## Fast Checklist

Before finalizing a new track or phase, confirm:

- `track.id` matches folder name
- all phases in `track.phases` exist as files
- all transitions are valid
- every phase has a resolvable prompt path
- prompt candidates can later pass `validate-prompt`
- the track can be installed with `eaw tracks install`
- the workflow can be checked with `eaw validate workflow --all`
