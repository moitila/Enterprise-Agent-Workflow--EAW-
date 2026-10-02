#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
base=templates/prompts/verification_validation_analysis
track=tracks/verification_validation_analysis
phases=(ingest intake source_inventory traceability_model verification_strategy validation_strategy quality_evaluation decision_evaluation critical_review analysis_package)
for p in "${phases[@]}"; do
  test -s "$track/phases/$p.yaml"
  test -s "$base/$p/prompt_v1.md"
  test "$(cat "$base/$p/ACTIVE")" = 1
  grep -q 'version=v1' "$base/$p/prompt_v1.meta"
done
# A: generic software is within scope; B/C: AI is conditional and metrics are not fabricated.
grep -qi 'software' "$base/verification_strategy/prompt_v1.md"
grep -qi 'no AI is evidenced in scope' "$base/quality_evaluation/prompt_v1.md"
grep -qi 'do not invent measurements' "$base/quality_evaluation/prompt_v1.md"
# D: missing ground truth remains unknown; E: traceability links source, method, evidence.
grep -qi 'ground truth' "$base/validation_strategy/prompt_v1.md"
grep -qi 'TBD' "$base/validation_strategy/prompt_v1.md"
grep -qi 'method/evidence needs' "$base/traceability_model/prompt_v1.md"
# F/G: upstream evidence is attributed and multi-root discovery is retained.
grep -qi 'provenance' "$base/source_inventory/prompt_v1.md"
grep -qi 'cross-repository evidence' "$base/source_inventory/prompt_v1.md"
# H/I: selected delivery targets and product-facing orchestration boundary.
grep -q 'DELIVERY_TARGETS' "$base/analysis_package/prompt_v1.md"
grep -qi 'orchestration' "$base/analysis_package/prompt_v1.md"
# J: strategy is analysis only; it must not execute or implement tests.
grep -qi 'Running or implementing tests' "$base/verification_strategy/prompt_v1.md"
grep -qi 'implementing fixes' "$base/critical_review/prompt_v1.md"
printf 'PASS: A-J V&V track implementation contracts\n'
