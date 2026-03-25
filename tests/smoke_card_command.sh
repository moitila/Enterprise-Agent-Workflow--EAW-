#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_card_command failed: %s\n" "$1" >&2
	exit 1
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

workdir="$tmp_root/workdir"
target_repo="$tmp_root/target"

mkdir -p "$target_repo"
git -C "$target_repo" init -q
git -C "$target_repo" config user.email "smoke@example.com"
git -C "$target_repo" config user.name "smoke"
printf "hello\n" >"$target_repo/README.md"
git -C "$target_repo" add README.md
git -C "$target_repo" commit -q -m "seed"

./scripts/eaw init --workdir "$workdir" --force >/dev/null
cat >"$workdir/config/repos.conf" <<CFG
local-main|$target_repo|target
CFG

help_output="$(EAW_WORKDIR="$workdir" ./scripts/eaw --help)"
grep -Fq 'eaw card <CARD> --track <TRACK>' <<<"$help_output" || fail "usage missing card command"

EAW_WORKDIR="$workdir" ./scripts/eaw card CARDSTD --track standard >/dev/null
test -f "$workdir/out/CARDSTD/standard_CARDSTD.md" || fail "standard track did not create standard dossier"
test -f "$workdir/out/CARDSTD/state_card_standard.yaml" || fail "standard track state file missing"
grep -Fq 'track_id: standard' "$workdir/out/CARDSTD/state_card_standard.yaml" || fail "standard track state mismatch"

EAW_WORKDIR="$workdir" ./scripts/eaw card CARDBUG --track bug "Bug title" >/dev/null
test -f "$workdir/out/CARDBUG/bug_CARDBUG.md" || fail "bug track did not create bug dossier"
test -f "$workdir/out/CARDBUG/state_card_bug.yaml" || fail "bug track state file missing"
grep -Fq 'track_id: bug' "$workdir/out/CARDBUG/state_card_bug.yaml" || fail "bug track state mismatch"

set +e
missing_output="$(EAW_WORKDIR="$workdir" ./scripts/eaw card CARDMISS 2>&1)"
missing_rc=$?
set -e
[[ "$missing_rc" -ne 0 ]] || fail "missing --track should fail"
grep -Fq 'multiple tracks installed — specify with --track <TRACK>' <<<"$missing_output" || fail "missing --track message mismatch"

set +e
invalid_output="$(EAW_WORKDIR="$workdir" ./scripts/eaw card CARDINV --track ghost 2>&1)"
invalid_rc=$?
set -e
[[ "$invalid_rc" -ne 0 ]] || fail "invalid track should fail"
grep -Fq "track 'ghost' is invalid or not installed" <<<"$invalid_output" || fail "invalid track message mismatch"

printf "smoke_card_command OK\n"
