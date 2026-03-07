#!/usr/bin/env bash

cmd_apply_prompt() {
	if [[ "$#" -ne 3 ]]; then
		echo "usage: eaw apply-prompt <TRACK> <PHASE> <CANDIDATE>" >&2
		return 2
	fi

	local track="$1"
	local phase="$2"
	local candidate="$3"
	local version dir active_file tmp_file

	if ! version="$(normalize_prompt_candidate "$candidate")"; then
		echo "FAIL: invalid candidate '$candidate' (expected vN or N)" >&2
		return 1
	fi

	dir="$(prompt_phase_dir "$track" "$phase")"
	if [[ ! -d "$dir" ]]; then
		echo "FAIL: prompt phase directory does not exist: $dir" >&2
		return 1
	fi

	if cmd_validate_prompt "$track" "$phase" "$candidate"; then
		:
	else
		local rc=$?
		return "$rc"
	fi

	active_file="$dir/ACTIVE"
	tmp_file="$active_file.tmp.$$"

	printf "%s\n" "$version" >"$tmp_file"
	mv "$tmp_file" "$active_file"
	echo "PASS: apply-prompt $track/$phase/$version"
	return 0
}
