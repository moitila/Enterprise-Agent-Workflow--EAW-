#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

printf "[golden] running scaffold parity checks\n"
bash "$REPO_ROOT/tests/scaffold_parity_smoke.sh"
