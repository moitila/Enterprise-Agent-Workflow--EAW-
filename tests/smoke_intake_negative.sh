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
card_workdir_invalid="4013C"
card_ingest_and_intake_missing="9901"

# Scenario A: missing canonical card workflow scaffold
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
grep -Fq "is missing canonical workflow YAMLs" <<<"$scenario_a_output" || fail "scenario A missing substring: is missing canonical workflow YAMLs"
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

# Scenario C: invalid EAW_WORKDIR/card workspace precondition
invalid_workdir="$tmpdir/eaw-workdir-inexistente-$$"
set +e
scenario_c_output="$(EAW_WORKDIR="$invalid_workdir" ./scripts/eaw intake "$card_workdir_invalid" --round=1 2>&1)"
scenario_c_rc=$?
set -e

[[ $scenario_c_rc -ne 0 ]] || fail "scenario C expected non-zero exit code"
if ! grep -Fq "ERROR:" <<<"$scenario_c_output"; then
	grep -Fq "EAW_WORKDIR is set but workspace config is incomplete." <<<"$scenario_c_output" || fail "scenario C missing runtime pre-check context"
fi
grep -Fq "./scripts/eaw init --workdir \"$invalid_workdir\"" <<<"$scenario_c_output" || fail "scenario C missing recommended action"
assert_no_repo_residue "$card_workdir_invalid"

# Scenario D: missing ingest/ and intake/ after feature card scaffold
scenario_d_workdir="$tmpdir/scenario-d-workdir"
./scripts/eaw init --workdir "$scenario_d_workdir" --force >/dev/null
EAW_WORKDIR="$scenario_d_workdir" ./scripts/eaw card "$card_ingest_and_intake_missing" --track feature >/dev/null 2>&1
rm -rf "$scenario_d_workdir/out/$card_ingest_and_intake_missing/ingest"
rm -rf "$scenario_d_workdir/out/$card_ingest_and_intake_missing/intake"

set +e
scenario_d_output="$(EAW_WORKDIR="$scenario_d_workdir" ./scripts/eaw intake "$card_ingest_and_intake_missing" --round=1 2>&1)"
scenario_d_rc=$?
set -e

[[ $scenario_d_rc -ne 0 ]] || fail "scenario D expected non-zero exit code"
grep -Fq "missing required artifacts: ingest/intake_feature.md" <<<"$scenario_d_output" || fail "scenario D missing expected ingest artifact failure"
assert_no_repo_residue "$card_ingest_and_intake_missing"

printf "OK\n"
