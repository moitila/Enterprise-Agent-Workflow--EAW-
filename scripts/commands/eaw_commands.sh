#!/usr/bin/env bash

eaw_normalize_phase_id() {
	local phase="${1:-}"
	case "$phase" in
	hypoteses)
		printf "hypotheses\n"
		;;
	planing)
		printf "planning\n"
		;;
	implement_planing)
		printf "implementation_planning\n"
		;;
	*)
		printf "%s\n" "$phase"
		;;
	esac
}

eaw_phase_prompt_phase() {
	local phase
	phase="$(eaw_normalize_phase_id "${1:-}")"
	case "$phase" in
	intake)
		printf "intake\n"
		;;
	findings)
		printf "analyze_findings\n"
		;;
	hypotheses)
		printf "analyze_hypotheses\n"
		;;
	planning)
		printf "analyze_planning\n"
		;;
	implementation_planning | implementation_executor)
		printf "%s\n" "$phase"
		;;
	*)
		return 1
		;;
	esac
}

eaw_yaml_trim() {
	local value="${1:-}"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%"${value##*[![:space:]]}"}"
	value="${value#\"}"
	value="${value%\"}"
	printf "%s\n" "$value"
}

eaw_yaml_track_scalar() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
		function trim(s) {
			sub(/^[[:space:]]+/, "", s)
			sub(/[[:space:]]+$/, "", s)
			sub(/^"/, "", s)
			sub(/"$/, "", s)
			return s
		}
		/^track:[[:space:]]*$/ { in_track=1; next }
		in_track && /^[^[:space:]]/ { in_track=0 }
		in_track && $0 ~ ("^  " key ":[[:space:]]*") {
			line=$0
			sub("^  " key ":[[:space:]]*", "", line)
			print trim(line)
			exit
		}
	' "$file"
}

eaw_yaml_phase_scalar() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
		function trim(s) {
			sub(/^[[:space:]]+/, "", s)
			sub(/[[:space:]]+$/, "", s)
			sub(/^"/, "", s)
			sub(/"$/, "", s)
			return s
		}
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0 }
		in_phase && $0 ~ ("^  " key ":[[:space:]]*") {
			line=$0
			sub("^  " key ":[[:space:]]*", "", line)
			print trim(line)
			exit
		}
	' "$file"
}

eaw_yaml_state_scalar() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
		function trim(s) {
			sub(/^[[:space:]]+/, "", s)
			sub(/[[:space:]]+$/, "", s)
			sub(/^"/, "", s)
			sub(/"$/, "", s)
			return s
		}
		/^card_state:[[:space:]]*$/ { in_state=1; next }
		in_state && /^[^[:space:]]/ { in_state=0 }
		in_state && $0 ~ ("^  " key ":[[:space:]]*") {
			line=$0
			sub("^  " key ":[[:space:]]*", "", line)
			print trim(line)
			exit
		}
	' "$file"
}

eaw_yaml_phase_prompt_path() {
	local file="$1"
	awk '
		function trim(s) {
			sub(/^[[:space:]]+/, "", s)
			sub(/[[:space:]]+$/, "", s)
			sub(/^"/, "", s)
			sub(/"$/, "", s)
			return s
		}
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0 }
		in_phase && /^  prompt:[[:space:]]*$/ { in_prompt=1; next }
		in_prompt && /^  [^[:space:]]/ { in_prompt=0 }
		in_prompt && /^    path:[[:space:]]*/ {
			line=$0
			sub(/^    path:[[:space:]]*/, "", line)
			print trim(line)
			exit
		}
	' "$file"
}

eaw_yaml_track_phases() {
	local file="$1"
	awk '
		/^track:[[:space:]]*$/ { in_track=1; next }
		in_track && /^[^[:space:]]/ { in_track=0 }
		in_track && /^  phases:[[:space:]]*$/ { in_phases=1; next }
		in_phases && /^  [^[:space:]-]/ { in_phases=0 }
		in_phases && /^[[:space:]]*$/ { next }
		in_phases && /^    - / {
			line=$0
			sub(/^    - /, "", line)
			print line
		}
	' "$file"
}

eaw_yaml_track_transitions() {
	local file="$1"
	awk '
		function trim(s) {
			sub(/^[[:space:]]+/, "", s)
			sub(/[[:space:]]+$/, "", s)
			return s
		}
		/^track:[[:space:]]*$/ { in_track=1; next }
		in_track && /^[^[:space:]]/ { in_track=0 }
		in_track && /^  transitions:[[:space:]]*$/ { in_transitions=1; next }
		in_transitions && /^  [^[:space:]]/ { in_transitions=0 }
		in_transitions && /^    [A-Za-z0-9_-]+:[[:space:]]*$/ {
			current=$0
			sub(/^    /, "", current)
			sub(/:[[:space:]]*$/, "", current)
			next
		}
		in_transitions && /^      next:[[:space:]]*/ {
			line=$0
			sub(/^      next:[[:space:]]*/, "", line)
			printf "%s|%s\n", trim(current), trim(line)
		}
	' "$file"
}

eaw_yaml_state_completed_phases() {
	local file="$1"
	awk '
		/^card_state:[[:space:]]*$/ { in_state=1; next }
		in_state && /^[^[:space:]]/ { in_state=0 }
		in_state && /^  completed_phases:[[:space:]]*\[[[:space:]]*\][[:space:]]*$/ { exit }
		in_state && /^  completed_phases:[[:space:]]*$/ { in_completed=1; next }
		in_completed && /^  [^[:space:]-]/ { in_completed=0 }
		in_completed && /^    - / {
			line=$0
			sub(/^    - /, "", line)
			print line
		}
	' "$file"
}

eaw_card_has_workflow_config() {
	local card_dir="$1"
	local intake_dir="$card_dir/intake"
	compgen -G "$intake_dir/track_*.yaml" >/dev/null || compgen -G "$intake_dir/state_card_*.yaml" >/dev/null || compgen -G "$intake_dir/phase_*.yaml" >/dev/null
}

eaw_load_card_workflow_context() {
	local card_dir="$1"
	local card_name="${card_dir##*/}"
	local intake_dir="$card_dir/intake"
	local errors=0
	local track_file state_file initial_phase final_phase track_id state_track_id current_phase previous_phase
	local current_phase_file current_prompt_phase current_prompt_path declared_prompt_phase next_phase
	local raw_phase normalized_phase phase_file phase_id prompt_phase prompt_path prompt_dir
	local raw_transition from_phase to_phase
	local -a track_phase_list=()
	local -a transition_list=()
	local -a completed_phase_list=()
	local -a track_candidates=()
	local -a state_candidates=()
	local -a phase_candidates=()
	local -A phase_file_by_id=()
	local -A track_phase_set=()
	local -A completed_phase_set=()
	local -A transition_map=()

	EAW_CARD_WORKFLOW_CARD_DIR="$card_dir"
	EAW_CARD_WORKFLOW_CARD="$card_name"
	EAW_CARD_WORKFLOW_TRACK_FILE=""
	EAW_CARD_WORKFLOW_STATE_FILE=""
	EAW_CARD_WORKFLOW_TRACK_ID=""
	EAW_CARD_WORKFLOW_INITIAL_PHASE=""
	EAW_CARD_WORKFLOW_FINAL_PHASE=""
	EAW_CARD_WORKFLOW_CURRENT_PHASE=""
	EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE=""
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_PHASE=""
	EAW_CARD_WORKFLOW_NEXT_PHASE=""

	shopt -s nullglob
	track_candidates=("$intake_dir"/track_*.yaml)
	state_candidates=("$intake_dir"/state_card_*.yaml)
	phase_candidates=("$intake_dir"/phase_*.yaml)
	shopt -u nullglob

	if [[ ${#track_candidates[@]} -eq 0 && ${#state_candidates[@]} -eq 0 && ${#phase_candidates[@]} -eq 0 ]]; then
		return 0
	fi

	if [[ ${#track_candidates[@]} -eq 0 ]]; then
		echo "ERROR: card ${card_name} has declarative workflow artifacts but is missing track_*.yaml in $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if [[ ${#state_candidates[@]} -eq 0 ]]; then
		echo "ERROR: card ${card_name} has declarative workflow artifacts but is missing state_card_*.yaml in $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if [[ ${#phase_candidates[@]} -eq 0 ]]; then
		echo "ERROR: card ${card_name} has declarative workflow artifacts but is missing phase_*.yaml files in $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi

	if [[ ${#track_candidates[@]} -ne 1 ]]; then
		echo "ERROR: card ${card_name} must define exactly one track_*.yaml in $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if [[ ${#state_candidates[@]} -ne 1 ]]; then
		echo "ERROR: card ${card_name} must define exactly one state_card_*.yaml in $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if [[ ${#phase_candidates[@]} -eq 0 ]]; then
		echo "ERROR: card ${card_name} must define at least one phase_*.yaml in $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi

	track_file="${track_candidates[0]}"
	state_file="${state_candidates[0]}"
	EAW_CARD_WORKFLOW_TRACK_FILE="$track_file"
	EAW_CARD_WORKFLOW_STATE_FILE="$state_file"

	track_id="$(eaw_yaml_track_scalar "$track_file" "id")"
	initial_phase="$(eaw_normalize_phase_id "$(eaw_yaml_track_scalar "$track_file" "initial_phase")")"
	final_phase="$(eaw_normalize_phase_id "$(eaw_yaml_track_scalar "$track_file" "final_phase")")"
	state_track_id="$(eaw_yaml_state_scalar "$state_file" "track_id")"
	current_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$state_file" "current_phase")")"
	previous_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$state_file" "previous_phase")")"

	if [[ -z "$track_id" ]]; then
		echo "ERROR: card ${card_name} track file missing required field track.id: $track_file" >&2
		errors=$((errors + 1))
	fi
	if [[ -z "$initial_phase" ]]; then
		echo "ERROR: card ${card_name} track file missing required field track.initial_phase: $track_file" >&2
		errors=$((errors + 1))
	fi
	if [[ -z "$final_phase" ]]; then
		echo "ERROR: card ${card_name} track file missing required field track.final_phase: $track_file" >&2
		errors=$((errors + 1))
	fi
	if [[ -z "$state_track_id" ]]; then
		echo "ERROR: card ${card_name} state file missing required field card_state.track_id: $state_file" >&2
		errors=$((errors + 1))
	fi
	if [[ -z "$current_phase" ]]; then
		echo "ERROR: card ${card_name} state file missing required field card_state.current_phase: $state_file" >&2
		errors=$((errors + 1))
	fi

	while IFS= read -r raw_phase; do
		[[ -n "$raw_phase" ]] || continue
		normalized_phase="$(eaw_normalize_phase_id "$raw_phase")"
		if [[ -n "${track_phase_set[$normalized_phase]:-}" ]]; then
			echo "ERROR: duplicate phase '$normalized_phase' in track.phases for card ${card_name} (MVP requires canonical YAML structure)" >&2
			errors=$((errors + 1))
		fi
		track_phase_list+=("$normalized_phase")
		track_phase_set["$normalized_phase"]=1
	done < <(eaw_yaml_track_phases "$track_file")
	if [[ ${#track_phase_list[@]} -eq 0 ]]; then
		echo "ERROR: card ${card_name} track file must list track.phases using canonical YAML structure: $track_file" >&2
		errors=$((errors + 1))
	fi

	for phase_file in "${phase_candidates[@]}"; do
		phase_id="$(eaw_normalize_phase_id "$(eaw_yaml_phase_scalar "$phase_file" "id")")"
		if [[ -z "$phase_id" ]]; then
			echo "ERROR: phase file missing required field phase.id: $phase_file" >&2
			errors=$((errors + 1))
			continue
		fi
		if [[ -n "${phase_file_by_id[$phase_id]:-}" ]]; then
			echo "ERROR: duplicate phase.id '$phase_id' across phase files: ${phase_file_by_id[$phase_id]} and $phase_file" >&2
			errors=$((errors + 1))
			continue
		fi
		phase_file_by_id["$phase_id"]="$phase_file"

		prompt_path="$(eaw_yaml_phase_prompt_path "$phase_file")"
		if [[ -z "$prompt_path" ]]; then
			echo "ERROR: phase '$phase_id' missing prompt.path in $phase_file (MVP requires canonical YAML structure)" >&2
			errors=$((errors + 1))
			continue
		fi
		prompt_dir="$(printf "%s\n" "$prompt_path" | awk -F/ '{ print $(NF-1) }')"
		declared_prompt_phase="$(eaw_normalize_phase_id "$prompt_dir")"
		if [[ "$declared_prompt_phase" != "$phase_id" ]]; then
			echo "ERROR: phase '$phase_id' has prompt.path phase '$prompt_dir' inconsistent with phase.id in $phase_file; prompt.path is a declarative contract and must use canonical YAML naming" >&2
			errors=$((errors + 1))
		fi
		if ! prompt_phase="$(eaw_phase_prompt_phase "$phase_id")"; then
			echo "ERROR: phase '$phase_id' has no unique official prompt mapping" >&2
			errors=$((errors + 1))
			continue
		fi
		if ! prompt_resolve_active_metadata "default" "$prompt_phase" >/dev/null; then
			echo "ERROR: phase '$phase_id' official prompt '$prompt_phase' is not resolvable" >&2
			errors=$((errors + 1))
		fi
	done

	for normalized_phase in "${track_phase_list[@]}"; do
		if [[ -z "${phase_file_by_id[$normalized_phase]:-}" ]]; then
			echo "ERROR: track phase '$normalized_phase' has no matching phase config file in $intake_dir" >&2
			errors=$((errors + 1))
		fi
	done

	if [[ -n "$initial_phase" && -z "${track_phase_set[$initial_phase]:-}" ]]; then
		echo "ERROR: track.initial_phase '$initial_phase' is not listed in track.phases for card ${card_name}" >&2
		errors=$((errors + 1))
	fi
	if [[ -n "$final_phase" && -z "${track_phase_set[$final_phase]:-}" ]]; then
		echo "ERROR: track.final_phase '$final_phase' is not listed in track.phases for card ${card_name}" >&2
		errors=$((errors + 1))
	fi
	if [[ -n "$track_id" && -n "$state_track_id" && "$track_id" != "$state_track_id" ]]; then
		echo "ERROR: card_state.track_id '$state_track_id' does not match track.id '$track_id' for card ${card_name}" >&2
		errors=$((errors + 1))
	fi
	if [[ -n "$current_phase" && -z "${track_phase_set[$current_phase]:-}" ]]; then
		echo "ERROR: card_state.current_phase '$current_phase' is not listed in track.phases for card ${card_name}" >&2
		errors=$((errors + 1))
	fi
	if [[ -n "$previous_phase" && "$previous_phase" != "null" && -z "${track_phase_set[$previous_phase]:-}" ]]; then
		echo "ERROR: card_state.previous_phase '$previous_phase' is not listed in track.phases for card ${card_name}" >&2
		errors=$((errors + 1))
	fi

	while IFS= read -r raw_transition; do
		[[ -n "$raw_transition" ]] || continue
		transition_list+=("$raw_transition")
		IFS='|' read -r from_phase to_phase <<<"$raw_transition"
		from_phase="$(eaw_normalize_phase_id "$from_phase")"
		to_phase="$(eaw_normalize_phase_id "$to_phase")"
		if [[ -n "${transition_map[$from_phase]:-}" ]]; then
			echo "ERROR: duplicate transition source '$from_phase' in track.transitions for card ${card_name} (MVP requires deterministic canonical YAML structure)" >&2
			errors=$((errors + 1))
		fi
		transition_map["$from_phase"]="$to_phase"
		if [[ -z "${track_phase_set[$from_phase]:-}" ]]; then
			echo "ERROR: track transition source '$from_phase' is not listed in track.phases for card ${card_name}" >&2
			errors=$((errors + 1))
		fi
		if [[ -z "${track_phase_set[$to_phase]:-}" ]]; then
			echo "ERROR: track transition target '$to_phase' is not listed in track.phases for card ${card_name}" >&2
			errors=$((errors + 1))
		fi
	done < <(eaw_yaml_track_transitions "$track_file")

	for normalized_phase in "${track_phase_list[@]}"; do
		if [[ "$normalized_phase" == "$final_phase" ]]; then
			if [[ -n "${transition_map[$normalized_phase]:-}" ]]; then
				echo "ERROR: final_phase '$final_phase' must not define next transition in $track_file" >&2
				errors=$((errors + 1))
			fi
			continue
		fi
		if [[ -z "${transition_map[$normalized_phase]:-}" ]]; then
			echo "ERROR: track phase '$normalized_phase' is missing transitions.<phase>.next in $track_file" >&2
			errors=$((errors + 1))
		fi
	done

	while IFS= read -r raw_phase; do
		[[ -n "$raw_phase" ]] || continue
		normalized_phase="$(eaw_normalize_phase_id "$raw_phase")"
		if [[ -n "${completed_phase_set[$normalized_phase]:-}" ]]; then
			echo "ERROR: duplicate phase '$normalized_phase' in card_state.completed_phases for card ${card_name} (MVP requires deterministic canonical YAML structure)" >&2
			errors=$((errors + 1))
		fi
		completed_phase_set["$normalized_phase"]=1
		if [[ -z "${track_phase_set[$normalized_phase]:-}" ]]; then
			echo "ERROR: card_state.completed_phases contains unknown phase '$normalized_phase' for card ${card_name}" >&2
			errors=$((errors + 1))
		fi
		completed_phase_list+=("$normalized_phase")
	done < <(eaw_yaml_state_completed_phases "$state_file")

	current_phase_file="${phase_file_by_id[$current_phase]:-}"
	if [[ -n "$current_phase" && -z "$current_phase_file" ]]; then
		echo "ERROR: current phase '$current_phase' has no matching phase config file in $intake_dir" >&2
		errors=$((errors + 1))
	fi

	if [[ "$errors" -gt 0 ]]; then
		return 1
	fi

	current_prompt_phase="$(eaw_phase_prompt_phase "$current_phase")"
	current_prompt_path="$(eaw_yaml_phase_prompt_path "$current_phase_file")"
	if [[ "$current_phase" == "$final_phase" ]]; then
		next_phase=""
	else
		next_phase="${transition_map[$current_phase]:-}"
		if [[ -z "$next_phase" ]]; then
			echo "ERROR: current phase '$current_phase' has no declarative next transition in $track_file" >&2
			return 1
		fi
	fi

	EAW_CARD_WORKFLOW_TRACK_ID="$track_id"
	EAW_CARD_WORKFLOW_INITIAL_PHASE="$initial_phase"
	EAW_CARD_WORKFLOW_FINAL_PHASE="$final_phase"
	EAW_CARD_WORKFLOW_CURRENT_PHASE="$current_phase"
	EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE="$current_phase_file"
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_PHASE="$current_prompt_phase"
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_PATH="$current_prompt_path"
	EAW_CARD_WORKFLOW_NEXT_PHASE="$next_phase"
	return 0
}

phase_load_workflow_context() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"

	if ! eaw_card_has_workflow_config "$card_dir"; then
		echo "RUNTIME: workflow config not present for card=$card; using legacy lifecycle"
		return 0
	fi
	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	echo "RUNTIME: loaded track id=$EAW_CARD_WORKFLOW_TRACK_ID file=$EAW_CARD_WORKFLOW_TRACK_FILE"
	echo "RUNTIME: loaded state file=$EAW_CARD_WORKFLOW_STATE_FILE current_phase=$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	echo "RUNTIME: loaded phase file=$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE prompt_phase=$EAW_CARD_WORKFLOW_CURRENT_PROMPT_PHASE prompt_path=$EAW_CARD_WORKFLOW_CURRENT_PROMPT_PATH"
	return 0
}

phase_resolve_workflow_transition() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"

	if ! eaw_card_has_workflow_config "$card_dir"; then
		echo "RUNTIME: workflow transition skipped for card=$card; legacy lifecycle"
		return 0
	fi
	if [[ -z "${EAW_CARD_WORKFLOW_TRACK_ID:-}" ]]; then
		if ! eaw_load_card_workflow_context "$card_dir"; then
			return 1
		fi
	fi

	if [[ "$EAW_CARD_WORKFLOW_CURRENT_PHASE" == "$EAW_CARD_WORKFLOW_FINAL_PHASE" ]]; then
		echo "RUNTIME: next_phase=<none> final_phase=$EAW_CARD_WORKFLOW_FINAL_PHASE status=complete"
	else
		echo "RUNTIME: next_phase=$EAW_CARD_WORKFLOW_NEXT_PHASE resolved_via=track.transitions current_phase=$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	fi
	return 0
}

cmd_card() {
	local type="$1"
	local card="$2"
	local title="$3"
	local outdir="$EAW_OUT_DIR/$card"
	# expose OUTDIR for run_phase and others
	OUTDIR="$outdir"
	ensure_dir "$outdir"

	# Preserve the lifecycle engine, but load declarative workflow context before
	# proceeding with the remaining phases so the runtime can validate state and
	# resolve the next track phase deterministically.
	run_phase "init_runtime" true phase_init_runtime "$type" "$card" "$title" "$outdir" || return 1
	run_phase "load_workflow_context" true phase_load_workflow_context "$card" || return 1
	run_phase "resolve_workflow_transition" true phase_resolve_workflow_transition "$card" || return 1
	run_phase "load_config" false phase_load_config "$outdir"
	run_phase "resolve_repos" false phase_resolve_repos
	run_phase "collect_context" false phase_collect_context "$card" "$outdir"
	run_phase "search_hits" false phase_search_hits "$outdir"
	run_phase "finalize" false phase_finalize "$card" "$outdir"
}
