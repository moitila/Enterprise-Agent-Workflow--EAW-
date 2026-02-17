#!/usr/bin/env bash
set -euo pipefail

# Lightweight wrapper for the canonical test harness in tests/
if [[ -x "$(dirname "$0")/tests/smoke.sh" ]]; then
	exec "$(dirname "$0")/tests/smoke.sh" "$@"
else
	echo "tests/smoke.sh not found or not executable" >&2
	exit 1
fi
