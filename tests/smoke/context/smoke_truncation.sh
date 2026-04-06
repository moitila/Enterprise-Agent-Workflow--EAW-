#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

fail() {
	printf "smoke_truncation failed: %s\n" "$1" >&2
	exit 1
}

# Cenario: truncamento e ordenacao estavel
# Valida que o onboarding respeita max_files_onboarding e max_bytes_per_file_onboarding,
# registra as exclusoes em provenance.md e mantem ordenacao estavel.
run_truncation_scenario() {
	local tmpdir workdir repo_dir card repo_key provenance_file n

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588TRUNC"
	repo_key="trunc-target"

	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null

	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@trunc.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add . && git -C "$repo_dir" commit -q -m "fixture"

	cat >"$workdir/config/repos.conf" <<REOF
${repo_key}|${repo_dir}|target
REOF

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "truncation smoke" >/dev/null

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

	# Cria 12 arquivos ordenados (acima do limite padrao de 10) + 1 arquivo grande
	local onboarding_src="$workdir/context_sources/onboarding/$repo_key"
	mkdir -p "$onboarding_src"
	for n in $(seq 1 12); do
		printf 'ordered-%02d\n' "$n" >"$onboarding_src/file_$(printf '%02d' "$n").md"
	done
	# Arquivo grande (acima de max_bytes_per_file_onboarding = 200KB)
	dd if=/dev/zero bs=205001 count=1 2>/dev/null | tr '\0' 'x' >"$onboarding_src/large.json"

	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	provenance_file="$workdir/out/$card/context/onboarding/provenance.md"

	# Validacao: primeiros arquivos materializados (ordenacao estavel)
	test -f "$workdir/out/$card/context/onboarding/file_01.md" \
		|| fail "truncation: first ordered file missing"
	test -f "$workdir/out/$card/context/onboarding/file_10.md" \
		|| fail "truncation: tenth ordered file missing"

	# Validacao: truncamento por max_files_onboarding
	test ! -e "$workdir/out/$card/context/onboarding/file_11.md" \
		|| fail "truncation: max_files_onboarding should have truncated at file_11"

	# Validacao: truncamento registrado em provenance.md
	test -f "$provenance_file" || fail "truncation: missing provenance.md"
	grep -Fq "max_files_onboarding" "$provenance_file" \
		|| fail "truncation: provenance missing max_files_onboarding record"
	grep -Fq "file_11.md | reason=max_files_onboarding" "$provenance_file" \
		|| fail "truncation: provenance missing file_11.md truncation record"
	grep -Fq "large.json | reason=max_bytes_per_file_onboarding" "$provenance_file" \
		|| fail "truncation: provenance missing large.json per-file limit record"

	# Validacao: sem conteudo fora de context/
	test ! -e "$workdir/out/$card/file_01.md" \
		|| fail "truncation: artifact escaped outside context/"
}

# Cenario: ordenacao estavel - dois runs com mesma entrada produzem mesma ordem
run_stable_ordering_scenario() {
	local tmpdir workdir1 workdir2 repo_dir card repo_key n

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	repo_dir="$tmpdir/repo"
	card="588ORD"
	repo_key="ord-target"

	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@ord.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add . && git -C "$repo_dir" commit -q -m "fixture"

	# Prepara dois workdirs identicos com a mesma fonte de onboarding
	local setup_workdir
	setup_workdir() {
		local workdir="$1"
		env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
		cat >"$workdir/config/repos.conf" <<REOF
${repo_key}|${repo_dir}|target
REOF
		EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "stable order" >/dev/null
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
		local onboarding_src="$workdir/context_sources/onboarding/$repo_key"
		mkdir -p "$onboarding_src"
		for n in $(seq 1 5); do
			printf 'item-%02d\n' "$n" >"$onboarding_src/file_$(printf '%02d' "$n").md"
		done
	}

	workdir1="$tmpdir/run1"
	workdir2="$tmpdir/run2"
	setup_workdir "$workdir1"
	setup_workdir "$workdir2"

	EAW_WORKDIR="$workdir1" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null
	EAW_WORKDIR="$workdir2" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: lista de arquivos materializados identica (ordenacao estavel)
	# Extrai a secao "## Materialized Files" do provenance.md para comparar ordenacao
	local list1 list2
	list1="$(awk '/^## Materialized Files/{p=1;next} /^## /{p=0} p && /^- /' \
		"$workdir1/out/$card/context/onboarding/provenance.md")"
	list2="$(awk '/^## Materialized Files/{p=1;next} /^## /{p=0} p && /^- /' \
		"$workdir2/out/$card/context/onboarding/provenance.md")"
	[[ "$list1" == "$list2" ]] \
		|| fail "stable ordering: materialized file list differs between runs"

	# Validacao: conteudo dos arquivos materializados identico
	for n in $(seq 1 5); do
		local fname="file_$(printf '%02d' "$n").md"
		diff "$workdir1/out/$card/context/onboarding/$fname" \
			"$workdir2/out/$card/context/onboarding/$fname" \
			>/dev/null 2>&1 \
			|| fail "stable ordering: $fname content differs between runs"
	done
}

printf "[smoke] truncamento\n"
run_truncation_scenario
printf "[smoke] ordenacao estavel\n"
run_stable_ordering_scenario
printf "[smoke] truncation OK\n"
