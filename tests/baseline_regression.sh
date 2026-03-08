#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf "[baseline] running smoke suite\n"
env -u EAW_WORKDIR bash "$REPO_ROOT/tests/smoke/smoke_baseline.sh"

printf "[baseline] running integration suite\n"
bash "$REPO_ROOT/tests/integration/integration_suite.sh"

printf "[baseline] running lifecycle suite\n"
bash "$REPO_ROOT/tests/lifecycle/lifecycle_suite.sh"

printf "[baseline] running golden suite\n"
bash "$REPO_ROOT/tests/golden/golden_suite.sh"

printf "[baseline] baseline regression pack completed\n"
