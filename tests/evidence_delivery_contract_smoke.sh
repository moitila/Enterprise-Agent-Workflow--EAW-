#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/scripts/lib/analysis_delivery_contract.sh"
source "$ROOT/scripts/lib/phase_completion.sh"
source "$ROOT/scripts/lib/workflow_validation.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Generic fixture universe: two target roots and one infra root.
repo_a="$tmp/frontend"
repo_b="$tmp/backend"
infra="$tmp/infra"
mkdir -p "$repo_a/docs" "$repo_b/src" "$infra/docs" "$tmp/card/analysis" "$tmp/card/investigations" "$tmp/destination"
printf 'frontend evidence\n' > "$repo_a/docs/source.md"
printf 'backend evidence with distinctive semantic content\n' > "$repo_b/src/source.md"
printf 'infra must not enter corpus\n' > "$infra/docs/internal.md"
cat > "$tmp/repos.conf" <<EOF
frontend|$repo_a|target
backend|$repo_b|target
eaw|$infra|infra
EOF
mkdir -p "$tmp/config"
cp "$tmp/repos.conf" "$tmp/config/repos.conf"
export EAW_CONFIG_DIR="$tmp/config"

# A/B: roots themselves authorize discovery; multiple roots are exposed, infra is excluded.
roots="$(eaw_delivery_target_roots "$tmp/repos.conf")"
grep -Fq $'frontend\t' <<< "$roots"
grep -Fq $'backend\t' <<< "$roots"
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
EOF
inventory="$(eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/10_source_manifest.yaml" "$tmp/repos.conf")"
grep -Fq "$repo_a/docs/source.md" <<< "$inventory"
grep -Fq "$repo_b/src/source.md" <<< "$inventory"
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
ln -s "$infra/docs/internal.md" "$repo_a/docs/escape.md"
sed 's#../outside.md#docs/escape.md#' "$tmp/card/analysis/bad.yaml" > "$tmp/card/analysis/symlink.yaml"
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/symlink.yaml" "$tmp/repos.conf" 2>/dev/null
sed "s#../outside.md#$tmp/external.md#" "$tmp/card/analysis/bad.yaml" > "$tmp/card/analysis/absolute.yaml"
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/absolute.yaml" "$tmp/repos.conf" 2>/dev/null

# E/H: target delivery paths derive from discovered target roots; infra is never included.
cat > "$tmp/analysis_package.yaml" <<'EOF'
phase:
  delivery_contract: required
  package_artifact: analysis/package.md
  target_delivery_paths:
    - "docs/eaw/{{CARD}}/report.md"
EOF
allowlist="$(eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" '' CARD-1 "$tmp/card/analysis/10_source_manifest.yaml")"
grep -Fxq "$repo_a/docs/eaw/CARD-1/report.md" <<< "$allowlist"
grep -Fxq "$repo_b/docs/eaw/CARD-1/report.md" <<< "$allowlist"
! grep -Fq "$infra/" <<< "$allowlist"

# F: an explicit scope.lock narrows derived target paths.
printf '%s\n' "$repo_b/docs/eaw/CARD-1/report.md" > "$tmp/scope.lock.md"
narrowed="$(eaw_delivery_derive_write_allowlist "$tmp/repos.conf" "$tmp/analysis_package.yaml" "$tmp/scope.lock.md" CARD-1 "$tmp/card/analysis/10_source_manifest.yaml")"
test "$narrowed" = "$repo_b/docs/eaw/CARD-1/report.md"

# G: a write outside all targets is rejected even if a caller supplies it.
printf 'outside\n' > "$tmp/outside.md"
printf '%s\n' "$tmp/outside.md" > "$tmp/outside.allowlist"
! eaw_delivery_persist_file "$tmp/outside.md" "$tmp/outside.md" "$tmp/outside.allowlist" 2>/dev/null

# I: required delivery cannot pass phase completion until target artifact exists and is persisted.
mkdir -p "$repo_a/docs/eaw/CARD-1"
printf 'final report\n' > "$tmp/card/analysis/final-report.md"
printf '%s\n' "$allowlist" > "$tmp/derived.allowlist"
eaw_delivery_persist_file "$tmp/card/analysis/final-report.md" "$repo_a/docs/eaw/CARD-1/report.md" "$tmp/derived.allowlist"
cat > "$tmp/card/analysis/package.md" <<EOF
ANALYSIS_STATUS: COMPLETE
COVERAGE_STATUS: COMPLETE
REQUIRED_AVAILABLE_NOT_EXAMINED: false
PERSISTENCE_STATUS: PERSISTED
PERSISTED_PATHS:
- $repo_a/docs/eaw/CARD-1/report.md
EOF
eaw_delivery_validate_package "$tmp/card/analysis/package.md" true
cat > "$tmp/required_delivery_phase.yaml" <<'EOF'
phase:
  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - analysis/package.md
  delivery_contract: required
  package_artifact: analysis/package.md
EOF
eaw_phase_completion_evaluate TEST-CARD "$tmp/card" analysis_package "$tmp/required_delivery_phase.yaml"
sed 's/PERSISTENCE_STATUS: PERSISTED/PERSISTENCE_STATUS: NOT_AUTHORIZED/' "$tmp/card/analysis/package.md" > "$tmp/card/analysis/not_persisted.md"
! eaw_delivery_validate_package "$tmp/card/analysis/not_persisted.md" true 2>/dev/null
cp "$tmp/card/analysis/not_persisted.md" "$tmp/card/analysis/package.md"
! eaw_phase_completion_evaluate TEST-CARD "$tmp/card" analysis_package "$tmp/required_delivery_phase.yaml" 2>/dev/null
cp "$tmp/card/analysis/package.md" "$tmp/card/analysis/not_persisted.md"
sed 's/PERSISTENCE_STATUS: NOT_AUTHORIZED/PERSISTENCE_STATUS: PERSISTED/' "$tmp/card/analysis/not_persisted.md" > "$tmp/card/analysis/package.md"
sed "s#- $repo_a/docs/eaw/CARD-1/report.md#- $tmp/outside.md#" "$tmp/card/analysis/package.md" > "$tmp/card/analysis/external_persisted.md"
! eaw_delivery_validate_package "$tmp/card/analysis/external_persisted.md" true 2>/dev/null

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

echo "evidence_delivery_contract_smoke: PASS (A-J)"
