#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

fail() {
	printf "smoke_context_none failed: %s\n" "$1" >&2
	exit 1
}

# Cenario: sem contexto
# Valida que um card em fase sem context templates nao materializa context/dynamic/ nem
# context/onboarding/, e que nenhum conteudo inesperado aparece em context/.
run_no_context_scenario() {
	local tmpdir workdir repo_dir card

	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="588CTX0"

	# Inicializa workdir isolado
	env -u EAW_WORKDIR "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null

	# Cria repositorio git minimo para repos.conf
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@ctx.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add .
	git -C "$repo_dir" commit -q -m "fixture"

	cat >"$workdir/config/repos.conf" <<EOF
ctx-none-target|$repo_dir|target
EOF

	# Cria card: inicia na fase ingest (sem context templates)
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" card "$card" --track feature "sem contexto" >/dev/null

	# Executa eaw next: roda fase ingest, sem materializacao de contexto
	EAW_WORKDIR="$workdir" "$REPO_ROOT/scripts/eaw" next "$card" >/dev/null

	# Validacao: context/ deve existir (criado pelo track initial_outputs)
	test -d "$workdir/out/$card/context" || fail "context/ directory missing after ingest phase"

	# Validacao: context/dynamic/ e context/onboarding/ NAO devem existir
	test ! -d "$workdir/out/$card/context/dynamic" \
		|| fail "context/dynamic/ should not exist when no context template configured"
	test ! -d "$workdir/out/$card/context/onboarding" \
		|| fail "context/onboarding/ should not exist when no context template configured"

	# Validacao: sem conteudo fora de context/ inesperado
	local unexpected_files
	unexpected_files="$(find "$workdir/out/$card/context" -type f 2>/dev/null | wc -l)"
	[[ "$unexpected_files" -eq 0 ]] \
		|| fail "unexpected content in context/ for no-context scenario: $unexpected_files file(s)"

	# Validacao: context/ nao tem subdiretorios alem do esperado
	local unexpected_dirs
	unexpected_dirs="$(find "$workdir/out/$card/context" -mindepth 1 -type d 2>/dev/null | wc -l)"
	[[ "$unexpected_dirs" -eq 0 ]] \
		|| fail "unexpected subdirectories in context/ for no-context scenario: $unexpected_dirs dir(s)"
}

printf "[smoke] sem contexto\n"
run_no_context_scenario
printf "[smoke] context_none OK\n"
