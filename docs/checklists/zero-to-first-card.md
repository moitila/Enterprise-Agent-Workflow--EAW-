# Zero to First Card — Checklist

Use this checklist alongside **[docs/QUICKSTART.md](../QUICKSTART.md)**.
Check each item before moving to the next section.

---

## Understanding (before starting)

- [ ] I understand the three roles: **Human requester** / **EAW operator** / **Isolated phase agent**
- [ ] I understand that EAW does not execute the agent — I deliver the rendered prompt manually
- [ ] I understand that a conversation with an agent is not official card state
- [ ] I know where the initial request goes: `ingest/raw_card_explication.md`
- [ ] I know that the rendered prompt is a phase-specific view — not the original request

---

## Setup

- [ ] Workspace initialized (`eaw init --workdir <path>` or equivalent)
- [ ] `EAW_WORKDIR` exported and persisted in shell
- [ ] `eaw doctor` returns no critical errors
- [ ] Repository onboarded (`eaw card <REPO_KEY> --track repo_onboarding` — populates `context_sources/onboarding/<repo_key>/`)

---

## Card creation

- [ ] Track chosen (`eaw tracks`)
- [ ] Card created (`eaw card <CARD_ID> --track <TRACK>`)
- [ ] Initial request written in `ingest/raw_card_explication.md`
- [ ] All sections of the template filled (objective, expected result, scope, constraints)

---

## First cycle

- [ ] `eaw preflight <CARD_ID>` = PASS
- [ ] `eaw next <CARD_ID>` executed
- [ ] Rendered prompt found in `out/<CARD_ID>/prompts/`
- [ ] Separate agent session opened (any tool — EAW is tool-agnostic)
- [ ] Full rendered prompt delivered — not summarized, not paraphrased
- [ ] Artifacts received from the agent session

---

## Review

- [ ] Artifacts reviewed against the **original request** (not just the phase prompt)
- [ ] `eaw status <CARD_ID>` consulted
- [ ] Artifacts brought back into the card directory
- [ ] Ready to repeat the cycle (`eaw next`)

---

## Cycle complete?

- [ ] Card marked complete by EAW runtime
- [ ] Learnings noted for future cards (open questions resolved, new constraints identified)
