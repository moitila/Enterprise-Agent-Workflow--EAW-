#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
TMP_ROOT=""
CARD_ID="94002"

fail() {
	printf "scaffold parity smoke failed: %s\n" "$1" >&2
	exit 1
}

assert_intake_scaffold() {
	local dir="$1"
	[[ -d "$dir" ]] || fail "missing intake dir: $dir"
	local state_file
	state_file="$(find "$dir" -maxdepth 1 -type f -name 'state_card_*.yaml' | LC_ALL=C sort)"
	[[ -n "$state_file" ]] || fail "missing canonical state scaffold in intake dir: $dir"
	local count
	count="$(find "$dir" -mindepth 1 -maxdepth 1 -print | wc -l | tr -d '[:space:]')"
	[[ "$count" == "1" ]] || fail "unexpected extra intake scaffold entries in: $dir"
}

capture_tree() {
	local card_dir="$1"
	local out_file="$2"
	find "$card_dir" \
		\( -path "$card_dir/context" -o -path "$card_dir/context/*" \) -prune -o \
		\( -type d -o -type f \) -print | LC_ALL=C sort >"$out_file"
}

main() {
	local ws normal_out normal_card ws_card
	TMP_ROOT="$(mktemp -d)"
	ws="$TMP_ROOT/ws"
	normal_out="$TMP_ROOT/normal_out"
	normal_card="$normal_out/$CARD_ID"
	ws_card="$ws/out/$CARD_ID"

	cleanup() {
		rm -rf "$TMP_ROOT"
	}
	trap cleanup EXIT

	EAW_WORKDIR="" EAW_OUT_DIR="$normal_out" ./scripts/eaw card "$CARD_ID" --track bug "scaffold test normal" >/dev/null
	assert_intake_scaffold "$normal_card/intake"

	./scripts/eaw init --workdir "$ws" --upgrade >/dev/null
	cat >"$ws/config/repos.conf" <<EOF
local-main|$REPO_ROOT|target
EOF
	EAW_WORKDIR="$ws" ./scripts/eaw card "$CARD_ID" --track bug "scaffold test workspace" >/dev/null
	assert_intake_scaffold "$ws_card/intake"

	local normal_paths ws_paths normal_norm ws_norm
	normal_paths="$TMP_ROOT/normal.paths"
	ws_paths="$TMP_ROOT/ws.paths"
	normal_norm="$TMP_ROOT/normal.norm.paths"
	ws_norm="$TMP_ROOT/ws.norm.paths"

	capture_tree "$normal_card" "$normal_paths"
	capture_tree "$ws_card" "$ws_paths"

	sed "s|$normal_card|out/CARD|g" "$normal_paths" >"$normal_norm"
	sed "s|$ws_card|out/CARD|g" "$ws_paths" >"$ws_norm"

	local diff_file
	diff_file="$TMP_ROOT/scaffold.diff"
	if ! diff -u "$normal_norm" "$ws_norm" >"$diff_file"; then
		cat "$diff_file" >&2
		fail "normal/workspace scaffold tree mismatch"
	fi
	sha256sum "$normal_norm" "$ws_norm" >/dev/null

	printf "scaffold parity smoke OK\n"
}

main "$@"
