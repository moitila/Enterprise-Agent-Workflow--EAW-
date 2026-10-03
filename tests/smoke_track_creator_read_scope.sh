#!/usr/bin/env bash
# Real parser/resolver/render regression; caller owns authorization of fixture root.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 2; }
fixture_root=''
negative=false
while (($#)); do
  case "$1" in
    --fixture-root) (($# >= 2)) || fail 'missing fixture root'; fixture_root="$2"; shift 2 ;;
    --negative-missing-source) negative=true; shift ;;
    *) fail "unknown argument: $1" ;;
  esac
done
[[ "$fixture_root" == /* && "$fixture_root" != / && "$fixture_root" != */ && "$fixture_root" != *'/../'* && "$fixture_root" != */.. ]] || fail 'explicit absolute non-root --fixture-root required'
[[ ! -e "$fixture_root" && ! -L "$fixture_root" ]] || fail 'fixture destination already exists'
parent="$(cd "$(dirname "$fixture_root")" && pwd -P)" || fail 'fixture parent must exist'
fixture_root="$parent/$(basename "$fixture_root")"
[[ "$fixture_root" != "$parent" && "$fixture_root" != / ]] || fail 'unsafe fixture root'
owned=false
cleanup() {
  if $owned; then
    [[ "$fixture_root" == "$parent/"* && "$fixture_root" != "$parent" ]] || return 2
    rm -rf -- "$fixture_root"
  fi
}
trap cleanup EXIT
mkdir -- "$fixture_root"
owned=true
# Every output is a descendant of this newly created, exclusive directory.
export EAW_ROOT_DIR="$REPO_ROOT"
export EAW_WORKDIR="$fixture_root/workspace"
export EAW_OUT_DIR="$EAW_WORKDIR/out"
export EAW_CONFIG_DIR="$EAW_WORKDIR/config"
export EAW_TEMPLATES_DIR="$EAW_WORKDIR/templates"
export REPOS_CONF="$EAW_CONFIG_DIR/repos.conf"
export EAW_CONF="$EAW_CONFIG_DIR/eaw.conf"
card=READ-SCOPE-FIXTURE
card_dir="$EAW_OUT_DIR/$card"
mkdir -p "$EAW_CONFIG_DIR" "$card_dir/investigations" "$card_dir/implementation" "$card_dir/prompts" "$card_dir/context/dynamic"
printf 'eaw|%s|target\n' "$REPO_ROOT" >"$REPOS_CONF"
printf 'ci_feedback_enabled=true\n' >"$EAW_CONF"
printf '## Repositorio principal de onboarding\neaw\n' >"$card_dir/investigations/00_intake.md"
printf 'Track design fixture\n' >"$card_dir/investigations/10_track_design.md"
printf 'Prompt design fixture\n' >"$card_dir/investigations/20_prompt_design.md"
printf 'Existing dynamic context fixture\n' >"$card_dir/context/dynamic/00_scope_manifest.md"
dynamic_before="$(cksum "$card_dir/context/dynamic/00_scope_manifest.md")"
printf '## In Scope\n## Out of Scope\n## Allowlist de Escrita\n- %s/tracks/fixture/track.yaml\n' "$REPO_ROOT" >"$card_dir/implementation/00_scope.lock.md"
source "$REPO_ROOT/scripts/lib.sh"
source "$REPO_ROOT/scripts/eaw_core.sh"
source "$REPO_ROOT/scripts/lib/analysis_delivery_contract.sh"
source "$REPO_ROOT/scripts/commands/eaw_commands.sh"
phase_file="$fixture_root/phase.yaml"
cp "$REPO_ROOT/tracks/track_creator/phases/implementation_executor.yaml" "$phase_file"
export EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE="$phase_file"
metadata="$(prompt_resolve_active_metadata track_creator implementation_executor)" || fail 'ACTIVE resolution failed'
grep -qx 'active=v3' <<<"$metadata" || fail 'effective ACTIVE is not v3'
template="$(sed -n 's/^md_file=//p' <<<"$metadata")"
[[ -f "$template" ]] || fail 'selected template missing'
expected=(
  "$REPO_ROOT/tracks/track_creator"
  "$card_dir/implementation"
  "$card_dir/investigations/00_intake.md"
  "$card_dir/investigations/10_track_design.md"
  "$card_dir/investigations/20_prompt_design.md"
  "$REPO_ROOT/docs/WORKFLOW_YAML_CONTRACT.md"
  "$REPO_ROOT/scripts/commands/eaw_commands.sh"
  "$REPO_ROOT/scripts/lib/analysis_delivery_contract.sh"
  "$REPO_ROOT/tracks/verification_validation_analysis/phases/source_inventory.yaml"
  "$REPO_ROOT/tracks/verification_validation_analysis/phases/analysis_package.yaml"
)
allowlist="$(eaw_scope_lock_allowlist_paths "$card_dir/implementation/00_scope.lock.md")"
[[ -n "$allowlist" ]] || fail 'fixture scope lock did not parse'
render() {
  local output="$1" runtime_environment
  runtime_environment="$(eaw_runtime_environment_block "$card" "$card_dir" track_creator implementation_executor "$allowlist" '- none' "- eaw => $REPO_ROOT" "$phase_file")" || fail 'runtime environment failed'
  eaw_render_phase_prompt_template "$template" "$output" IMPLEMENTATION_EXECUTOR "$card" track_creator "$card_dir" "- eaw => $REPO_ROOT" '(none)' '- none' track_creator implementation_executor "$allowlist" '- none' "$runtime_environment" '' || fail 'render failed'
  [[ -s "$(dirname "$output")/ci_feedback_prompt.md" ]] || fail 'CI sibling absent'
}
section() {
  awk -v heading="$2" '$0==heading {inside=1; next} inside && /^[[:space:]]*$/ {exit} inside {print}' "$1"
}
cp "$phase_file" "$fixture_root/phase.after.yaml"
git -C "$REPO_ROOT" show HEAD:tracks/track_creator/phases/implementation_executor.yaml >"$phase_file" || fail 'baseline YAML unavailable'
dynamic_contract_before="$(eaw_yaml_phase_dynamic_context_template "$phase_file")"
active_template="$template"
template="$REPO_ROOT/templates/prompts/track_creator/implementation_executor/prompt_v2.md"
render "$card_dir/prompts/before.md"
section "$card_dir/prompts/before.md" WRITE_ALLOWLIST: >"$fixture_root/allowlist.before"
cp "$fixture_root/phase.after.yaml" "$phase_file"
template="$active_template"
if $negative; then
  sed -i '\|{{CARD_DIR}}/investigations/10_track_design.md|d' "$phase_file"
fi
render "$card_dir/prompts/after.md"
section "$card_dir/prompts/after.md" WRITE_ALLOWLIST: >"$fixture_root/allowlist.after"
cmp "$fixture_root/allowlist.before" "$fixture_root/allowlist.after" || fail 'WRITE_ALLOWLIST changed'
[[ "$dynamic_before" == "$(cksum "$card_dir/context/dynamic/00_scope_manifest.md")" ]] || fail 'dynamic context persistence changed'
[[ "$dynamic_contract_before" == "$(eaw_yaml_phase_dynamic_context_template "$phase_file")" && -z "$dynamic_contract_before" ]] || fail 'dynamic context contract changed'
printf 'PASS: effective ACTIVE=v3; WRITE_ALLOWLIST unchanged from HEAD YAML/v2 baseline\n'
cat "$fixture_root/allowlist.after"
printf 'PASS: dynamic_context_template empty; context/dynamic persisted unchanged\n'
resolved=''
raw="$(eaw_yaml_phase_read_sources "$phase_file")" || fail 'read_sources parser failed'
while IFS= read -r item; do
  [[ -n "$item" ]] || continue
  path="$(CARD_DIR="$card_dir" RUNTIME_ROOT="$REPO_ROOT" OUT_DIR="$EAW_OUT_DIR" eaw_resolve_read_source_item "$item")" || fail "resolver failed: $item"
  resolved+="$path"$'\n'
done <<<"$raw"
read_sources="$(section "$card_dir/prompts/after.md" READ_SOURCES:)"
read_scope="$(section "$card_dir/prompts/after.md" READ_SCOPE)"
missing=()
for path in "${expected[@]}"; do
  if ! grep -Fxq "$path" <<<"$resolved" || ! grep -Fxq "$path" <<<"$read_sources"; then
    missing+=("$path")
    printf 'MISSING_SOURCE: %s\n' "$path"
  fi
  # The original implementation directory has a trailing slash in READ_SCOPE.
  grep -Fxq -- "- $path" <<<"$read_scope" || grep -Fxq -- "- $path/" <<<"$read_scope" || fail "READ_SCOPE missing: $path"
done
if $negative; then
  [[ ${#missing[@]} -eq 1 && "${missing[0]}" == "$card_dir/investigations/10_track_design.md" ]] || fail 'negative case did not identify the selected missing source'
  printf 'EXPECTED_NEGATIVE: missing source detected after successful real render\n'
  exit 1
fi
[[ ${#missing[@]} -eq 0 ]] || fail 'unexpected missing sources'
[[ "$(printf '%s' "$resolved" | sed '/^$/d' | wc -l)" -eq 10 ]] || fail 'read_sources is not the closed ten-source list'
printf 'PASS: all ten sources resolved and covered by rendered READ_SOURCES and READ_SCOPE\n%s\n' "$read_sources"
