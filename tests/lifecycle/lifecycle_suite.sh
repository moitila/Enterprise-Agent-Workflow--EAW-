#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

printf "[lifecycle] running phase lifecycle checks\n"
bash "$REPO_ROOT/tests/run_phase_smoke.sh"

printf "[lifecycle] running prompt core smoke checks\n"
bash "$REPO_ROOT/tests/smoke_prompt_core.sh"

printf "[lifecycle] running prompt lifecycle integration checks\n"
bash "$REPO_ROOT/tests/integration/integration_prompt_lifecycle.sh"

printf "[lifecycle] running workflow prompt.path smoke checks\n"
bash "$REPO_ROOT/tests/workflow_prompt_path_smoke.sh"

printf "[lifecycle] running dedicated phase engine checks\n"
bash "$REPO_ROOT/tests/phase_engine_lifecycle.sh"

printf "[lifecycle] running workflow wrapper compatibility checks\n"
bash "$REPO_ROOT/tests/workflow_wrapper_compatibility.sh"
