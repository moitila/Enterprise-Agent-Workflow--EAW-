#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
	printf "smoke_baseline failed: %s\n" "$1" >&2
	exit 1
}

init_workdir() {
	local workdir="$1"
	"$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
}

create_repo() {
	local repo_dir="$1"
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "baseline@example.com"
	git -C "$repo_dir" config user.name "baseline"
}

prime_feature_card_for_findings() {
	local workdir="$1"
	local card="$2"
	local ingest_content="$3"

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "baseline smoke" >/dev/null
	printf "%s\n" "$ingest_content" >"$workdir/out/$card/ingest/sources.md"
	cat >"$workdir/out/$card/state_card_feature.yaml" <<EOF
card_state:
  track_id: feature
  previous_phase: ingest
  current_phase: findings
  completed_phases:
    - ingest
  phase_status: RUN
  phase_started_at: 2026-03-29T00:00:00Z
  phase_completed: false
  phase_completed_at: null
EOF
}

write_repos_conf() {
	local workdir="$1"
	local repo_dir="$2"
	cat >"$workdir/config/repos.conf" <<EOF
baseline-target|$repo_dir|target
EOF
}

run_signal_scenario() {
	local tmpdir repo_dir workdir card dynamic_dir
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN
	repo_dir="$tmpdir/repo-signal"
	workdir="$tmpdir/workdir-signal"
	card="583SIGNAL"

	create_repo "$repo_dir"
	mkdir -p "$repo_dir/src" "$repo_dir/tests"
	cat >"$repo_dir/src/app.sh" <<'EOF'
#!/usr/bin/env bash
build_widget_token() {
	printf "widget\n"
}
EOF
	cat >"$repo_dir/tests/app_test.sh" <<'EOF'
#!/usr/bin/env bash
build_widget_token() {
	printf "test\n"
}
EOF
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "baseline fixtures"
	printf "\n# delta\n" >>"$repo_dir/src/app.sh"

	init_workdir "$workdir"
	write_repos_conf "$workdir" "$repo_dir"
	prime_feature_card_for_findings "$workdir" "$card" "Use src/app.sh and build_widget_token to inspect the baseline."

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	dynamic_dir="$workdir/out/$card/context/dynamic"
	[[ -f "$dynamic_dir/00_scope_manifest.md" ]] || fail "missing manifest for signal scenario"
	[[ -f "$dynamic_dir/20_candidate_files.txt" ]] || fail "missing candidate file for signal scenario"
	[[ -f "$dynamic_dir/30_target_snippets.md" ]] || fail "missing snippets file for signal scenario"
	grep -Fq "deterministic_baseline_v1" "$dynamic_dir/00_scope_manifest.md" || fail "manifest missing baseline identifier"
	grep -Fq "max_hits_por_token" "$dynamic_dir/00_scope_manifest.md" || fail "manifest missing runtime limits"
	grep -Fq "path=src/app.sh" "$dynamic_dir/20_candidate_files.txt" || fail "signal scenario missing app candidate"
	grep -Fq "src/app.sh" "$dynamic_dir/30_target_snippets.md" || fail "signal scenario missing snippet for app.sh"
	test ! -f "$dynamic_dir/40_warnings.md" || fail "signal scenario should not emit warnings"
}

run_empty_scenario() {
	local tmpdir repo_dir workdir card dynamic_dir
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN
	repo_dir="$tmpdir/repo-empty"
	workdir="$tmpdir/workdir-empty"
	card="583EMPTY"

	create_repo "$repo_dir"
	printf "plain readme\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add README.md
	git -C "$repo_dir" commit -q -m "baseline empty"

	init_workdir "$workdir"
	write_repos_conf "$workdir" "$repo_dir"
	prime_feature_card_for_findings "$workdir" "$card" "apenas contexto geral sem caminhos tecnicos relevantes"

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	dynamic_dir="$workdir/out/$card/context/dynamic"
	[[ -f "$dynamic_dir/00_scope_manifest.md" ]] || fail "missing manifest for empty scenario"
	[[ -f "$dynamic_dir/20_candidate_files.txt" ]] || fail "missing candidate file for empty scenario"
	[[ -f "$dynamic_dir/30_target_snippets.md" ]] || fail "missing snippets file for empty scenario"
	[[ ! -s "$dynamic_dir/20_candidate_files.txt" ]] || fail "empty scenario should not emit candidates"
	grep -Fq "Nenhum snippet selecionado." "$dynamic_dir/30_target_snippets.md" || fail "empty scenario should emit stable empty snippet artifact"
	test ! -f "$dynamic_dir/40_warnings.md" || fail "empty scenario should not emit warnings"
}

run_hits_limit_scenario() {
	local tmpdir repo_dir workdir card dynamic_dir i
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN
	repo_dir="$tmpdir/repo-hits"
	workdir="$tmpdir/workdir-hits"
	card="583HITS"

	create_repo "$repo_dir"
	mkdir -p "$repo_dir/src"
	for i in $(seq 1 25); do
		printf "needle_token_%02d\nshared_limit_token\n" "$i" >"$repo_dir/src/file_$i.txt"
	done
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "baseline hits"

	init_workdir "$workdir"
	write_repos_conf "$workdir" "$repo_dir"
	prime_feature_card_for_findings "$workdir" "$card" "shared_limit_token"

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	dynamic_dir="$workdir/out/$card/context/dynamic"
	[[ -f "$dynamic_dir/40_warnings.md" ]] || fail "hits scenario should emit warnings"
	grep -Fq "max_hits_por_token" "$dynamic_dir/40_warnings.md" || fail "hits scenario missing max_hits warning"
}

printf "[smoke] running baseline suite\n"
env -u EAW_WORKDIR bash "$REPO_ROOT/tests/smoke.sh" "$@"
run_signal_scenario
run_empty_scenario
run_hits_limit_scenario
printf "[smoke] dynamic baseline scenarios OK\n"
