#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf "[test] smoke scope\n"
bash "$REPO_ROOT/tests/smoke/smoke_baseline.sh"

printf "[test] integration scope\n"
bash "$REPO_ROOT/tests/integration/integration_suite.sh"

printf "[test] lifecycle scope\n"
bash "$REPO_ROOT/tests/lifecycle/lifecycle_suite.sh"

printf "[test] golden scope\n"
bash "$REPO_ROOT/tests/golden/golden_suite.sh"
