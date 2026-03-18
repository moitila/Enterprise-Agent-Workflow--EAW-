#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_ROOT="$(mktemp -d)"

export EAW_WORKDIR="$WORK_ROOT/.eaw"

"$REPO_ROOT/scripts/eaw" init --workdir "$EAW_WORKDIR" >/dev/null

default_intake_dir="$EAW_WORKDIR/templates/prompts/default/intake"
test -f "$default_intake_dir/prompt_v1.md"
test -f "$default_intake_dir/prompt_v1.meta"
test -f "$default_intake_dir/ACTIVE"
[[ -n "$(tr -d '[:space:]' <"$default_intake_dir/ACTIVE")" ]]

md_file="$default_intake_dir/prompt_v1.md"
md_backup="$default_intake_dir/prompt_v1.md.bak"
meta_file="$default_intake_dir/prompt_v1.meta"
meta_backup="$default_intake_dir/prompt_v1.meta.bak"
restore_prompt_files() {
	if [[ -f "$md_backup" ]]; then
		mv "$md_backup" "$md_file"
	fi
	if [[ -f "$meta_backup" ]]; then
		mv "$meta_backup" "$meta_file"
	fi
}
cleanup() {
	restore_prompt_files
	rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

"$REPO_ROOT/scripts/eaw" validate-prompt default intake v1 >/dev/null
"$REPO_ROOT/scripts/eaw" validate >/dev/null
"$REPO_ROOT/scripts/eaw" prompt validate >/dev/null

"$REPO_ROOT/scripts/eaw" card 500 --track standard "Prompt core smoke" >/dev/null
"$REPO_ROOT/scripts/eaw" intake 500 --round=1 >/dev/null

test -f "$EAW_WORKDIR/out/500/prompts/intake.md"
provenance_file="$EAW_WORKDIR/out/500/provenance/prompts_used.yaml"
test -f "$provenance_file"
grep -F "phase: intake" "$provenance_file" >/dev/null
grep -Eq "prompt_used: intake_v[0-9]+" "$provenance_file"

test -f "$REPO_ROOT/tracks/feature/phases/ingest.yaml"
grep -F "initial_phase: ingest" "$REPO_ROOT/tracks/feature/track.yaml" >/dev/null

"$REPO_ROOT/scripts/eaw" card 501 --track feature "Ingest phase smoke" >/dev/null
test -d "$EAW_WORKDIR/out/501/ingest"
test -f "$EAW_WORKDIR/out/501/ingest/sources.md"
test -d "$EAW_WORKDIR/out/501/intake"
test -d "$EAW_WORKDIR/out/501/investigations"
# feature ingest smoke must exercise `eaw next`
"$REPO_ROOT/scripts/eaw" next 501 >/dev/null
feature_prompt="$EAW_WORKDIR/out/501/prompts/ingest.md"
test -f "$feature_prompt"
grep -F 'INGEST_DIR=`out/<CARD>/ingest/`' "$feature_prompt" >/dev/null
grep -F "Ler \`$EAW_WORKDIR/out/501/ingest\` quando existir." "$feature_prompt" >/dev/null
grep -F "Ler \`$EAW_WORKDIR/out/501/intake\` apenas como fallback compativel quando \`$EAW_WORKDIR/out/501/ingest\` nao existir." "$feature_prompt" >/dev/null

log_missing_md="$WORK_ROOT/validate_missing_md.log"
mv "$md_file" "$md_backup"
if "$REPO_ROOT/scripts/eaw" validate >"$log_missing_md" 2>&1; then
	echo "expected validate to fail when ACTIVE markdown is missing" >&2
	exit 1
fi
grep -F "phase 'intake'" "$log_missing_md" >/dev/null
grep -F "version 'v1'" "$log_missing_md" >/dev/null
grep -F "$md_file" "$log_missing_md" >/dev/null
mv "$md_backup" "$md_file"

log_missing_meta="$WORK_ROOT/validate_missing_meta.log"
mv "$meta_file" "$meta_backup"
if "$REPO_ROOT/scripts/eaw" validate >"$log_missing_meta" 2>&1; then
	echo "expected validate to fail when ACTIVE metadata is missing" >&2
	exit 1
fi
grep -F "phase 'intake'" "$log_missing_meta" >/dev/null
grep -F "version 'v1'" "$log_missing_meta" >/dev/null
grep -F "$meta_file" "$log_missing_meta" >/dev/null
mv "$meta_backup" "$meta_file"

"$REPO_ROOT/scripts/eaw" validate >/dev/null
"$REPO_ROOT/scripts/eaw" prompt validate >/dev/null

printf "smoke prompt core OK\n"
