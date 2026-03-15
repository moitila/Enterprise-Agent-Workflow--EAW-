#!/usr/bin/env bash

cmd_intake() {
	local card="${1:-}"
	local round_arg="${2:-}"
	local round="1"

	if [[ "$card" == "--help" || "$card" == "-h" ]]; then
		usage
		return 0
	fi

	if [[ -n "$round_arg" ]]; then
		if [[ "$round_arg" =~ ^--round=([0-9]+)$ ]]; then
			round="${BASH_REMATCH[1]}"
		else
			die "usage: eaw intake <CARD> [--round=N]"
		fi
	fi

	eaw_warn_compatibility_wrapper "intake"
	EAW_PHASE_PROMPT_ROUND="$round" eaw_wrapper_materialize_until_phase "$card" "intake"
}
