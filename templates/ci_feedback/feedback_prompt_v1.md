# CI Feedback Prompt — {{CARD}} / {{TRACK}} / {{PHASE}}

You have just completed a phase of an EAW card. If you observed any of the
issues below, write a feedback file at:

  {{EAW_WORKDIR}}/ci_feedback/{{TRACK}}/{{PHASE}}/feedback_{{CARD}}.md

NOTE: A escrita em {{EAW_WORKDIR}}/ci_feedback/ é exceção operacional autorizada ao WRITE_SCOPE desta fase e não requer entrada na WRITE_ALLOWLIST soberana.

If you have no observations, skip this step entirely — do not create an empty file.

## Feedback format

Use only the sections where you have observations:

---
# CI Feedback — {{CARD}} / {{TRACK}} / {{PHASE}}
Date: [YYYY-MM-DD]

## Prompt issues
[Problems with the rendered phase prompt — unclear instructions, missing context, ambiguous scope]

## Runtime issues
[Unexpected EAW runtime behavior — wrong artifact names, schema errors, phase blocking]

## Missing context
[Context that would have helped the agent execute better]

## Artifact contract issues
[Wrong artifact names, schema violations, empty scaffolds that should have been pre-populated]

## Skill/trap suggestions
[New trap to document, skill adjustment, new rule]

## Suggested backlog items
[Improvements worth a formal card]

## Token/cost observations
[Phase too expensive, prompt too long, unnecessary iterations]
---

Omit sections where you have nothing to report.
This feedback file is ADDITIONAL — it does not replace any required phase artifact.
