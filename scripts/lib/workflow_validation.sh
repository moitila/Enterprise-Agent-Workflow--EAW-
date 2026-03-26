#!/usr/bin/env bash

eaw_validate_workflow_usage() {
	cat <<'EOF'
usage: eaw validate workflow [--track <track_id> | --all]
EOF
}

eaw_validate_workflow_error() {
	local track_id="$1"
	local phase_id="$2"
	local field="$3"
	local message="$4"
	printf "ERROR track=%s" "$track_id" >&2
	if [[ -n "$phase_id" ]]; then
		printf " phase=%s" "$phase_id" >&2
	fi
	if [[ -n "$field" ]]; then
		printf " field=%s" "$field" >&2
	fi
	printf " message=%s\n" "$message" >&2
}

eaw_validate_workflow_phase_outputs() {
	local track_id="$1"
	local phase_id="$2"
	local phase_file="$3"
	local issue
	local errors=0

	while IFS= read -r issue; do
		[[ -n "$issue" ]] || continue
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "$phase_id" "outputs" "$issue"
	done < <(
		awk '
			function ltrim(s) {
				sub(/^[[:space:]]+/, "", s)
				return s
			}
			/^phase:[[:space:]]*$/ { in_phase=1; next }
			in_phase && /^[^[:space:]]/ { in_phase=0; in_outputs=0; current="" }
			in_phase && /^  outputs:[[:space:]]*$/ { in_outputs=1; current=""; next }
			in_outputs && /^  [^[:space:]]/ { in_outputs=0; current="" }
			!in_outputs { next }
			/^[[:space:]]*$/ { next }
			/^    [A-Za-z0-9_-]+:[[:space:]]*$/ {
				line=$0
				sub(/^    /, "", line)
				sub(/:[[:space:]]*$/, "", line)
				current=line
				if (current != "create_directories" && current != "create_artifacts" && current != "prompts") {
					printf "unsupported outputs key '\''%s'\''\n", current
				}
				next
			}
			/^    [A-Za-z0-9_-]+:[[:space:]]*\[[[:space:]]*\][[:space:]]*$/ {
				line=$0
				sub(/^    /, "", line)
				sub(/:[[:space:]]*\[[[:space:]]*\][[:space:]]*$/, "", line)
				if (line != "create_directories" && line != "create_artifacts" && line != "prompts") {
					printf "unsupported outputs key '\''%s'\''\n", line
				}
				current=""
				next
			}
			/^    [A-Za-z0-9_-]+:[[:space:]]*\S/ {
				line=$0
				sub(/^    /, "", line)
				split(line, parts, ":")
				key=parts[1]
				if (key != "create_directories" && key != "create_artifacts" && key != "prompts") {
					printf "unsupported outputs key '\''%s'\''\n", key
				} else {
					printf "key '\''%s'\'' must be declared as list or []\n", key
				}
				current=""
				next
			}
			/^      - / {
				if (current == "") {
					printf "orphan list item under outputs: %s\n", ltrim($0)
				}
				next
			}
			{
				printf "invalid outputs line: %s\n", ltrim($0)
			}
		' "$phase_file"
	)

	return "$errors"
}

eaw_validate_workflow_phase_completion() {
	local track_id="$1"
	local phase_id="$2"
	local phase_file="$3"
	local strategy
	local errors=0

	strategy="$(eaw_yaml_phase_completion_strategy "$phase_file")"
	case "$strategy" in
	"" | required_artifacts_exist)
		:
		;;
	*)
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "$phase_id" "completion.strategy" "unknown strategy '$strategy'"
		;;
	esac

	return "$errors"
}

eaw_validate_workflow_phase_tooling_hints() {
	local track_id="$1"
	local phase_id="$2"
	local phase_file="$3"
	local issue
	local errors=0

	while IFS= read -r issue; do
		[[ -n "$issue" ]] || continue
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "$phase_id" "tooling_hints" "$issue"
	done < <(
		awk '
			function ltrim(s) {
				sub(/^[[:space:]]+/, "", s)
				return s
			}
			/^phase:[[:space:]]*$/ { in_phase=1; next }
			in_phase && /^[^[:space:]]/ { in_phase=0; in_hints=0; saw_header=0 }
			in_phase && /^  tooling_hints:[[:space:]]*$/ { in_hints=1; saw_header=1; next }
			in_phase && /^  tooling_hints:[[:space:]]*\[[[:space:]]*\][[:space:]]*$/ { saw_header=1; in_hints=0; next }
			in_phase && /^  tooling_hints:[[:space:]]*\S/ {
				saw_header=1
				in_hints=0
				printf "tooling_hints must be declared as list or []\n"
				next
			}
			in_hints && /^  [^[:space:]-]/ { in_hints=0 }
			!in_hints { next }
			/^[[:space:]]*$/ { next }
			/^    - .+/ { next }
			/^    -[[:space:]]*$/ {
				printf "tooling_hints entries must be non-empty strings\n"
				next
			}
			{
				printf "invalid tooling_hints line: %s\n", ltrim($0)
			}
		' "$phase_file"
	)

	return "$errors"
}

eaw_validate_workflow_track() {
	local track_id="$1"
	local track_dir track_file initial_phase final_phase raw_phase normalized_phase phase_file phase_id prompt_path phase_errors
	local raw_transition from_phase to_phase prompt_binding
	local errors=0
	local -a track_phase_list=()
	local -a phase_candidates=()
	local -A track_phase_set=()
	local -A phase_file_by_id=()
	local -A transition_map=()

	track_dir="$EAW_TRACKS_DIR/$track_id"
	if [[ -z "$track_id" || ! -d "$track_dir" ]]; then
		eaw_validate_workflow_error "$track_id" "" "track" "track directory not found"
		return 1
	fi

	track_file="$track_dir/track.yaml"
	if [[ ! -f "$track_file" ]]; then
		eaw_validate_workflow_error "$track_id" "" "track" "missing track.yaml"
		return 1
	fi

	track_id="$(eaw_yaml_track_scalar "$track_file" "id")"
	initial_phase="$(eaw_normalize_phase_id "$(eaw_yaml_track_scalar "$track_file" "initial_phase")")"
	final_phase="$(eaw_normalize_phase_id "$(eaw_yaml_track_scalar "$track_file" "final_phase")")"

	if [[ -z "$track_id" ]]; then
		errors=$((errors + 1))
		eaw_validate_workflow_error "<unknown>" "" "track.id" "missing track.id"
	fi

	while IFS= read -r raw_phase; do
		[[ -n "$raw_phase" ]] || continue
		normalized_phase="$(eaw_normalize_phase_id "$raw_phase")"
		if [[ -n "${track_phase_set[$normalized_phase]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$normalized_phase" "track.phases" "duplicate phase id '$normalized_phase'"
			continue
		fi
		track_phase_set["$normalized_phase"]=1
		track_phase_list+=("$normalized_phase")
	done < <(eaw_yaml_track_phases "$track_file")

	if [[ ${#track_phase_list[@]} -eq 0 ]]; then
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "" "track.phases" "track.phases is empty"
	fi
	if [[ -n "$initial_phase" && -z "${track_phase_set[$initial_phase]:-}" ]]; then
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "$initial_phase" "track.initial_phase" "initial phase is not listed in track.phases"
	fi
	if [[ -n "$final_phase" && -z "${track_phase_set[$final_phase]:-}" ]]; then
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "$final_phase" "track.final_phase" "final phase is not listed in track.phases"
	fi

	shopt -s nullglob
	phase_candidates=("$track_dir"/phases/*.yaml)
	shopt -u nullglob
	if [[ ${#phase_candidates[@]} -eq 0 ]]; then
		errors=$((errors + 1))
		eaw_validate_workflow_error "$track_id" "" "track.phases" "no phase files found in $track_dir/phases"
	fi

	for phase_file in "${phase_candidates[@]}"; do
		phase_id="$(eaw_normalize_phase_id "$(eaw_yaml_phase_scalar "$phase_file" "id")")"
		if [[ -z "$phase_id" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "${phase_file##*/}" "phase.id" "missing phase.id"
			continue
		fi
		if [[ -n "${phase_file_by_id[$phase_id]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$phase_id" "phase.id" "duplicate phase config file"
			continue
		fi
		phase_file_by_id["$phase_id"]="$phase_file"
		prompt_path="$(eaw_yaml_phase_prompt_path "$phase_file")"
		if [[ -z "$prompt_path" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$phase_id" "prompt.path" "missing prompt.path"
		elif ! prompt_binding="$(eaw_resolve_prompt_binding_from_path "$phase_file" "$prompt_path" 2>&1)"; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$phase_id" "prompt.path" "$prompt_binding"
		fi
		eaw_validate_workflow_phase_outputs "$track_id" "$phase_id" "$phase_file"
		phase_errors=$?
		if [[ "$phase_errors" -gt 0 ]]; then
			errors=$((errors + phase_errors))
		fi
		eaw_validate_workflow_phase_completion "$track_id" "$phase_id" "$phase_file"
		phase_errors=$?
		if [[ "$phase_errors" -gt 0 ]]; then
			errors=$((errors + phase_errors))
		fi
		eaw_validate_workflow_phase_tooling_hints "$track_id" "$phase_id" "$phase_file"
		phase_errors=$?
		if [[ "$phase_errors" -gt 0 ]]; then
			errors=$((errors + phase_errors))
		fi
	done

	for normalized_phase in "${track_phase_list[@]}"; do
		if [[ -z "${phase_file_by_id[$normalized_phase]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$normalized_phase" "track.phases" "phase file is missing"
		fi
	done

	while IFS= read -r raw_transition; do
		[[ -n "$raw_transition" ]] || continue
		IFS='|' read -r from_phase to_phase <<<"$raw_transition"
		from_phase="$(eaw_normalize_phase_id "$from_phase")"
		to_phase="$(eaw_normalize_phase_id "$to_phase")"
		if [[ -n "${transition_map[$from_phase]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$from_phase" "transitions" "duplicate transition source '$from_phase'"
			continue
		fi
		transition_map["$from_phase"]="$to_phase"
		if [[ -z "${track_phase_set[$from_phase]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$from_phase" "transitions" "source phase is not listed in track.phases"
		fi
		if [[ -z "${track_phase_set[$to_phase]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$from_phase" "transitions" "target phase '$to_phase' does not exist"
		fi
	done < <(eaw_yaml_track_transitions "$track_file")

	for normalized_phase in "${track_phase_list[@]}"; do
		if [[ "$normalized_phase" == "$final_phase" ]]; then
			if [[ -n "${transition_map[$normalized_phase]:-}" ]]; then
				errors=$((errors + 1))
				eaw_validate_workflow_error "$track_id" "$normalized_phase" "transitions" "final phase must not define next transition"
			fi
			continue
		fi
		if [[ -z "${transition_map[$normalized_phase]:-}" ]]; then
			errors=$((errors + 1))
			eaw_validate_workflow_error "$track_id" "$normalized_phase" "transitions" "missing transitions.<phase>.next"
		fi
	done

	if [[ "$errors" -eq 0 ]]; then
		printf "OK track=%s phases=%d\n" "$track_id" "${#track_phase_list[@]}"
		return 0
	fi

	return 1
}

eaw_validate_workflow_cli() {
	local mode="all"
	local track_id=""
	local errors=0
	local warnings=0
	local arg
	local -a track_ids=()

	while [[ $# -gt 0 ]]; do
		arg="$1"
		case "$arg" in
		--track)
			shift
			[[ $# -gt 0 ]] || {
				eaw_validate_workflow_usage >&2
				return 2
			}
			mode="track"
			track_id="$1"
			;;
		--all)
			mode="all"
			track_id=""
			;;
		--help | -h)
			eaw_validate_workflow_usage
			return 0
			;;
		*)
			eaw_validate_workflow_usage >&2
			return 2
			;;
		esac
		shift
	done

	echo "EAW validate workflow"
	echo "Resolved dirs:"
	echo "  EAW_ROOT_DIR=$EAW_ROOT_DIR"
	echo "  EAW_WORKDIR=${EAW_WORKDIR:-}"

	case "$mode" in
	track)
		track_ids=("$track_id")
		;;
	all)
		while IFS= read -r track_id; do
			[[ -n "$track_id" ]] || continue
			track_ids+=("$track_id")
		done < <(cmd_tracks)
		;;
	esac

	if [[ ${#track_ids[@]} -eq 0 ]]; then
		eaw_validate_workflow_error "<none>" "" "track" "no installed tracks found"
		return 2
	fi

	for track_id in "${track_ids[@]}"; do
		if ! eaw_validate_workflow_track "$track_id"; then
			errors=$((errors + 1))
		fi
	done

	echo "SUMMARY: errors=$errors warnings=$warnings"
	if [[ "$errors" -gt 0 ]]; then
		return 2
	fi
	return 0
}
