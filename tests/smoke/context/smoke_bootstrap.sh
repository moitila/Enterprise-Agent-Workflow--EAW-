#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

fail() {
	printf "smoke_bootstrap failed: %s\n" "$1" >&2
	exit 1
}

# Cenario: bootstrap opcional e determinismo
# Valida que o sistema funciona com dynamic e onboarding configurados,
# que o bootstrap (primeira execucao sem context pre-existente) produz todos os artefatos,
# e que repeticao da mesma entrada produz mesma saida.
#
# oracle: ## CONTEXT - ONBOARDING (intake requirement; runtime emits without ## prefix, H3)
# oracle: ## CONTEXT - DYNAMIC (intake requirement; runtime emits without ## prefix, H3)
run_bootstrap_scenario() {
	local tmpdir workdir repo_dir card repo_key provenance_file dynamic_dir prompt_file

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588BOOT"
	repo_key="boot-target"

	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null

	mkdir -p "$repo_dir/src"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@boot.test"
	git -C "$repo_dir" config user.name "smoke"
	cat >"$repo_dir/src/core.sh" <<'EOF'
#!/usr/bin/env bash
bootstrap_token() { printf "bootstrap\n"; }
EOF
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "bootstrap fixture"

	cat >"$workdir/config/repos.conf" <<REOF
${repo_key}|${repo_dir}|target
REOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "bootstrap smoke" >/dev/null

	mkdir -p "$workdir/out/$card/ingest"
	printf "bootstrap_token\n" >"$workdir/out/$card/ingest/sources.md"

	cat >"$workdir/out/$card/state_card_feature.yaml" <<STEOF
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
STEOF

	# Cria fonte de onboarding (bootstrap opcional: sistema funciona com ou sem fonte)
	mkdir -p "$workdir/context_sources/onboarding/$repo_key"
	printf 'bootstrap-doc\n' >"$workdir/context_sources/onboarding/$repo_key/README.md"

	# Primeira execucao (bootstrap)
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	dynamic_dir="$workdir/out/$card/context/dynamic"
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"

	# Validacao: baseline dynamic registrada
	test -f "$dynamic_dir/00_scope_manifest.md" \
		|| fail "bootstrap: missing 00_scope_manifest.md"
	test -f "$dynamic_dir/20_candidate_files.txt" \
		|| fail "bootstrap: missing 20_candidate_files.txt"
	test -f "$dynamic_dir/30_target_snippets.md" \
		|| fail "bootstrap: missing 30_target_snippets.md"

	# Validacao: out/<CARD>/context/onboarding/provenance.md
	test -f "$provenance_file" || fail "bootstrap: missing onboarding provenance.md"
	grep -Fq "max_files_onboarding" "$provenance_file" \
		|| fail "bootstrap: provenance missing max_files_onboarding"

	# Validacao: headings CONTEXT - ONBOARDING e CONTEXT - DYNAMIC no prompt gerado
	# oracle: ## CONTEXT - ONBOARDING
	# oracle: ## CONTEXT - DYNAMIC
	prompt_file="$workdir/out/$card/prompts/findings.md"
	test -f "$prompt_file" || fail "bootstrap: missing findings prompt file"
	grep -Fq "CONTEXT - ONBOARDING" "$prompt_file" \
		|| fail "bootstrap: prompt missing CONTEXT - ONBOARDING heading"
	grep -Fq "CONTEXT - DYNAMIC" "$prompt_file" \
		|| fail "bootstrap: prompt missing CONTEXT - DYNAMIC heading"

	# Snapshotar artefatos para comparacao de determinismo
	local manifest_snap candidates_snap snippets_snap prov_snap
	manifest_snap="$(cat "$dynamic_dir/00_scope_manifest.md")"
	candidates_snap="$(cat "$dynamic_dir/20_candidate_files.txt")"
	snippets_snap="$(cat "$dynamic_dir/30_target_snippets.md")"
	prov_snap="$(cat "$provenance_file")"

	# Segunda execucao com mesma entrada (validacao de determinismo)
	# Reseta estado para reexecutar findings com mesma entrada
	cat >"$workdir/out/$card/state_card_feature.yaml" <<STEOF
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
STEOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: mesma saida (determinismo explicito)
	[[ "$(cat "$dynamic_dir/20_candidate_files.txt")" == "$candidates_snap" ]] \
		|| fail "bootstrap determinism: candidate_files.txt changed between runs"
	[[ "$(cat "$dynamic_dir/30_target_snippets.md")" == "$snippets_snap" ]] \
		|| fail "bootstrap determinism: target_snippets.md changed between runs"
	[[ "$(cat "$dynamic_dir/00_scope_manifest.md")" == "$manifest_snap" ]] \
		|| fail "bootstrap determinism: scope_manifest.md changed between runs (unstable ordering)"
	[[ "$(cat "$provenance_file")" == "$prov_snap" ]] \
		|| fail "bootstrap determinism: provenance.md changed between runs"
}

# Cenario: bootstrap sem fonte de onboarding (bootstrap opcional = funciona sem fonte)
run_bootstrap_no_onboarding_scenario() {
	local tmpdir workdir repo_dir card provenance_file

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588BOOT0"

	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null

	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@boot0.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add . && git -C "$repo_dir" commit -q -m "fixture"

	cat >"$workdir/config/repos.conf" <<REOF
boot0-target|$repo_dir|target
REOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "bootstrap no onboarding" >/dev/null

	mkdir -p "$workdir/out/$card/ingest"
	printf "fixture\n" >"$workdir/out/$card/ingest/sources.md"

	cat >"$workdir/out/$card/state_card_feature.yaml" <<STEOF
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
STEOF

	# Sem context_sources/onboarding/ - bootstrap sem fonte (opcional)
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: bootstrap funciona mesmo sem fonte (onboarding e opcional)
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"
	test -f "$provenance_file" \
		|| fail "bootstrap no onboarding: provenance.md missing when source absent"
	grep -Fq "source_status: absent" "$provenance_file" \
		|| fail "bootstrap no onboarding: source_status absent not recorded"

	# Validacao: dynamic context tambem funciona no bootstrap
	test -f "$workdir/out/$card/context/dynamic/00_scope_manifest.md" \
		|| fail "bootstrap no onboarding: dynamic context manifest missing"
}

printf "[smoke] bootstrap com onboarding e determinismo\n"
run_bootstrap_scenario
printf "[smoke] bootstrap sem fonte de onboarding\n"
run_bootstrap_no_onboarding_scenario
printf "[smoke] bootstrap OK\n"
