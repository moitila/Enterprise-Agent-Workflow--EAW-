# EAW — Zero to First Card

This guide walks you through your first complete EAW card cycle.
Before starting, read **[docs/GETTING_STARTED.md](GETTING_STARTED.md)** to understand
the three roles and the core cycle.

---

## Prerequisites

- EAW workspace initialized (see `skills/bootstrap_operator/SKILL.md`)
- `EAW_WORKDIR` exported and persisted in your shell
- `eaw doctor` returns no critical errors

---

## Step 1 — Choose a track

```sh
./scripts/eaw tracks
```

Review the available tracks. Choose the one that fits your card type.
If unsure, start with the default `feature` track.

---

## Step 2 — Create the card

```sh
./scripts/eaw card <CARD_ID> --track <TRACK>
```

Replace `<CARD_ID>` with a short, unique identifier (e.g., `my_first_card`).
The card directory will be created at `$EAW_WORKDIR/out/<CARD_ID>/`.

---

## Step 3 — Write your initial request

```sh
mkdir -p "$EAW_WORKDIR/out/<CARD_ID>/ingest"
# Edit: $EAW_WORKDIR/out/<CARD_ID>/ingest/raw_card_explication.md
# Template: templates/ingest/raw_card_explication.md
```

This file is the **canonical source of intent** for the entire card.
Fill it completely — do not leave the objective or expected result blank.
Use the template at `templates/ingest/raw_card_explication.md` as your starting point.

---

## Step 4 — Validate before advancing

```sh
./scripts/eaw preflight <CARD_ID>
```

Expected result: `PASS`. Resolve any reported issues before continuing.

---

## Step 5 — Advance the phase

```sh
./scripts/eaw next <CARD_ID>
```

EAW will determine the next action and materialize the rendered prompt for the current phase.

---

## Step 6 — Find the rendered prompt

```
out/<CARD_ID>/prompts/<phase_alias>.md
```

This is your **handoff artifact**. It contains the full instruction for the phase,
already assembled by EAW from the card state, track, and ingest material.

---

## Step 7 — Open a separate agent session

Open a new session in your preferred AI tool (any tool — EAW is tool-agnostic).
Deliver the **full rendered prompt** — do NOT summarize it, paraphrase it,
or add instructions on top of it. The prompt is self-contained.

The EAW does not execute the agent. **You do.**

---

## Step 8 — Bring artifacts back

The agent produces artifacts (documents, plans, code, analyses, etc.).
Bring them back into the card directory as directed by the phase prompt.
Review them against your **original request** in `ingest/raw_card_explication.md`
— not just against the phase prompt.

---

## Step 9 — Repeat until complete

```sh
./scripts/eaw status <CARD_ID>
./scripts/eaw next <CARD_ID>
```

Check status, advance the phase, deliver the new rendered prompt to the agent,
bring artifacts back, review. Repeat steps 5–8 until the card completes.

---

## Reference

- Model and vocabulary: [docs/GETTING_STARTED.md](GETTING_STARTED.md)
- Initial request template: [templates/ingest/raw_card_explication.md](../templates/ingest/raw_card_explication.md)
- First card checklist: [docs/checklists/zero-to-first-card.md](checklists/zero-to-first-card.md)
