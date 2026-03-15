#!/usr/bin/env bash

cmd_analyze() {
	local card="${1:-}"
	local card_dir
	local test_plan

	if [[ "$card" == "--help" || "$card" == "-h" ]]; then
		usage
		return 0
	fi

	eaw_warn_compatibility_wrapper "analyze"
	card_dir="$EAW_OUT_DIR/$card"
	eaw_wrapper_materialize_until_phase "$card" "planning"

	test_plan="$card_dir/TEST_PLAN_${card}.md"
	if [[ ! -f "$test_plan" ]]; then
		assert_write_scope "analyze" "write test plan" "$test_plan" "$EAW_OUT_DIR"
		cat >"$test_plan" <<TP
# Test Plan for ${card}

## Summary

Describe deterministic tests to validate changes.

## Unit Tests

- Add tests for ...

## Integration Tests

- Run ...

TP
		echo "Wrote $test_plan"
	fi
}
