#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CARD="930005"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export EAW_WORKDIR="$tmpdir/.eaw"
CARD_DIR="$EAW_WORKDIR/out/$CARD"
IMPL_DIR="$CARD_DIR/implementation"

if [[ ! -f "./scripts/eaw" ]]; then
	echo "ERROR: must run from repo root containing scripts/eaw" >&2
	exit 1
fi

echo "SMOKE: card=$CARD"

bash ./scripts/eaw init --workdir "$EAW_WORKDIR" --upgrade >/dev/null 2>&1
bash ./scripts/eaw feature "$CARD" "smoke implement" >/dev/null 2>&1
bash ./scripts/eaw implement "$CARD" >/dev/null 2>&1
echo "SMOKE: implement OK"

if [[ ! -d "$IMPL_DIR" ]]; then
	echo "ERROR: missing implement artifact: $IMPL_DIR" >&2
	exit 1
fi

for path in \
	"$IMPL_DIR/00_scope.lock.md" \
	"$IMPL_DIR/10_change_plan.md" \
	"$IMPL_DIR/20_patch_notes.md"; do
	if [[ ! -e "$path" ]]; then
		echo "ERROR: missing implement artifact: $path" >&2
		exit 1
	fi
	if [[ ! -f "$path" ]]; then
		echo "ERROR: implement artifact not a regular file: $path" >&2
		exit 1
	fi
	if [[ ! -s "$path" ]]; then
		echo "ERROR: empty implement artifact: $path" >&2
		exit 1
	fi
done
echo "SMOKE: artifacts OK"

set +e
bash ./scripts/eaw validate >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -ne 0 ]]; then
	echo "ERROR: validate failed" >&2
	exit "$rc"
fi

echo "SMOKE: validate OK"
echo "SMOKE: PASS"
