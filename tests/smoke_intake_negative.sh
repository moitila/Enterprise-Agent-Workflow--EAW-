#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_intake_negative failed: %s\n" "$1" >&2
	exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_no_repo_residue() {
	local card="$1"
	if [[ -e "$REPO_ROOT/out/$card" ]]; then
		fail "unexpected residue outside tempdir: $REPO_ROOT/out/$card"
	fi
}

card_template_missing="4013A"
card_round_invalid="4013B"

# Scenario A: missing template
isolated_root="$tmpdir/isolated_root"
mkdir -p "$isolated_root"
ln -s "$REPO_ROOT/scripts" "$isolated_root/scripts"

isolated_workdir="$tmpdir/isolated_workdir"
"$isolated_root/scripts/eaw" init --workdir "$isolated_workdir" --force >/dev/null

set +e
scenario_a_output="$(EAW_WORKDIR="$isolated_workdir" "$isolated_root/scripts/eaw" intake "$card_template_missing" 2>&1)"
scenario_a_rc=$?
set -e

[[ $scenario_a_rc -ne 0 ]] || fail "scenario A expected non-zero exit code"
grep -Fq "template not found" <<<"$scenario_a_output" || fail "scenario A missing substring: template not found"
assert_no_repo_residue "$card_template_missing"

# Scenario B: invalid --round argument
workdir="$tmpdir/workdir"
./scripts/eaw init --workdir "$workdir" --force >/dev/null

set +e
scenario_b_output="$(EAW_WORKDIR="$workdir" ./scripts/eaw intake "$card_round_invalid" --round=abc 2>&1)"
scenario_b_rc=$?
set -e

[[ $scenario_b_rc -ne 0 ]] || fail "scenario B expected non-zero exit code"
grep -Fq "usage: eaw intake <CARD> [--round=N]" <<<"$scenario_b_output" || fail "scenario B missing usage substring"
assert_no_repo_residue "$card_round_invalid"

printf "OK\n"
