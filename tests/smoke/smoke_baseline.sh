#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

printf "[smoke] running baseline suite\n"
env -u EAW_WORKDIR bash "$REPO_ROOT/tests/smoke.sh" "$@"
