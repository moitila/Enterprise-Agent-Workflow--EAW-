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
./scripts/eaw feature "$CARD" "intake smoke"
./scripts/eaw intake "$CARD" >/dev/null
./scripts/eaw intake "$CARD" --round=2 >/dev/null

r1="$EAW_WORKDIR/out/$CARD/investigations/intake_agent_prompt.round_1.md"
r2="$EAW_WORKDIR/out/$CARD/investigations/intake_agent_prompt.round_2.md"

[[ -f "$r1" ]] || fail "missing $r1"
[[ -f "$r2" ]] || fail "missing $r2"

for f in "$r1" "$r2"; do
	grep -Fq "out/<CARD>/intake/" "$f" || fail "missing anchor out/<CARD>/intake/ in $f"
	grep -Fq "investigations/_intake_provenance.md" "$f" || fail "missing anchor investigations/_intake_provenance.md in $f"
	grep -Fq "eaw intake <CARD>" "$f" || fail "missing anchor eaw intake <CARD> in $f"
done

printf "OK\n"
