#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANONICAL_SMOKE="$REPO_ROOT/tests/smoke.sh"
EAW_SCRIPT="$REPO_ROOT/scripts/eaw"
HELP_WORKDIR="$(mktemp -d)"

cleanup() {
	rm -rf "$HELP_WORKDIR"
}
trap cleanup EXIT INT TERM

run_help_check() {
	local label="$1"
	shift
	local output

	output="$(EAW_WORKDIR="$HELP_WORKDIR" "$EAW_SCRIPT" "$@" 2>&1)"
	if [[ $? -ne 0 ]]; then
		echo "Smoke failed: help command returned non-zero: $label" >&2
		echo "$output" >&2
		exit 1
	fi
	if [[ "$output" != *"Usage:"* ]]; then
		echo "Smoke failed: help output missing Usage: $label" >&2
		echo "$output" >&2
		exit 1
	fi
	if [[ "$output" == *"Wrote "* || "$output" == *"CREATED:"* ]]; then
		echo "Smoke failed: help command produced write marker: $label" >&2
		echo "$output" >&2
		exit 1
	fi
}

run_help_check "--help" --help
run_help_check "-h" -h
run_help_check "intake --help" intake --help
run_help_check "intake -h" intake -h
run_help_check "analyze --help" analyze --help
run_help_check "analyze -h" analyze -h
run_help_check "implement --help" implement --help
run_help_check "implement -h" implement -h

if [[ -d "$HELP_WORKDIR/out/--help" || -d "$HELP_WORKDIR/out/-h" ]]; then
	echo "Smoke failed: help commands created out/--help or out/-h" >&2
	exit 1
fi

if [[ ! -f "$CANONICAL_SMOKE" ]]; then
	echo "tests/smoke.sh not found" >&2
	exit 1
fi

if [[ -x "$CANONICAL_SMOKE" ]]; then
	env -u EAW_WORKDIR "$CANONICAL_SMOKE" "$@"
else
	env -u EAW_WORKDIR bash "$CANONICAL_SMOKE" "$@"
fi
