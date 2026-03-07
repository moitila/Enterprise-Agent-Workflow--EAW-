#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

printf "[integration] running intake flow checks\n"
bash "$REPO_ROOT/tests/smoke_intake.sh"

printf "[integration] running implement flow checks\n"
bash "$REPO_ROOT/tests/smoke_implement.sh"
