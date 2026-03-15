#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf "[phase-engine] running lifecycle/integration-light phase engine checks\n"
bash "$REPO_ROOT/tests/workflow_next_phase_execution.sh"
