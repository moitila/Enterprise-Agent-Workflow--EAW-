#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

printf "[lifecycle] running phase lifecycle checks\n"
bash "$REPO_ROOT/tests/run_phase_smoke.sh"

printf "[lifecycle] running prompt core smoke checks\n"
bash "$REPO_ROOT/tests/smoke_prompt_core.sh"

printf "[lifecycle] running prompt lifecycle integration checks\n"
bash "$REPO_ROOT/tests/integration/integration_prompt_lifecycle.sh"
