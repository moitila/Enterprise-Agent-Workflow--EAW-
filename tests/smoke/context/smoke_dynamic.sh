#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

fail() {
	printf "smoke_dynamic failed: %s\n" "$1" >&2
	exit 1
}

# Prepara workdir isolado com repo git e card primado para fase findings.
init_findings_env() {
	local workdir="$1"
	local repo_dir="$2"
	local card="$3"
	local repo_key="$4"
	local ingest_content="$5"

	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null

	mkdir -p "$repo_dir/src"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@dynamic.test"
	git -C "$repo_dir" config user.name "smoke"
	cat >"$repo_dir/src/widget.sh" <<'EOF'
#!/usr/bin/env bash
build_widget_token() { printf "widget\n"; }
EOF
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "fixture"
	printf "\n# delta\n" >>"$repo_dir/src/widget.sh"

	cat >"$workdir/config/repos.conf" <<REOF
${repo_key}|${repo_dir}|target
REOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "dynamic smoke" >/dev/null

	mkdir -p "$workdir/out/$card/ingest"
	printf "%s\n" "$ingest_content" >"$workdir/out/$card/ingest/sources.md"

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
}

# Cenario: dynamic context basico
# Valida que a fase findings com previous_phase=ingest materializa context/dynamic/ com os
# artefatos obrigatorios (manifest, candidates, snippets).
run_dynamic_basic_scenario() {
	local tmpdir workdir repo_dir card dynamic_dir

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588DYN1"

	init_findings_env "$workdir" "$repo_dir" "$card" "dynamic-target" \
		"Use src/widget.sh and build_widget_token to inspect the baseline."

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	dynamic_dir="$workdir/out/$card/context/dynamic"

	# Validacao: artefatos obrigatorios de baseline dynamic
	test -f "$dynamic_dir/00_scope_manifest.md" \
		|| fail "dynamic basic: missing 00_scope_manifest.md"
	test -f "$dynamic_dir/20_candidate_files.txt" \
		|| fail "dynamic basic: missing 20_candidate_files.txt"
	test -f "$dynamic_dir/30_target_snippets.md" \
		|| fail "dynamic basic: missing 30_target_snippets.md"
	grep -Fq "deterministic_baseline_v1" "$dynamic_dir/00_scope_manifest.md" \
		|| fail "dynamic basic: manifest missing baseline identifier"
	grep -Fq "max_hits_por_token" "$dynamic_dir/00_scope_manifest.md" \
		|| fail "dynamic basic: manifest missing runtime limits"

	# Validacao: referencia de template no manifest (oracle: referencia de template)
	grep -Fq "deterministic_baseline_v1" "$dynamic_dir/00_scope_manifest.md" \
		|| fail "dynamic basic: template reference missing in manifest"

	# Validacao: sem conteudo fora de context/
	test ! -f "$workdir/out/$card/dynamic_context.md" \
		|| fail "dynamic basic: artifact escaped outside context/"
}

# Cenario: template inexistente
# Valida que configurar um onboarding_template inexistente produz erro observavel.
run_template_inexistente_scenario() {
	local tmpdir workdir repo_dir card err_output rc

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588DYN2"

	init_findings_env "$workdir" "$repo_dir" "$card" "dynamic-target" "fixture context"

	# Patch findings.yaml no workdir para usar onboarding_template inexistente
	# (o workdir usa tracks do RUNTIME_ROOT pois nao tem tracks/ proprio;
	#  copiamos e modificamos para o workdir)
	local tracks_src="$REPO_ROOT/tracks"
	[[ -d "$tracks_src" ]] \
		|| fail "template inexistente: tracks/ ausente em REPO_ROOT, impossivel aplicar patch"
	cp -r "$tracks_src" "$workdir/tracks"
	# Substitui onboarding_template por valor inexistente
	sed -i 's/onboarding_template: repo_discovery/onboarding_template: nonexistent_template_xyz/' \
		"$workdir/tracks/feature/phases/findings.yaml"

	set +e
	err_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" 2>&1)"
	rc=$?
	set -e

	# Validacao: eaw next deve falhar com erro observavel de template inexistente
	[[ "$rc" -ne 0 ]] \
		|| fail "template inexistente: expected failure but eaw next succeeded"
	printf "%s\n" "$err_output" | grep -Fq "template directory not found" \
		|| fail "template inexistente: error not observable in output: $err_output"
}

# Cenario: context nao materializado
# Valida que declarar dynamic_context_template sem materializar context/dynamic/ produz
# erro observavel "context nao materializado".
run_context_nao_materializado_scenario() {
	local tmpdir workdir repo_dir card err_output rc

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588DYN3"

	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@dynamic.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add . && git -C "$repo_dir" commit -q -m "fixture"

	cat >"$workdir/config/repos.conf" <<REOF
dynamic-target|$repo_dir|target
REOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "ctx not materialized" >/dev/null

	mkdir -p "$workdir/out/$card/ingest"
	printf "fixture\n" >"$workdir/out/$card/ingest/sources.md"

	# Prima para findings com previous_phase=hypotheses (nao ingest)
	# Isso evita auto-materializacao de dynamic context
	cat >"$workdir/out/$card/state_card_feature.yaml" <<STEOF
card_state:
  track_id: feature
  previous_phase: hypotheses
  current_phase: findings
  completed_phases:
    - ingest
    - hypotheses
  phase_status: RUN
  phase_started_at: 2026-03-29T00:00:00Z
  phase_completed: false
  phase_completed_at: null
STEOF

	# context/dynamic/ intencionalmente ausente

	set +e
	err_output="$(EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" 2>&1)"
	rc=$?
	set -e

	[[ "$rc" -ne 0 ]] \
		|| fail "context nao materializado: expected failure but eaw next succeeded"
	printf "%s\n" "$err_output" | grep -Fq "context nao materializado" \
		|| fail "context nao materializado: error not observable in output: $err_output"
}

# Cenario: determinismo - mesma entrada produz mesma saida
# Executa a fase findings duas vezes com a mesma entrada e compara os artefatos principais.
run_determinism_scenario() {
	local tmpdir workdir1 workdir2 repo_dir card

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	repo_dir="$tmpdir/repo"
	card="588DYN4"

	mkdir -p "$repo_dir/src"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@det.test"
	git -C "$repo_dir" config user.name "smoke"
	cat >"$repo_dir/src/stable.sh" <<'EOF'
#!/usr/bin/env bash
stable_token() { printf "stable\n"; }
EOF
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "stable fixture"

	# Primeira execucao
	workdir1="$tmpdir/run1"
	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir1" --force >/dev/null
	cat >"$workdir1/config/repos.conf" <<REOF
det-target|$repo_dir|target
REOF
	EAW_WORKDIR="$workdir1" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "determinism run" >/dev/null
	mkdir -p "$workdir1/out/$card/ingest"
	printf "stable_token\n" >"$workdir1/out/$card/ingest/sources.md"
	cat >"$workdir1/out/$card/state_card_feature.yaml" <<STEOF
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
	EAW_WORKDIR="$workdir1" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Segunda execucao com mesma entrada
	workdir2="$tmpdir/run2"
	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir2" --force >/dev/null
	cat >"$workdir2/config/repos.conf" <<REOF
det-target|$repo_dir|target
REOF
	EAW_WORKDIR="$workdir2" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "determinism run" >/dev/null
	mkdir -p "$workdir2/out/$card/ingest"
	printf "stable_token\n" >"$workdir2/out/$card/ingest/sources.md"
	cat >"$workdir2/out/$card/state_card_feature.yaml" <<STEOF
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
	EAW_WORKDIR="$workdir2" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: artefatos identicos entre as duas execucoes
	diff "$workdir1/out/$card/context/dynamic/20_candidate_files.txt" \
		"$workdir2/out/$card/context/dynamic/20_candidate_files.txt" \
		>/dev/null 2>&1 \
		|| fail "determinism: candidate_files.txt differs between runs"
	diff "$workdir1/out/$card/context/dynamic/30_target_snippets.md" \
		"$workdir2/out/$card/context/dynamic/30_target_snippets.md" \
		>/dev/null 2>&1 \
		|| fail "determinism: target_snippets.md differs between runs"

	# Validacao: ordenacao estavel - manifest identico
	diff "$workdir1/out/$card/context/dynamic/00_scope_manifest.md" \
		"$workdir2/out/$card/context/dynamic/00_scope_manifest.md" \
		>/dev/null 2>&1 \
		|| fail "determinism: scope_manifest.md differs between runs (unstable ordering)"
}

printf "[smoke] dynamic context basico\n"
run_dynamic_basic_scenario
printf "[smoke] template inexistente\n"
run_template_inexistente_scenario
printf "[smoke] context nao materializado\n"
run_context_nao_materializado_scenario
printf "[smoke] determinismo\n"
run_determinism_scenario
printf "[smoke] dynamic OK\n"
