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
# K: exercise the existing resolver, delivery, persistence, scope, and completion helpers.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/analysis_delivery_contract.sh"
source "$ROOT/scripts/lib/phase_completion.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
selected="$tmp/selected"
other="$tmp/other"
infra="$tmp/infra"
card="$tmp/card"
mkdir -p "$selected/src" "$selected/docs" "$other/src" "$other/docs" "$infra/src" "$card/analysis" "$card/implementation"
printf 'distinctive propagated evidence\n' > "$other/src/evidence.md"
printf 'selected root\n' > "$selected/src/evidence.md"
cat > "$tmp/repos.conf" <<EOF
selected|$selected|target
other|$other|target
infra|$infra|infra
EOF
export EAW_CONFIG_DIR="$tmp"
cat > "$card/analysis/10_source_manifest.yaml" <<'EOF'
sources:
  - id: E1
    repository: other
    path: src/evidence.md
    required: true
    availability: available
EOF
resolved="$(eaw_delivery_resolve_inventory_sources "$card/analysis/10_source_manifest.yaml" "$tmp/repos.conf")"
grep -Fq "$other/src/evidence.md" <<< "$resolved"
grep -Fq 'distinctive propagated evidence' "$(cut -f3 <<< "$resolved")"
cat > "$card/analysis/bad.yaml" <<'EOF'
sources:
  - id: BAD
    repository: infra
    path: src/evidence.md
    required: true
    availability: available
EOF
if eaw_delivery_resolve_inventory_sources "$card/analysis/bad.yaml" "$tmp/repos.conf" 2>/dev/null; then exit 1; fi
sed 's#src/evidence.md#../escape.md#' "$card/analysis/10_source_manifest.yaml" > "$card/analysis/traversal.yaml"
if eaw_delivery_resolve_inventory_sources "$card/analysis/traversal.yaml" "$tmp/repos.conf" 2>/dev/null; then exit 1; fi
ln -s "$infra/src/evidence.md" "$other/src/escape.md"
sed 's#src/evidence.md#src/escape.md#' "$card/analysis/10_source_manifest.yaml" > "$card/analysis/symlink.yaml"
if eaw_delivery_resolve_inventory_sources "$card/analysis/symlink.yaml" "$tmp/repos.conf" 2>/dev/null; then exit 1; fi
cat > "$card/analysis/70_package_handoff.md" <<'EOF'
DELIVERY_TARGETS:
  - selected
ANALYSIS_STATUS: COMPLETE
COVERAGE_STATUS: COMPLETE
REQUIRED_AVAILABLE_NOT_EXAMINED: false
PERSISTENCE_STATUS: NOT_PERSISTED
EOF
cat > "$card/implementation/00_scope.lock.md" <<EOF
$selected/docs/verification-validation-analysis.md
$selected/docs/verification-validation-matrix.yaml
$selected/docs/verification-validation-decisions.yaml
EOF
printf 'authoritative report bytes\n' > "$card/analysis/verification-validation-analysis.md"
printf 'matrix: distinctive: 42\n' > "$card/analysis/verification-validation-matrix.yaml"
printf 'decisions: distinctive: accepted\n' > "$card/analysis/verification-validation-decisions.yaml"
if eaw_phase_completion_evaluate TEST-CARD "$card" analysis_package "$track/phases/analysis_package.yaml" 2>/dev/null; then exit 1; fi
mkdir -p "$selected/docs"
for path in docs/verification-validation-analysis.md docs/verification-validation-matrix.yaml docs/verification-validation-decisions.yaml; do
  src="$card/analysis/$(basename "$path")"
  eaw_delivery_persist_selected_file "$src" "$selected/$path" "$tmp/repos.conf" "$track/phases/analysis_package.yaml" "$card/implementation/00_scope.lock.md" TEST-CARD "$card/analysis/70_package_handoff.md"
  test -s "$selected/$path"
  cmp -s "$src" "$selected/$path"
  test ! -e "$other/$path"
done
cat >> "$card/analysis/70_package_handoff.md" <<EOF
PERSISTENCE_STATUS: PERSISTED
PERSISTED_PATHS:
- $selected/docs/verification-validation-analysis.md
- $selected/docs/verification-validation-matrix.yaml
- $selected/docs/verification-validation-decisions.yaml
EOF
eaw_phase_completion_evaluate TEST-CARD "$card" analysis_package "$track/phases/analysis_package.yaml"
test "$(find "$selected/docs" -maxdepth 1 -type f | wc -l)" -eq 3
test "$(find "$other/docs" -maxdepth 1 -type f | wc -l)" -eq 0
if grep -E 'CARD_ID|TEST-CARD' "$track/phases/analysis_package.yaml"; then exit 1; fi
grep -q 'analysis/40_quality_evaluation.md' "$track/phases/quality_evaluation.yaml"
grep -q 'analysis/40_quality_evaluation.md' "$base/quality_evaluation/prompt_v1.md"
grep -q 'NOT_APPLICABLE' "$base/quality_evaluation/prompt_v1.md"
grep -q 'TBD' "$base/quality_evaluation/prompt_v1.md"
printf 'PASS: A-J V&V track implementation contracts\n'
