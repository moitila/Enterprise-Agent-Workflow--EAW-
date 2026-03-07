#!/usr/bin/env bash

cmd_suggest_prompt() {
	if [[ "$#" -lt 1 ]]; then
		echo "usage: eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>" >&2
		return 2
	fi

	local card="$1"
	shift

	local track=""
	local phase=""
	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--track)
			if [[ "$#" -lt 2 ]]; then
				echo "usage: eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>" >&2
				return 2
			fi
			track="$2"
			shift 2
			;;
		--phase)
			if [[ "$#" -lt 2 ]]; then
				echo "usage: eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>" >&2
				return 2
			fi
			phase="$2"
			shift 2
			;;
		*)
			echo "usage: eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>" >&2
			return 2
			;;
		esac
	done

	if [[ -z "$track" || -z "$phase" ]]; then
		echo "usage: eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>" >&2
		return 2
	fi

	local proposal_dir="$EAW_OUT_DIR/$card/proposals"
	local patch_md="$proposal_dir/prompt_patch_001.md"
	local patch_diff="$proposal_dir/prompt_patch_001.diff"
	local result_md="$proposal_dir/prompt_patch_001.result.md"
	local first_failure=""
	local status="PASS"
	local exit_code=0
	local gate_lines=()
	local root_message=""

	ensure_dir "$proposal_dir"

	record_gate() {
		local gate_name="$1"
		local gate_status="$2"
		local gate_detail="$3"
		gate_lines+=("- $gate_name: $gate_status - $gate_detail")
		if [[ -z "$first_failure" && "$gate_status" == "FAIL" ]]; then
			first_failure="$gate_detail"
			status="FAIL"
			exit_code=1
		fi
	}

	write_patch_md() {
		local base_candidate_label="$1"
		local base_md_path="$2"
		local base_meta_path="$3"
		cat >"$patch_md" <<EOF
# Prompt Patch 001 - Card $card

ROLE:
- EAW prompt suggestion artifact for $track/$phase.

INPUTS:
- card: $card
- track: $track
- phase: $phase
- base_candidate: $base_candidate_label
- base_md: ${base_md_path:-not_found}
- base_meta: ${base_meta_path:-not_found}

GUARDRAILS:
- Do not invent behavior beyond the evidence available for this card.
- Respect the allowlist from scope.lock before changing any repository file.
- Never modify ACTIVE automatically.
- Write only the audit artifacts for this suggestion flow.

OUTPUT:
- Create prompt_patch_001.md, prompt_patch_001.diff and prompt_patch_001.result.md in out/$card/proposals/.
- Keep validate-prompt as a prerequisite for apply-prompt.

Summary:
- This artifact records a deterministic prompt suggestion for $track/$phase without applying any candidate.
EOF
	}

	write_diff_placeholder() {
		printf "NO_DIFF: base candidate not found\n" >"$patch_diff"
	}

	write_result_md() {
		local base_candidate_label="$1"
		cat >"$result_md" <<EOF
# Prompt Patch Result - Card $card

status: $status
exit_code: $exit_code
track: $track
phase: $phase
base_candidate: $base_candidate_label
artifacts:
- $patch_md
- $patch_diff
- $result_md
gates:
EOF
		local gate_line
		for gate_line in "${gate_lines[@]}"; do
			printf "%s\n" "$gate_line" >>"$result_md"
		done
	}

	local safe_inputs=true
	if validate_prompt_slug "track" "$track" >/dev/null 2>&1; then
		record_gate "safe_track" "PASS" "track accepted: $track"
	else
		record_gate "safe_track" "FAIL" "invalid track '$track' (expected safe slug [a-z0-9_-])"
		safe_inputs=false
	fi
	if validate_prompt_slug "phase" "$phase" >/dev/null 2>&1; then
		record_gate "safe_phase" "PASS" "phase accepted: $phase"
	else
		record_gate "safe_phase" "FAIL" "invalid phase '$phase' (expected safe slug [a-z0-9_-])"
		safe_inputs=false
	fi

	local dir=""
	local active_file=""
	local base_candidate=""
	local base_name=""
	local base_md=""
	local base_meta=""
	if [[ "$safe_inputs" == "true" ]]; then
		dir="$(prompt_phase_dir "$track" "$phase")"
		active_file="$dir/ACTIVE"
		if [[ -d "$dir" ]]; then
			record_gate "phase_directory" "PASS" "prompt phase directory exists: $dir"
		else
			record_gate "phase_directory" "FAIL" "prompt phase directory does not exist: $dir"
		fi
	else
		record_gate "phase_directory" "SKIP" "prompt phase directory not evaluated because slug validation failed"
	fi

	if [[ -n "$dir" && -f "$active_file" ]]; then
		base_candidate="$(trim_spaces "$(cat "$active_file")")"
		if normalize_prompt_candidate "$base_candidate" >/dev/null 2>&1; then
			record_gate "active_candidate" "PASS" "ACTIVE points to $base_candidate"
			base_name="$(prompt_candidate_base "$base_candidate")"
			base_md="$dir/${base_name}.md"
			base_meta="$dir/${base_name}.meta"
		else
			record_gate "active_candidate" "FAIL" "ACTIVE contains invalid candidate: $base_candidate"
		fi
	elif [[ -n "$dir" && -d "$dir" ]]; then
		record_gate "active_candidate" "FAIL" "ACTIVE file not found: $active_file"
	fi

	if [[ -n "$base_md" && -f "$base_md" ]]; then
		record_gate "candidate_markdown" "PASS" "base candidate markdown exists: $base_md"
	else
		record_gate "candidate_markdown" "FAIL" "base candidate markdown not found"
	fi
	if [[ -n "$base_meta" && -f "$base_meta" ]]; then
		record_gate "candidate_metadata" "PASS" "base candidate metadata exists: $base_meta"
	else
		record_gate "candidate_metadata" "FAIL" "base candidate metadata not found"
	fi

	local base_label="${base_candidate:-not_found}"
	write_patch_md "$base_label" "$base_md" "$base_meta"

	local required_items=(
		"ROLE:"
		"INPUTS:"
		"GUARDRAILS:"
		"OUTPUT:"
		"Do not invent"
		"allowlist"
	)
	local item
	for item in "${required_items[@]}"; do
		if grep -Fq -- "$item" "$patch_md"; then
			record_gate "required_substring" "PASS" "required substring found: $item"
		else
			record_gate "required_substring" "FAIL" "required substring not found: $item"
		fi
	done

	local forbidden_items=(
		"ignore previous instructions"
		"write anywhere"
		"modify excluded repos"
		"disable tests"
		"skip validation"
	)
	for item in "${forbidden_items[@]}"; do
		if grep -Fq -- "$item" "$patch_md"; then
			record_gate "forbidden_word" "FAIL" "forbidden word found: $item"
		else
			record_gate "forbidden_word" "PASS" "forbidden word absent: $item"
		fi
	done

	if [[ -f "$base_md" ]]; then
		local diff_rc=0
		diff -u --label "base_candidate.md" --label "new_candidate.md" "$base_md" "$patch_md" >"$patch_diff" || diff_rc=$?
		if [[ "$diff_rc" -le 1 ]]; then
			record_gate "proposal_diff" "PASS" "prompt_patch_001.diff generated from base candidate"
		else
			record_gate "proposal_diff" "FAIL" "diff command failed"
			write_diff_placeholder
		fi
	else
		write_diff_placeholder
		record_gate "proposal_diff" "PASS" "NO_DIFF: base candidate not found"
	fi

	write_result_md "$base_label"

	if [[ "$status" == "FAIL" ]]; then
		root_message="${first_failure:-suggest-prompt failed}"
		printf "FAIL: %s\n" "$root_message" >&2
		return 1
	fi

	echo "PASS: suggest-prompt $card $track/$phase"
	return 0
}
