#!/usr/bin/env bash

cmd_smoke() {
	bash "$ROOT_DIR/tests/smoke/smoke_baseline.sh" "$@"
}

cmd_test() {
	bash "$ROOT_DIR/tests/test.sh" "$@"
}
