#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_preflight_worktree failed: %s\n" "$1" >&2
	exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

wd="$tmp/workdir"
card="PFWT"

# Fixture: main git repo (.git diretorio) + worktree linkado (.git arquivo).
git init -q "$tmp/main"
git -C "$tmp/main" config user.email "smoke@example.com"
git -C "$tmp/main" config user.name "smoke"
printf "seed\n" >"$tmp/main/README.md"
git -C "$tmp/main" add README.md
git -C "$tmp/main" commit -q -m "seed"
git -C "$tmp/main" worktree add -q -b wtbr "$tmp/wt"

[[ -d "$tmp/main/.git" ]] || fail "fixture: main/.git deveria ser diretorio"
[[ -f "$tmp/wt/.git" ]] || fail "fixture: wt/.git deveria ser arquivo (worktree)"

# Diretorio simples sem git (nao-regressao da rejeicao).
mkdir -p "$tmp/plain"

# TDD-reverso ao nivel do predicado: a deteccao ANTIGA `[[ -d <repo>/.git ]]`
# gera falso-negativo para worktree (seu .git e arquivo), enquanto a deteccao
# canonica NOVA `git rev-parse --git-dir` a aceita.
if [[ -d "$tmp/wt/.git" ]]; then
	fail "TDD-reverso invalido: worktree/.git deveria ser arquivo (predicado antigo deve falhar)"
fi
if ! git -C "$tmp/wt" rev-parse --git-dir >/dev/null 2>&1; then
	fail "TDD-reverso invalido: predicado novo deve aceitar worktree"
fi

# Cria um card patch para materializar out/<CARD>/prompts/ (check 4 do preflight).
./scripts/eaw init --workdir "$wd" --force >/dev/null
printf 'main|%s|target\n' "$tmp/main" >"$wd/config/repos.conf"
EAW_WORKDIR="$wd" ./scripts/eaw card "$card" --track patch "preflight worktree smoke" >/dev/null
[[ -d "$wd/out/$card/prompts" ]] || fail "card patch nao materializou out/$card/prompts"

preflight_out=""
preflight_rc=0
run_preflight() {
	local repo_path="$1"
	printf 'smoke|%s|target\n' "$repo_path" >"$wd/config/repos.conf"
	set +e
	preflight_out="$(EAW_WORKDIR="$wd" ./scripts/eaw preflight "$card" 2>&1)"
	preflight_rc=$?
	set -e
}

# Caso (1): ACEITA worktree (.git arquivo) — o fix corrige o falso-negativo.
run_preflight "$tmp/wt"
[[ "$preflight_rc" -eq 0 ]] || fail "caso1 worktree: preflight deveria PASSAR (rc=$preflight_rc out=$preflight_out)"
grep -Fq "PASS (4/4 checks)" <<<"$preflight_out" || fail "caso1 worktree: faltou 'PASS (4/4 checks)': $preflight_out"
if grep -Fq "não é repositório git" <<<"$preflight_out"; then
	fail "caso1 worktree: rejeicao git inesperada: $preflight_out"
fi

# Caso (2): REJEITA diretorio nao-git (nao-regressao).
run_preflight "$tmp/plain"
[[ "$preflight_rc" -ne 0 ]] || fail "caso2 dir nao-git: preflight deveria FALHAR (out=$preflight_out)"
grep -Fq "não é repositório git: $tmp/plain" <<<"$preflight_out" || fail "caso2 dir nao-git: faltou rejeicao git: $preflight_out"

# Caso (3): ACEITA .git diretorio (nao-regressao).
run_preflight "$tmp/main"
[[ "$preflight_rc" -eq 0 ]] || fail "caso3 git dir: preflight deveria PASSAR (rc=$preflight_rc out=$preflight_out)"
grep -Fq "PASS (4/4 checks)" <<<"$preflight_out" || fail "caso3 git dir: faltou 'PASS (4/4 checks)': $preflight_out"

printf "smoke preflight worktree OK\n"
