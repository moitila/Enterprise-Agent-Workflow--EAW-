#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$ROOT_DIR/tests/fixtures/golden_structure"

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

main() {
  cd "$ROOT_DIR"

  local tmp_root workdir
  tmp_root="$(mktemp -d)"
  trap 'rm -rf "${tmp_root:-}"' EXIT
  workdir="$tmp_root/workdir"

  export EAW_WORKDIR="$workdir"

  ./scripts/eaw init --workdir "$workdir" --force >/dev/null
  cat >"$workdir/config/repos.conf" <<CFG
local-main|$ROOT_DIR|target
CFG

  local card_feature="940101"
  local card_bug="940102"
  local card_spike="940103"
  local card_pipeline="940104"

  local actual_feature="$tmp_root/feature.paths.txt"
  local actual_bug="$tmp_root/bug.paths.txt"
  local actual_spike="$tmp_root/spike.paths.txt"
  local actual_analyze="$tmp_root/analyze.paths.txt"

  ./scripts/eaw feature "$card_feature" "Golden feature" >/dev/null
  capture_paths "$workdir" "$card_feature" "$actual_feature"
  compare_fixture "$actual_feature" "$FIXTURES_DIR/feature.paths.txt"

  ./scripts/eaw bug "$card_bug" "Golden bug" >/dev/null
  capture_paths "$workdir" "$card_bug" "$actual_bug"
  compare_fixture "$actual_bug" "$FIXTURES_DIR/bug.paths.txt"

  ./scripts/eaw spike "$card_spike" "Golden spike" >/dev/null
  capture_paths "$workdir" "$card_spike" "$actual_spike"
  compare_fixture "$actual_spike" "$FIXTURES_DIR/spike.paths.txt"

  ./scripts/eaw feature "$card_pipeline" "Golden pipeline" >/dev/null

  ./scripts/eaw analyze "$card_pipeline" >/dev/null
  capture_paths "$workdir" "$card_pipeline" "$actual_analyze"
  compare_fixture "$actual_analyze" "$FIXTURES_DIR/analyze.paths.txt"

  assert_file_contains "$workdir/out/$card_pipeline/investigations/findings_agent_prompt.md" "=== EAW FINDINGS PROMPT"
  assert_file_contains "$workdir/out/$card_pipeline/investigations/hypotheses_agent_prompt.md" "=== EAW HYPOTHESES PROMPT"
  assert_file_contains "$workdir/out/$card_pipeline/investigations/planning_agent_prompt.md" "=== EAW PLANNING PROMPT"

  if [[ ! -f "$workdir/out/$card_feature/context/local-main/git-commit.txt" ]]; then
    echo "ERROR: missing context signature file: $workdir/out/$card_feature/context/local-main/git-commit.txt" >&2
    return 1
  fi

  echo "OK: golden structure check passed"
}

main "$@"
