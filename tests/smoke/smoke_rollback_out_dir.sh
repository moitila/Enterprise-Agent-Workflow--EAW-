#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

TMP_ROOT="$(mktemp -d)"

fail() {
	printf "rollback out dir smoke failed: %s\n" "$1" >&2
	exit 1
}

cleanup() {
	local rc=$?
	rm -rf "$TMP_ROOT"
	exit "$rc"
}
trap cleanup EXIT INT TERM

create_fixture() {
	local fixture_root="$1"
	local repo_dir="$fixture_root/repo"
	local workdir="$fixture_root/workdir"
	local card="ROLLBACK_SMOKE"

	mkdir -p "$repo_dir/src" "$workdir/config"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "rollback-smoke@example.com"
	git -C "$repo_dir" config user.name "rollback-smoke"
	printf "original content\n" >"$repo_dir/src/rollback_target.txt"
	git -C "$repo_dir" add src/rollback_target.txt
	git -C "$repo_dir" commit -q -m "rollback smoke baseline"
	printf "changed content\n" >"$repo_dir/src/rollback_target.txt"

	printf "rollback-target|%s|target\n" "$repo_dir" >"$workdir/config/repos.conf"
	mkdir -p "$workdir/out/$card/implementation"
	cat >"$workdir/out/$card/implementation/00_scope.lock.md" <<'EOF'
## Allowlist

- `src/rollback_target.txt`
EOF

	printf '%s\n' "$repo_dir" "$workdir" "$card"
}

run_override_scenario() {
	local fixture_root="$TMP_ROOT/override"
	local alternate_out="$fixture_root/alternate-out"
	local repo_dir workdir card output
	local -a fixture
	mapfile -t fixture < <(create_fixture "$fixture_root")
	repo_dir="${fixture[0]}"
	workdir="${fixture[1]}"
	card="${fixture[2]}"

	mkdir -p "$alternate_out"
	mv "$workdir/out/$card" "$alternate_out/$card"

	if ! output="$(EAW_WORKDIR="$workdir" EAW_OUT_DIR="$alternate_out" bash "$REPO_ROOT/scripts/eaw" rollback "$card" 2>&1)"; then
		printf '%s\n' "$output" >&2
		fail "alternate output rollback returned non-zero"
	fi
	grep -Fq "restored: src/rollback_target.txt" <<<"$output" || fail "alternate output did not report restoration"
	grep -Fxq "original content" "$repo_dir/src/rollback_target.txt" || fail "alternate output did not restore content"
	[[ ! -e "$workdir/out/$card" ]] || fail "alternate output scenario used default output"

	printf "rollback out dir smoke override OK\n"
}

run_default_scenario() {
	local fixture_root="$TMP_ROOT/default"
	local alternate_out="$fixture_root/unused-out"
	local repo_dir workdir card output
	local -a fixture
	mapfile -t fixture < <(create_fixture "$fixture_root")
	repo_dir="${fixture[0]}"
	workdir="${fixture[1]}"
	card="${fixture[2]}"

	mkdir -p "$alternate_out"
	if ! output="$(env -u EAW_OUT_DIR EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" rollback "$card" 2>&1)"; then
		printf '%s\n' "$output" >&2
		fail "default output rollback returned non-zero"
	fi
	grep -Fq "restored: src/rollback_target.txt" <<<"$output" || fail "default output did not report restoration"
	grep -Fxq "original content" "$repo_dir/src/rollback_target.txt" || fail "default output did not restore content"
	[[ ! -e "$alternate_out/$card" ]] || fail "default output scenario used alternate output"

	printf "rollback out dir smoke default OK\n"
}

run_override_scenario
run_default_scenario
printf "rollback out dir smoke OK\n"
