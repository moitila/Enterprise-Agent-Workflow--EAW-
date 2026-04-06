#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf "test suite failed: %s\n" "$1" >&2
	exit 1
}

prepare_feature_planning_with_onboarding() {
	local workdir="$1"
	local phase_file="$workdir/tracks/feature/phases/planning.yaml"
	python3 - "$phase_file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
needle = "  prompt:\n    active: 3\n    path: templates/prompts/feature/planning/prompt_v<active>.md\n"
replacement = needle + "\n  context:\n    onboarding_template: workspace-onboarding\n"
if needle not in text:
    raise SystemExit("planning prompt block not found")
path.write_text(text.replace(needle, replacement, 1))
PY
}

run_onboarding_runtime_suite() {
	local tmp_root workdir card provenance_file

	tmp_root="$(mktemp -d)"
	trap 'rm -rf "$tmp_root"' RETURN

	workdir="$tmp_root/workdir"
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
	printf 'local-main|/home/user/dev/EAW-dev|target\n' >"$workdir/config/repos.conf"
	prepare_feature_planning_with_onboarding "$workdir"

	mkdir -p "$workdir/context_sources/onboarding/local-main/docs"
	printf 'alpha\n' >"$workdir/context_sources/onboarding/local-main/README.md"
	printf 'beta\n' >"$workdir/context_sources/onboarding/local-main/docs/info.txt"
	printf 'ignored\n' >"$workdir/context_sources/onboarding/local-main/image.bin"

	card="585ACC"
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "onboarding acceptance" >/dev/null
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" >/dev/null
	test -f "$workdir/out/$card/context/onboarding/README.md" || fail "missing onboarding README materialization"
	test -f "$workdir/out/$card/context/onboarding/docs/info.txt" || fail "missing onboarding nested materialization"
	grep -Fqx 'alpha' "$workdir/out/$card/context/onboarding/README.md" || fail "materialized README content changed"
	test ! -e "$workdir/out/$card/context/onboarding/image.bin" || fail "unsupported onboarding file should not materialize"
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"
	test -f "$provenance_file" || fail "missing onboarding provenance for materialized source"
	grep -Fq 'context_sources/onboarding/local-main' "$provenance_file" || fail "provenance missing source root"
	grep -Fq 'README.md' "$provenance_file" || fail "provenance missing considered file"
	grep -Fq 'max_files_onboarding' "$provenance_file" || fail "provenance missing max_files_onboarding"
	grep -Fq 'max_bytes_total_onboarding' "$provenance_file" || fail "provenance missing max_bytes_total_onboarding"

	rm -rf "$workdir/context_sources/onboarding/local-main"
	card="585ABS"
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "onboarding absent" >/dev/null
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" >/dev/null
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"
	test -f "$provenance_file" || fail "missing provenance when onboarding source is absent"
	grep -Fq 'source_status: absent' "$provenance_file" || fail "absent onboarding source should be recorded"

	mkdir -p "$workdir/context_sources/onboarding/local-main"
	printf 'stale\n' >"$workdir/context_sources/onboarding/local-main/a.md"
	card="585IDEMP"
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "onboarding idempotence" >/dev/null
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" >/dev/null
	printf 'residue\n' >"$workdir/out/$card/context/onboarding/obsolete.txt"
	rm "$workdir/context_sources/onboarding/local-main/a.md"
	printf 'fresh\n' >"$workdir/context_sources/onboarding/local-main/b.md"
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" >/dev/null
	test ! -e "$workdir/out/$card/context/onboarding/obsolete.txt" || fail "stale onboarding artifact should be removed"
	test ! -e "$workdir/out/$card/context/onboarding/a.md" || fail "removed source file should not persist after rerun"
	test -f "$workdir/out/$card/context/onboarding/b.md" || fail "new source file should materialize after rerun"

	rm -rf "$workdir/context_sources/onboarding/local-main"
	mkdir -p "$workdir/context_sources/onboarding/local-main"
	for n in $(seq 1 12); do
		printf 'ordered-%02d\n' "$n" >"$workdir/context_sources/onboarding/local-main/file_$(printf '%02d' "$n").md"
	done
	python3 - "$workdir/context_sources/onboarding/local-main/large.json" <<'PY'
from pathlib import Path
import json
import sys

payload = {"blob": "x" * 205000}
Path(sys.argv[1]).write_text(json.dumps(payload))
PY
	card="585LIMIT"
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "onboarding limits" >/dev/null
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" analyze "$card" >/dev/null
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"
	test -f "$workdir/out/$card/context/onboarding/file_01.md" || fail "first ordered onboarding file missing"
	test -f "$workdir/out/$card/context/onboarding/file_10.md" || fail "tenth ordered onboarding file missing"
	test ! -e "$workdir/out/$card/context/onboarding/file_11.md" || fail "max_files_onboarding should truncate materialization"
	grep -Fq 'file_11.md | reason=max_files_onboarding' "$provenance_file" || fail "max_files truncation should be recorded"
	grep -Fq 'large.json | reason=max_bytes_per_file_onboarding' "$provenance_file" || fail "per-file limit should be recorded"
}

printf "[test] smoke scope\n"
bash "$REPO_ROOT/tests/smoke/smoke_baseline.sh"

printf "[test] integration scope\n"
bash "$REPO_ROOT/tests/integration/integration_suite.sh"

printf "[test] lifecycle scope\n"
bash "$REPO_ROOT/tests/lifecycle/lifecycle_suite.sh"

printf "[test] golden scope\n"
bash "$REPO_ROOT/tests/golden/golden_suite.sh"

printf "[test] onboarding runtime scope\n"
run_onboarding_runtime_suite
