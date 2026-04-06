#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

fail() {
	printf "smoke_onboarding failed: %s\n" "$1" >&2
	exit 1
}

# Prepara workdir, repo e card prontos para rodar a fase findings com onboarding.
# repo_key deve bater com a chave em repos.conf e com o dir em context_sources/onboarding/.
init_findings_env() {
	local workdir="$1"
	local repo_dir="$2"
	local card="$3"
	local repo_key="$4"

	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null

	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@onboarding.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "fixture"

	cat >"$workdir/config/repos.conf" <<EOF
${repo_key}|${repo_dir}|target
EOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "onboarding smoke" >/dev/null

	# Fornece fonte ingest para permitir materializacao de dynamic context
	mkdir -p "$workdir/out/$card/ingest"
	printf "README fixture\n" >"$workdir/out/$card/ingest/sources.md"

	# Prima estado diretamente para fase findings (previous_phase: ingest)
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

# Cenario: onboarding valido - fonte presente em context_sources/onboarding/
run_onboarding_valid_scenario() {
	local tmpdir workdir repo_dir card repo_key provenance_file

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588OBD1"
	repo_key="onboarding-target"

	init_findings_env "$workdir" "$repo_dir" "$card" "$repo_key"

	# Cria fonte de onboarding com arquivos validos
	mkdir -p "$workdir/context_sources/onboarding/$repo_key/docs"
	printf 'alpha\n' >"$workdir/context_sources/onboarding/$repo_key/README.md"
	printf 'beta\n' >"$workdir/context_sources/onboarding/$repo_key/docs/info.txt"
	printf 'ignored\n' >"$workdir/context_sources/onboarding/$repo_key/image.bin"

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: arquivos onboarding materializados
	test -f "$workdir/out/$card/context/onboarding/README.md" \
		|| fail "onboarding valid: missing materialized README.md"
	test -f "$workdir/out/$card/context/onboarding/docs/info.txt" \
		|| fail "onboarding valid: missing nested materialized file"
	grep -Fqx 'alpha' "$workdir/out/$card/context/onboarding/README.md" \
		|| fail "onboarding valid: materialized README content changed"
	test ! -e "$workdir/out/$card/context/onboarding/image.bin" \
		|| fail "onboarding valid: unsupported file should not materialize"

	# Validacao: provenance.md com campos obrigatorios
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"
	test -f "$provenance_file" || fail "onboarding valid: missing provenance.md"
	grep -Fq "context_sources/onboarding/$repo_key" "$provenance_file" \
		|| fail "onboarding valid: provenance missing source root"
	grep -Fq "README.md" "$provenance_file" \
		|| fail "onboarding valid: provenance missing considered file"
	grep -Fq "max_files_onboarding" "$provenance_file" \
		|| fail "onboarding valid: provenance missing max_files_onboarding"
	grep -Fq "max_bytes_total_onboarding" "$provenance_file" \
		|| fail "onboarding valid: provenance missing max_bytes_total_onboarding"

	# Validacao: sem conteudo fora de context/
	test ! -f "$workdir/out/$card/context/onboarding/image.bin" \
		|| fail "onboarding valid: binary file should not appear in context/"
}

# Cenario: onboarding inexistente - fonte ausente em context_sources/onboarding/
run_onboarding_absent_scenario() {
	local tmpdir workdir repo_dir card repo_key provenance_file

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588OBD2"
	repo_key="onboarding-target"

	init_findings_env "$workdir" "$repo_dir" "$card" "$repo_key"

	# Sem context_sources/onboarding/ - onboarding source ausente

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: provenance.md deve existir mesmo quando fonte ausente
	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"
	test -f "$provenance_file" \
		|| fail "onboarding absent: missing provenance.md when source absent"
	grep -Fq "source_status: absent" "$provenance_file" \
		|| fail "onboarding absent: source_status absent not recorded in provenance"

	# Validacao: sem arquivos de conteudo materializados (apenas provenance.md)
	local materialized_count
	materialized_count="$(find "$workdir/out/$card/context/onboarding" -type f -not -name "provenance.md" 2>/dev/null | wc -l)"
	[[ "$materialized_count" -eq 0 ]] \
		|| fail "onboarding absent: unexpected content files materialized: $materialized_count"
}

printf "[smoke] onboarding valido\n"
run_onboarding_valid_scenario
printf "[smoke] onboarding inexistente\n"
run_onboarding_absent_scenario
printf "[smoke] onboarding OK\n"
