#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$ROOT_DIR/tests/fixtures/golden_structure"
TARGET_FIXTURE_DIR="$ROOT_DIR/tests/fixtures/golden_repo_target"

capture_paths() {
  local workdir="$1"
  local card="$2"
  local out_file="$3"
  find "$workdir/out/$card" -type f | sed "s|$workdir/||" | LC_ALL=C sort >"$out_file"
}

compare_fixture() {
  local actual="$1"
  local expected="$2"
  if ! diff -u "$expected" "$actual"; then
    echo "ERROR: golden structure mismatch for $(basename "$expected")" >&2
    return 1
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -Fq -- "$pattern" "$file"; then
    echo "ERROR: missing expected content in $file: $pattern" >&2
    return 1
  fi
}

assert_prompt_contract() {
  local file="$1"
  local required_sections=(
    "RUNTIME_ENVIRONMENT"
    "ROLE"
    "OBJECTIVE"
    "INPUT"
    "OUTPUT"
    "READ_SCOPE"
    "WRITE_SCOPE"
    "FORBIDDEN"
    "FAIL_CONDITIONS"
  )
  local section
  for section in "${required_sections[@]}"; do
    assert_file_contains "$file" "$section"
  done
  if [[ "$(sed -n '1p' "$file")" != "RUNTIME_ENVIRONMENT" ]]; then
    echo "ERROR: prompt must start with RUNTIME_ENVIRONMENT in $file" >&2
    return 1
  fi
  assert_file_contains "$file" "CARD_ID:"
  assert_file_contains "$file" "TRACK_ID:"
  assert_file_contains "$file" "STEP_ID:"
  assert_file_contains "$file" "WORKDIR:"
  assert_file_contains "$file" "CARD_DIR:"
  assert_file_contains "$file" "OUT_DIR:"
  assert_file_contains "$file" "TARGET_REPOSITORIES:"
  assert_file_contains "$file" "WRITE_ALLOWLIST:"
  assert_file_contains "$file" "CRITICAL_PATHS:"
}

main() {
  cd "$ROOT_DIR"

  local tmp_root workdir target_repo
  tmp_root="$(mktemp -d)"
  trap 'rm -rf "${tmp_root:-}"' EXIT
  workdir="$tmp_root/workdir"
  target_repo="$tmp_root/target_repo"

  mkdir -p "$target_repo"
  cp -R "$TARGET_FIXTURE_DIR/." "$target_repo/"
  (
    cd "$target_repo"
    git init -q
    git config user.name "golden-test"
    git config user.email "golden-test@example.com"
    git add .
    git commit -q -m "seed fixture"
  )

  export EAW_WORKDIR="$workdir"

  ./scripts/eaw init --workdir "$workdir" --force >/dev/null
  cat >"$workdir/config/repos.conf" <<CFG
local-main|$target_repo|target
CFG

  local card_feature="940101"
  local card_bug="940102"
  local card_spike="940103"
  local card_pipeline="940104"

  local actual_feature="$tmp_root/feature.paths.txt"
  local actual_bug="$tmp_root/bug.paths.txt"
  local actual_spike="$tmp_root/spike.paths.txt"
  local actual_analyze="$tmp_root/analyze.paths.txt"

  ./scripts/eaw card "$card_feature" --track feature "Golden feature" >/dev/null
  capture_paths "$workdir" "$card_feature" "$actual_feature"
  compare_fixture "$actual_feature" "$FIXTURES_DIR/feature.paths.txt"

  ./scripts/eaw card "$card_bug" --track bug "Golden bug" >/dev/null
  capture_paths "$workdir" "$card_bug" "$actual_bug"
  compare_fixture "$actual_bug" "$FIXTURES_DIR/bug.paths.txt"

  ./scripts/eaw card "$card_spike" --track spike "Golden spike" >/dev/null
  capture_paths "$workdir" "$card_spike" "$actual_spike"
  compare_fixture "$actual_spike" "$FIXTURES_DIR/spike.paths.txt"

  ./scripts/eaw card "$card_pipeline" --track feature "Golden pipeline" >/dev/null

  ./scripts/eaw analyze "$card_pipeline" >/dev/null
  capture_paths "$workdir" "$card_pipeline" "$actual_analyze"
  compare_fixture "$actual_analyze" "$FIXTURES_DIR/analyze.paths.txt"

  assert_prompt_contract "$workdir/out/$card_pipeline/investigations/findings_agent_prompt.md"
  assert_prompt_contract "$workdir/out/$card_pipeline/investigations/hypotheses_agent_prompt.md"
  assert_prompt_contract "$workdir/out/$card_pipeline/investigations/planning_agent_prompt.md"

  if [[ ! -f "$workdir/out/$card_feature/context/local-main/git-commit.txt" ]]; then
    echo "ERROR: missing context signature file: $workdir/out/$card_feature/context/local-main/git-commit.txt" >&2
    return 1
  fi

  echo "OK: golden structure check passed"
}

main "$@"
