#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_intake failed: %s\n" "$1" >&2
	exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export EAW_WORKDIR="$tmpdir/.eaw"
CARD="4012"

./scripts/eaw init --workdir "$EAW_WORKDIR" --upgrade
./scripts/eaw card "$CARD" --track standard "intake smoke"
./scripts/eaw intake "$CARD" >/dev/null
./scripts/eaw intake "$CARD" --round=2 >/dev/null

prompt="$EAW_WORKDIR/out/$CARD/prompts/intake.md"

[[ -f "$prompt" ]] || fail "missing $prompt"
grep -Fq "out/<CARD>/intake/" "$prompt" || fail "missing anchor out/<CARD>/intake/ in $prompt"
grep -Fq "investigations/_intake_provenance.md" "$prompt" || fail "missing anchor investigations/_intake_provenance.md in $prompt"
grep -Fq "CONFIG_SOURCE=" "$prompt" || fail "missing CONFIG_SOURCE in $prompt"

printf "OK\n"
