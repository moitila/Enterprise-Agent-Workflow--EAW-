#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

export EAW_WORKDIR="$WORK_ROOT/.eaw"

"$REPO_ROOT/scripts/eaw" init --workdir "$EAW_WORKDIR" >/dev/null

default_intake_dir="$EAW_WORKDIR/templates/prompts/default/intake"
test -f "$default_intake_dir/prompt_v1.md"
test -f "$default_intake_dir/prompt_v1.meta"
test -f "$default_intake_dir/ACTIVE"
[[ -n "$(tr -d '[:space:]' <"$default_intake_dir/ACTIVE")" ]]

"$REPO_ROOT/scripts/eaw" validate-prompt default intake v1 >/dev/null

"$REPO_ROOT/scripts/eaw" feature 500 "Prompt core smoke" >/dev/null
"$REPO_ROOT/scripts/eaw" intake 500 --round=1 >/dev/null

test -f "$EAW_WORKDIR/out/500/investigations/intake_agent_prompt.round_1.md"
provenance_file="$EAW_WORKDIR/out/500/provenance/prompts_used.yaml"
test -f "$provenance_file"
grep -F "phase: intake" "$provenance_file" >/dev/null
grep -Eq "prompt_used: intake_v[0-9]+" "$provenance_file"

printf "smoke prompt core OK\n"
