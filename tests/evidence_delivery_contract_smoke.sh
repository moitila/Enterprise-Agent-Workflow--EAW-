#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/analysis_delivery_contract.sh"
source "$ROOT/scripts/lib/phase_completion.sh"
source "$ROOT/scripts/lib/workflow_validation.sh"
source "$ROOT/scripts/commands/eaw_commands.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Generic fixture universe: two target roots and one infra root.
repo_a="$tmp/frontend"
repo_b="$tmp/backend"
repo_c="$tmp/database"
infra="$tmp/infra"
mkdir -p "$repo_a/docs" "$repo_b/docs" "$repo_b/src" "$repo_c/docs" "$infra/docs" "$tmp/card/analysis" "$tmp/card/investigations" "$tmp/destination"
printf 'frontend evidence\n' > "$repo_a/docs/source.md"
printf 'backend evidence with distinctive semantic content\n' > "$repo_b/src/source.md"
printf 'database evidence\n' > "$repo_c/docs/source.md"
printf 'infra must not enter corpus\n' > "$infra/docs/internal.md"
cat > "$tmp/repos.conf" <<EOF
frontend|$repo_a|target
backend|$repo_b|target
database|$repo_c|target
eaw|$infra|infra
EOF
mkdir -p "$tmp/config"
cp "$tmp/repos.conf" "$tmp/config/repos.conf"
export EAW_CONFIG_DIR="$tmp/config"

# A/B: roots themselves authorize discovery; multiple roots are exposed, infra is excluded.
roots="$(eaw_delivery_target_roots "$tmp/repos.conf")"
grep -Fq $'frontend\t' <<< "$roots"
grep -Fq $'backend\t' <<< "$roots"
grep -Fq $'database\t' <<< "$roots"
! grep -Fq $'eaw\t' <<< "$roots"
test -f "$(realpath -e "$repo_a/docs/source.md")"
grep -Fq 'frontend evidence' "$repo_a/docs/source.md"

# C: discovery manifest propagates selected, real source content downstream without a selector file.
cat > "$tmp/card/analysis/10_source_manifest.yaml" <<'EOF'
sources:
  - id: F1
    repository: frontend
    path: docs/source.md
    required: true
    availability: available
  - id: B1
    repository: backend
    path: src/source.md
    required: true
    availability: available
  - id: D1
    repository: database
    path: docs/source.md
    required: true
    availability: available
EOF
inventory="$(eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/10_source_manifest.yaml" "$tmp/repos.conf")"
grep -Fq "$repo_a/docs/source.md" <<< "$inventory"
grep -Fq "$repo_b/src/source.md" <<< "$inventory"
grep -Fq "$repo_c/docs/source.md" <<< "$inventory"
cat > "$tmp/card/analysis/infra.yaml" <<'EOF'
sources:
  - id: X1
    repository: eaw
    path: docs/internal.md
    required: true
    availability: available
EOF
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/infra.yaml" "$tmp/repos.conf" 2>/dev/null
downstream_content="$(while IFS=$'\t' read -r _ _ source_path; do cat "$source_path"; done <<< "$inventory")"
grep -Fq 'distinctive semantic content' <<< "$downstream_content"

# D: traversal, absolute external paths, and symlink escapes are rejected.
cat > "$tmp/card/analysis/bad.yaml" <<EOF
sources:
  - id: T
    repository: frontend
    path: ../outside.md
    required: true
    availability: available
EOF
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/bad.yaml" "$tmp/repos.conf" 2>/dev/null
ln -s "$infra/docs/internal.md" "$repo_b/docs/escape.md"
sed 's#../outside.md#docs/escape.md#' "$tmp/card/analysis/bad.yaml" > "$tmp/card/analysis/symlink.yaml"
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/symlink.yaml" "$tmp/repos.conf" 2>/dev/null
sed "s#../outside.md#$tmp/external.md#" "$tmp/card/analysis/bad.yaml" > "$tmp/card/analysis/absolute.yaml"
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/absolute.yaml" "$tmp/repos.conf" 2>/dev/null

# A-C: three repositories provide evidence, while an explicit analysis decision selects one delivery root.
cat > "$tmp/analysis_package.yaml" <<'EOF'
phase:
  delivery_contract: required
  package_artifact: analysis/package.md
  target_delivery_paths:
    - "docs/product/report.md"
EOF
cat > "$tmp/card/analysis/package.md" <<'EOF'
DELIVERY_TARGETS:
  - backend
EOF
allowlist="$(eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD-1 "$tmp/card/analysis/10_source_manifest.yaml" "$tmp/card/analysis/package.md" true)"
test "$allowlist" = "$repo_b/docs/product/report.md"
! grep -Fq "$repo_a/" <<< "$allowlist"
! grep -Fq "$repo_c/" <<< "$allowlist"
! grep -Fq "$infra/" <<< "$allowlist"
allowlist_other_card="$(eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD-2 "$tmp/card/analysis/10_source_manifest.yaml" "$tmp/card/analysis/package.md" true)"
test "$allowlist" = "$allowlist_other_card"
! grep -Fq 'CARD-' <<< "$allowlist"

# Runtime allowlist exposure stays empty until the handoff has a selection,
# then exposes only the selected root and declared paths.
runtime_allowlist="$(eaw_card_write_allowlist_entries "$tmp/card" "$tmp/analysis_package.yaml")"
test "$runtime_allowlist" = "$repo_b/docs/product/report.md"
mv "$tmp/card/analysis/package.md" "$tmp/card/analysis/package.selected.md"
touch "$tmp/card/analysis/package.md"
runtime_unselected="$(eaw_card_write_allowlist_entries "$tmp/card" "$tmp/analysis_package.yaml")"
test -z "$runtime_unselected"
mv "$tmp/card/analysis/package.selected.md" "$tmp/card/analysis/package.md"

# Explicit multi-root delivery works; absent, ambiguous, invalid and infra selections fail closed.
cat > "$tmp/card/analysis/multi.md" <<'EOF'
DELIVERY_TARGETS:
  - backend
  - database
EOF
multi="$(eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD '' "$tmp/card/analysis/multi.md" true)"
grep -Fxq "$repo_b/docs/product/report.md" <<< "$multi"
grep -Fxq "$repo_c/docs/product/report.md" <<< "$multi"
! eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD '' "$tmp/card/analysis/missing.md" true 2>/dev/null
cat > "$tmp/card/analysis/ambiguous.md" <<'EOF'
DELIVERY_TARGETS:
  - backend
DELIVERY_TARGETS:
  - database
EOF
! eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD '' "$tmp/card/analysis/ambiguous.md" true 2>/dev/null
cat > "$tmp/card/analysis/invalid.md" <<'EOF'
DELIVERY_TARGETS:
  - eaw
EOF
! eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD '' "$tmp/card/analysis/invalid.md" true 2>/dev/null
sed 's/backend/unknown/' "$tmp/card/analysis/package.md" > "$tmp/card/analysis/unknown.md"
! eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD '' "$tmp/card/analysis/unknown.md" true 2>/dev/null

# F: an explicit scope.lock narrows derived target paths.
printf '%s\n' "$repo_b/docs/product/report.md" > "$tmp/scope.lock.md"
narrowed="$(eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" "$tmp/scope.lock.md" CARD-1 '' "$tmp/card/analysis/package.md" true)"
test "$narrowed" = "$repo_b/docs/product/report.md"

# G: a write outside all targets is rejected even if a caller supplies it.
printf 'outside\n' > "$tmp/outside.md"
printf '%s\n' "$tmp/outside.md" > "$tmp/outside.allowlist"
! eaw_delivery_persist_file "$tmp/outside.md" "$tmp/outside.md" "$tmp/outside.allowlist" 2>/dev/null
cat > "$tmp/unsafe_delivery.yaml" <<'EOF'
phase:
  target_delivery_paths:
    - "docs/../outside.md"
EOF
! eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/unsafe_delivery.yaml" '' CARD '' "$tmp/card/analysis/package.md" true 2>/dev/null

# G: required delivery cannot pass phase completion until target artifact exists and is persisted.
mkdir -p "$repo_b/docs/product"
printf 'final report\n' > "$tmp/card/analysis/final-report.md"
eaw_delivery_persist_selected_file "$tmp/card/analysis/final-report.md" "$repo_b/docs/product/report.md" "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD-1 "$tmp/card/analysis/package.md"
cat > "$tmp/card/analysis/package.md" <<EOF
DELIVERY_TARGETS:
  - backend
ANALYSIS_STATUS: COMPLETE
COVERAGE_STATUS: COMPLETE
REQUIRED_AVAILABLE_NOT_EXAMINED: false
PERSISTENCE_STATUS: PERSISTED
PERSISTED_PATHS:
- $repo_b/docs/product/report.md
EOF
eaw_delivery_validate_package "$tmp/card/analysis/package.md" true "$allowlist"
cat > "$tmp/required_delivery_phase.yaml" <<'EOF'
phase:
  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - analysis/package.md
  delivery_contract: required
  package_artifact: analysis/package.md
  target_delivery_paths:
    - "docs/product/report.md"
EOF
eaw_phase_completion_evaluate TEST-CARD "$tmp/card" analysis_package "$tmp/required_delivery_phase.yaml"
sed 's/PERSISTENCE_STATUS: PERSISTED/PERSISTENCE_STATUS: NOT_AUTHORIZED/' "$tmp/card/analysis/package.md" > "$tmp/card/analysis/not_persisted.md"
! eaw_delivery_validate_package "$tmp/card/analysis/not_persisted.md" true 2>/dev/null
cp "$tmp/card/analysis/not_persisted.md" "$tmp/card/analysis/package.md"
! eaw_phase_completion_evaluate TEST-CARD "$tmp/card" analysis_package "$tmp/required_delivery_phase.yaml" 2>/dev/null
sed "s#- $repo_b/docs/product/report.md#- $tmp/outside.md#" "$tmp/card/analysis/not_persisted.md" > "$tmp/card/analysis/external_persisted.md"
sed -i 's/PERSISTENCE_STATUS: NOT_AUTHORIZED/PERSISTENCE_STATUS: PERSISTED/' "$tmp/card/analysis/external_persisted.md"
! eaw_delivery_validate_package "$tmp/card/analysis/external_persisted.md" true "$allowlist" 2>/dev/null

# J: Track Creator validation rejects required delivery with no derivable target path.
cat > "$tmp/impossible_delivery.yaml" <<'EOF'
phase:
  delivery_contract: required
  package_artifact: analysis/package.md
EOF
! eaw_validate_workflow_evidence_contract fixture analysis_package "$tmp/impossible_delivery.yaml" 2>/dev/null

# Prior controls: analysis coverage and persistence remain separate; unexamined required evidence blocks COMPLETE.
sed 's/REQUIRED_AVAILABLE_NOT_EXAMINED: false/REQUIRED_AVAILABLE_NOT_EXAMINED: true/' "$tmp/card/analysis/package.md" > "$tmp/card/analysis/incomplete_coverage.md"
! eaw_delivery_validate_package "$tmp/card/analysis/incomplete_coverage.md" true 2>/dev/null

echo "criterion A: PASS (three evidence roots, one explicitly selected delivery root)"
echo "criterion B: PASS (semantic product path, no universal card directory)"
echo "criterion C: PASS (same allowlist for two distinct card IDs)"
echo "criterion D: PASS (role=target boundary, infra and unsafe paths rejected)"
echo "criterion E: PASS (explicit scope.lock narrowing)"
echo "criterion F: PASS (analysis selection works without manual source authorization)"
echo "criterion G: PASS (required delivery completion follows verified persistence)"
echo "evidence_delivery_contract_smoke: PASS (A-G plus containment, traversal, symlink, coverage, Track Creator validation)"
