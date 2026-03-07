#!/usr/bin/env bash

prompt_is_known_section() {
	local section="$1"
	case "$section" in
	ROLE | OBJECTIVE | INPUT | OUTPUT | READ_SCOPE | WRITE_SCOPE | FORBIDDEN | FAIL_CONDITIONS | RULES)
		return 0
		;;
	esac
	return 1
}

prompt_validate_structural_file() {
	local md_file="$1"
	local label="$2"
	local errors=0
	local section line upper keyword
	local unknown_section=""
	local unknown_has_critical="false"
	local -a required_sections=(
		"ROLE"
		"OBJECTIVE"
		"INPUT"
		"OUTPUT"
		"READ_SCOPE"
		"WRITE_SCOPE"
		"FORBIDDEN"
		"FAIL_CONDITIONS"
	)
	local -a critical_keywords=(
		"OVERRIDE"
		"BYPASS"
		"IGNORE"
		"DISABLE"
		"EXCEPTION"
		"EXECUTE"
		"RUN"
		"SHELL"
		"COMMAND"
		"SCRIPT"
		"WRITE_ANYWHERE"
		"READ_ANYWHERE"
		"TARGET_REPOS"
		"WORKSPACE"
		"ACTIVE_REPO"
		"ACTIVE_REPOS"
		"GLOBAL_WRITE"
		"GLOBAL_READ"
	)

	for section in "${required_sections[@]}"; do
		if ! grep -Eq "^${section}[[:space:]]*$" "$md_file"; then
			echo "ERROR: missing required section ${section} in ${label}" >&2
			errors=$((errors + 1))
		fi
	done

	while IFS= read -r line || [[ -n "$line" ]]; do
		line="${line%$'\r'}"
		if [[ "$line" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
			if [[ -n "$unknown_section" ]]; then
				if [[ "$unknown_has_critical" == "true" ]]; then
					echo "ERROR: unknown section '${unknown_section}' with critical keyword in ${label}" >&2
					errors=$((errors + 1))
				else
					echo "WARNING: unknown section '${unknown_section}' in ${label}"
				fi
			fi
			if prompt_is_known_section "$line"; then
				unknown_section=""
				unknown_has_critical="false"
			else
				unknown_section="$line"
				unknown_has_critical="false"
			fi
			continue
		fi

		if [[ -z "$unknown_section" ]]; then
			continue
		fi
		upper="${line^^}"
		for keyword in "${critical_keywords[@]}"; do
			if [[ "$upper" == *"$keyword"* ]]; then
				unknown_has_critical="true"
				break
			fi
		done
	done <"$md_file"

	if [[ -n "$unknown_section" ]]; then
		if [[ "$unknown_has_critical" == "true" ]]; then
			echo "ERROR: unknown section '${unknown_section}' with critical keyword in ${label}" >&2
			errors=$((errors + 1))
		else
			echo "WARNING: unknown section '${unknown_section}' in ${label}"
		fi
	fi

	if ((errors > 0)); then
		return 1
	fi
	echo "PASS: validate-prompt ${label}"
	return 0
}

cmd_validate_prompt_single() {
	local track="$1"
	local phase="$2"
	local candidate="$3"
	local version base dir md_file meta_file required forbidden meta_version item

	dir="$(prompt_phase_dir "$track" "$phase")"
	if [[ ! -d "$dir" ]]; then
		echo "ERROR: prompt directory not found for phase '$phase': $dir" >&2
		return 1
	fi

	if [[ "$candidate" == "latest" ]]; then
		if ! base="$(prompt_highest_candidate_base "$dir")"; then
			echo "ERROR: no prompt candidate found in $dir" >&2
			return 1
		fi
		version="${base#prompt_}"
	else
		if ! version="$(normalize_prompt_candidate "$candidate")"; then
			echo "FAIL: invalid candidate '$candidate' (expected vN, N or latest)" >&2
			return 1
		fi
		if ! base="$(prompt_candidate_base "$candidate")"; then
			echo "FAIL: invalid candidate '$candidate'" >&2
			return 1
		fi
	fi

	md_file="$dir/${base}.md"
	meta_file="$dir/${base}.meta"

	if [[ ! -f "$md_file" ]]; then
		echo "ERROR: missing markdown candidate: $md_file" >&2
		return 1
	fi
	if [[ ! -f "$meta_file" ]]; then
		echo "ERROR: missing metadata candidate: $meta_file" >&2
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
		if [[ "$item" == "RULES" ]]; then
			continue
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

	cmd_validate_prompt_label="${track}/${phase}/${version}"
	prompt_validate_structural_file "$md_file" "$cmd_validate_prompt_label"
}

cmd_prompt_validate_all() {
	local md_file rel
	local count=0
	local errors=0

	while IFS= read -r md_file; do
		[[ -z "$md_file" ]] && continue
		count=$((count + 1))
		rel="${md_file#${EAW_TEMPLATES_DIR}/}"
		if ! prompt_validate_structural_file "$md_file" "$rel"; then
			errors=$((errors + 1))
		fi
	done < <(prompt_list_markdown_candidates)

	if ((count == 0)); then
		echo "ERROR: no prompt_v*.md found under ${EAW_TEMPLATES_DIR}/prompts" >&2
		return 1
	fi
	if ((errors > 0)); then
		return 1
	fi
	return 0
}

cmd_validate_prompt() {
	if [[ "$#" -eq 3 ]]; then
		cmd_validate_prompt_single "$1" "$2" "$3"
		return $?
	fi
	if [[ "$#" -eq 0 ]]; then
		cmd_prompt_validate_all
		return $?
	fi
	echo "usage: eaw validate-prompt <TRACK> <PHASE> <CANDIDATE>" >&2
	echo "usage: eaw prompt validate" >&2
	return 2
}
