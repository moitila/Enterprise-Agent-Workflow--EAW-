#!/usr/bin/env bash

cmd_implement() {
	local card="${1:-}"
	local card_dir

	if [[ -z "$card" ]]; then
		die "missing <CARD> argument"
	fi
	if [[ "$card" == "--help" || "$card" == "-h" ]]; then
		usage
		return 0
	fi
	if [[ ! "$card" =~ ^[A-Za-z0-9_-]+$ ]]; then
		die "invalid <CARD> '$card' (expected [A-Za-z0-9_-]+)"
	fi

	card_dir="$EAW_OUT_DIR/$card"
	if [[ ! -d "$card_dir" ]]; then
		die "card output directory not found: $card_dir"
	fi

	eaw_warn_compatibility_wrapper "implement"
	eaw_wrapper_materialize_until_phase "$card" "implementation_executor"
}
