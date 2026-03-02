#!/usr/bin/env bash

cmd_validate_prompt() {
	if [[ "$#" -ne 3 ]]; then
		echo "usage: eaw validate-prompt <TRACK> <PHASE> <CANDIDATE>" >&2
		return 2
	fi

	local track="$1"
	local phase="$2"
	local candidate="$3"
	local version base dir md_file meta_file required forbidden meta_version item

	if ! version="$(normalize_prompt_candidate "$candidate")"; then
		echo "FAIL: invalid candidate '$candidate' (expected vN or N)" >&2
		return 1
	fi

	if ! base="$(prompt_candidate_base "$candidate")"; then
		echo "FAIL: invalid candidate '$candidate'" >&2
		return 1
	fi

	dir="$(prompt_phase_dir "$track" "$phase")"
	md_file="$dir/${base}.md"
	meta_file="$dir/${base}.meta"

	if [[ ! -f "$md_file" ]]; then
		echo "FAIL: missing markdown candidate: $md_file" >&2
		return 1
	fi
	if [[ ! -f "$meta_file" ]]; then
		echo "FAIL: missing metadata candidate: $meta_file" >&2
		return 1
	fi

	meta_version="$(prompt_meta_value "$meta_file" "version")"
	if [[ -z "$meta_version" ]]; then
		echo "FAIL: missing version in metadata: $meta_file" >&2
		return 1
	fi
	if [[ "$meta_version" != "$version" ]]; then
		echo "FAIL: metadata version '$meta_version' does not match candidate '$version'" >&2
		return 1
	fi

	required="$(prompt_meta_value "$meta_file" "required_substrings")"
	if [[ -z "$required" ]]; then
		echo "FAIL: missing required_substrings in metadata: $meta_file" >&2
		return 1
	fi

	IFS='|' read -r -a required_items <<<"$required"
	for item in "${required_items[@]}"; do
		item="$(trim_spaces "$item")"
		if [[ -z "$item" ]]; then
			echo "FAIL: empty required substring in metadata: $meta_file" >&2
			return 1
		fi
		if ! grep -Fq -- "$item" "$md_file"; then
			echo "FAIL: required substring not found: $item" >&2
			return 1
		fi
	done

	forbidden="$(prompt_meta_value "$meta_file" "forbidden_words")"
	if [[ -n "$forbidden" ]]; then
		IFS='|' read -r -a forbidden_items <<<"$forbidden"
		for item in "${forbidden_items[@]}"; do
			item="$(trim_spaces "$item")"
			if [[ -z "$item" ]]; then
				continue
			fi
			if grep -Fq -- "$item" "$md_file"; then
				echo "FAIL: forbidden word found: $item" >&2
				return 1
			fi
		done
	fi

	echo "PASS: validate-prompt $track/$phase/$version"
	return 0
}
