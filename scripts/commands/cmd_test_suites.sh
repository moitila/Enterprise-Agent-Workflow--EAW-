#!/usr/bin/env bash

cmd_smoke() {
	bash "$ROOT_DIR/tests/smoke/smoke_baseline.sh" "$@"
	bash "$ROOT_DIR/tests/smoke/context/smoke_context_none.sh"
	bash "$ROOT_DIR/tests/smoke/context/smoke_onboarding.sh"
	bash "$ROOT_DIR/tests/smoke/context/smoke_dynamic.sh"
	bash "$ROOT_DIR/tests/smoke/context/smoke_truncation.sh"
	bash "$ROOT_DIR/tests/smoke/context/smoke_bootstrap.sh"
}

cmd_test() {
	bash "$ROOT_DIR/tests/test.sh" "$@"
}
