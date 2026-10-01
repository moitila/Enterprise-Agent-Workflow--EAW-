#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "$ROOT/scripts/lib/analysis_delivery_contract.sh"
source "$ROOT/scripts/lib/phase_completion.sh"
source "$ROOT/scripts/lib/workflow_validation.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/target"
mkdir -p "$repo/docs" "$tmp/card/analysis" "$tmp/destination"
cp "$ROOT/tests/fixtures/evidence_delivery_contract/authorized_target/source.md" "$repo/docs/source.md"
cp "$ROOT/tests/fixtures/evidence_delivery_contract/unauthorized_target/source.md" "$repo/docs/private.md"
printf 'fixture|%s|target\n' "$repo" > "$tmp/repos.conf"
mkdir -p "$tmp/config"
cp "$tmp/repos.conf" "$tmp/config/repos.conf"
export EAW_CONFIG_DIR="$tmp/config"
cat > "$tmp/source_inventory.yaml" <<'EOF'
phase:
  evidence_sources:
    - repository: fixture
      paths:
        - docs/source.md
      required: true
EOF
test "$(eaw_delivery_phase_sources "$tmp/source_inventory.yaml" | cut -f1-3)" = $'fixture\tdocs/source.md\ttrue'
eaw_delivery_validate_evidence_declaration "$tmp/source_inventory.yaml" "$tmp/repos.conf"
eaw_validate_workflow_evidence_contract fixture source_inventory "$tmp/source_inventory.yaml"
resolved="$(eaw_delivery_resolve_phase_sources "$tmp/source_inventory.yaml" "$tmp/repos.conf")"
grep -Fq "$repo/docs/source.md" <<< "$resolved"
! grep -Fq "$repo/docs/private.md" <<< "$resolved"

# The inventory is a data record, not independent authority: only required,
# available rows from the explicitly selected target can be propagated.
cat > "$tmp/card/analysis/10_source_manifest.yaml" <<EOF
sources:
  - id: S1
    repository: fixture
    path: docs/source.md
    required: true
    availability: available
  - id: S2
    repository: fixture
    path: docs/private.md
    required: true
    availability: available
  - id: S3
    repository: fixture
    path: docs/missing.md
    required: true
    availability: unavailable
EOF
cat > "$tmp/card/analysis/01_analysis_scope.yaml" <<'EOF'
authorized_sources:
  - repo_key: fixture
    paths:
      - docs/source.md
    required: true
EOF
ai_selector="$(awk '/^  evidence_sources_from:/ {print $2; exit}' "$ROOT/tracks/ai_pipeline_analysis/phases/source_inventory.yaml")"
security_selector="$(awk '/^  evidence_sources_from:/ {print $2; exit}' "$ROOT/tracks/security_privacy_analysis/phases/source_inventory.yaml")"
test "$ai_selector" = "analysis/01_analysis_scope.yaml"
test "$security_selector" = "$ai_selector"
inventory="$(eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/10_source_manifest.yaml" "$tmp/repos.conf" "$tmp/card/analysis/01_analysis_scope.yaml")"
grep -Fq "$repo/docs/source.md" <<< "$inventory"
! grep -Fq "$repo/docs/private.md" <<< "$inventory"
! grep -Fq "$repo/docs/missing.md" <<< "$inventory"

# Both tracks consume the same per-card selectors. A present target file is
# exposed only when selected; absent/empty selector artifacts fail closed.
for selector in "$ai_selector" "$security_selector"; do
	selected="$(eaw_delivery_resolve_scope_sources "$tmp/card/$selector" "$tmp/repos.conf")"
	grep -Fq "$repo/docs/source.md" <<< "$selected"
	! grep -Fq "$repo/docs/private.md" <<< "$selected"
done
! eaw_delivery_resolve_scope_sources "$tmp/card/analysis/missing_scope.yaml" "$tmp/repos.conf"
printf 'authorized_sources: []\n' > "$tmp/card/analysis/empty_scope.yaml"
! eaw_delivery_resolve_scope_sources "$tmp/card/analysis/empty_scope.yaml" "$tmp/repos.conf"
sed '/    required: true/d' "$tmp/card/analysis/01_analysis_scope.yaml" > "$tmp/card/analysis/missing_required_scope.yaml"
! eaw_delivery_resolve_scope_sources "$tmp/card/analysis/missing_required_scope.yaml" "$tmp/repos.conf"

# Unknown repositories, traversal, and an available-but-missing inventory path fail closed.
sed 's/repository: fixture/repository: unknown/' "$tmp/source_inventory.yaml" > "$tmp/invalid.yaml"
! eaw_delivery_validate_evidence_declaration "$tmp/invalid.yaml" "$tmp/repos.conf"
! eaw_validate_workflow_evidence_contract fixture source_inventory "$tmp/invalid.yaml"
sed 's#docs/source.md#../outside.md#' "$tmp/source_inventory.yaml" > "$tmp/traversal.yaml"
! eaw_delivery_validate_evidence_declaration "$tmp/traversal.yaml" "$tmp/repos.conf"
! eaw_validate_workflow_evidence_contract fixture source_inventory "$tmp/traversal.yaml"
sed 's#docs/source.md#docs/missing.md#' "$tmp/card/analysis/10_source_manifest.yaml" > "$tmp/card/analysis/bad.yaml"
! eaw_delivery_resolve_inventory_sources "$tmp/card/analysis/bad.yaml" "$tmp/repos.conf"

# Coverage and persistence are separate; complete cannot hide required evidence gaps.
cat > "$tmp/card/package.md" <<'EOF'
ANALYSIS_STATUS: COMPLETE
COVERAGE_STATUS: COMPLETE
REQUIRED_AVAILABLE_NOT_EXAMINED: false
PERSISTENCE_STATUS: NOT_AUTHORIZED
PERSISTED_PATHS: none
EOF
eaw_delivery_validate_package "$tmp/card/package.md"
cat > "$tmp/phase.yaml" <<'EOF'
phase:
  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - analysis/package.md
  delivery_contract: required
  package_artifact: analysis/package.md
EOF
cp "$tmp/card/package.md" "$tmp/card/analysis/package.md"
eaw_phase_completion_evaluate TEST-CARD "$tmp/card" analysis_package "$tmp/phase.yaml"
sed 's/REQUIRED_AVAILABLE_NOT_EXAMINED: false/REQUIRED_AVAILABLE_NOT_EXAMINED: true/' "$tmp/card/package.md" > "$tmp/card/bad_package.md"
! eaw_delivery_validate_package "$tmp/card/bad_package.md"
cp "$tmp/card/bad_package.md" "$tmp/card/analysis/package.md"
! eaw_phase_completion_evaluate TEST-CARD "$tmp/card" analysis_package "$tmp/phase.yaml"
sed 's/PERSISTENCE_STATUS: NOT_AUTHORIZED/PERSISTENCE_STATUS: PERSISTED/' "$tmp/card/package.md" > "$tmp/card/bad_persistence.md"
! eaw_delivery_validate_package "$tmp/card/bad_persistence.md"

# Authorized persistence uses exact paths; a nearby path is rejected.
printf '%s\n' "$tmp/destination/package.md" > "$tmp/allowlist"
eaw_delivery_persist_file "$tmp/card/package.md" "$tmp/destination/package.md" "$tmp/allowlist"
cmp "$tmp/card/package.md" "$tmp/destination/package.md"
! eaw_delivery_persist_file "$tmp/card/package.md" "$tmp/destination/other.md" "$tmp/allowlist"

echo "evidence_delivery_contract_smoke: PASS"
