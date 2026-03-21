#!/usr/bin/env bash

EAW_COMMANDS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EAW_PHASE_COMPLETION_LIB="$EAW_COMMANDS_DIR/../lib/phase_completion.sh"
# shellcheck disable=SC1090
source "$EAW_PHASE_COMPLETION_LIB"

usage() {
	cat <<EOF
Usage: eaw init [--workdir <path>] [--force] [--upgrade]
Example:
  eaw init --workdir ./.eaw --upgrade
  eaw card <CARD> --track <TRACK> ["<TITLE>"]
  eaw next <CARD>
  eaw intake <CARD> [--round=N]   # deprecated compatibility wrapper; planned removal in v1.0
  eaw analyze <CARD>              # deprecated compatibility wrapper; planned removal in v1.0
  eaw implement <CARD>            # deprecated compatibility wrapper; planned removal in v1.0
  eaw tracks
  eaw tracks install
  eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>
  eaw prompt validate
  eaw validate-prompt <TRACK> <PHASE> <CANDIDATE>
  eaw propose-prompt <CARD> <TRACK> <PHASE> <BASE_CANDIDATE> <NEW_CANDIDATE>
  eaw apply-prompt <TRACK> <PHASE> <CANDIDATE>
  eaw validate
  eaw doctor
EOF
}

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

eaw_yaml_state_has_key() {
	local file="$1"
	local key="$2"
	awk -v key="$key" '
		/^card_state:[[:space:]]*$/ { in_state=1; next }
		in_state && /^[^[:space:]]/ { in_state=0 }
		in_state && $0 ~ ("^  " key ":[[:space:]]*") { found=1; exit }
		END { exit(found ? 0 : 1) }
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

eaw_yaml_phase_output_directories() {
	local file="$1"
	awk '
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_outputs=0; in_dirs=0 }
		in_phase && /^  outputs:[[:space:]]*$/ { in_outputs=1; next }
		in_outputs && /^  [^[:space:]]/ { in_outputs=0; in_dirs=0 }
		in_outputs && /^    create_directories:[[:space:]]*$/ { in_dirs=1; next }
		in_dirs && /^    [^[:space:]-]/ { in_dirs=0 }
		in_dirs && /^      - / {
			line=$0
			sub(/^      - /, "", line)
			print line
		}
	' "$file"
}

eaw_yaml_phase_output_artifacts() {
	local file="$1"
	awk '
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_outputs=0; in_artifacts=0 }
		in_phase && /^  outputs:[[:space:]]*$/ { in_outputs=1; next }
		in_outputs && /^  [^[:space:]]/ { in_outputs=0; in_artifacts=0 }
		in_outputs && /^    create_artifacts:[[:space:]]*$/ { in_artifacts=1; next }
		in_artifacts && /^    [^[:space:]-]/ { in_artifacts=0 }
		in_artifacts && /^      - / {
			line=$0
			sub(/^      - /, "", line)
			print line
		}
	' "$file"
}

eaw_yaml_phase_output_prompts() {
	local file="$1"
	awk '
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_outputs=0; in_prompts=0 }
		in_phase && /^  outputs:[[:space:]]*$/ { in_outputs=1; next }
		in_outputs && /^  [^[:space:]]/ { in_outputs=0; in_prompts=0 }
		in_outputs && /^    prompts:[[:space:]]*$/ { in_prompts=1; next }
		in_prompts && /^    [^[:space:]-]/ { in_prompts=0 }
		in_prompts && /^      - / {
			line=$0
			sub(/^      - /, "", line)
			print line
		}
	' "$file"
}

eaw_yaml_phase_tooling_hints() {
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
		in_phase && /^[^[:space:]]/ { in_phase=0; in_hints=0 }
		in_phase && /^  tooling_hints:[[:space:]]*$/ { in_hints=1; next }
		in_phase && /^  tooling_hints:[[:space:]]*\[[[:space:]]*\][[:space:]]*$/ { in_hints=0; next }
		in_hints && /^  [^[:space:]-]/ { in_hints=0 }
		in_hints && /^    - / {
			line=$0
			sub(/^    - /, "", line)
			print trim(line)
		}
	' "$file"
}

eaw_yaml_phase_completion_strategy() {
	eaw_phase_completion_strategy_name "$1"
}

eaw_yaml_phase_completion_required_artifacts() {
	eaw_phase_completion_required_artifacts "$1"
}

eaw_validate_phase_completion() {
	eaw_phase_completion_evaluate "$1" "$2" "$3" "$4"
}

eaw_validate_phase_completion_strict() {
	eaw_phase_completion_evaluate_strict "$1" "$2" "$3" "$4"
}

eaw_prompt_binding_from_path() {
	local prompt_path="${1:-}"
	local normalized_path remainder track raw_phase phase
	local -a segments=()

	normalized_path="${prompt_path#./}"
	case "$normalized_path" in
	templates/prompts/*)
		remainder="${normalized_path#templates/prompts/}"
		;;
	prompts/*)
		remainder="${normalized_path#prompts/}"
		;;
	*)
		return 1
		;;
	esac

	IFS='/' read -r -a segments <<<"$remainder"
	if [[ ${#segments[@]} -lt 2 ]]; then
		return 1
	fi

	if [[ ${#segments[@]} -ge 3 ]]; then
		track="${segments[0]}"
		raw_phase="${segments[1]}"
	else
		track="default"
		raw_phase="${segments[0]}"
	fi

	if [[ -z "$track" || -z "$raw_phase" ]]; then
		return 1
	fi

	phase="$(eaw_normalize_phase_id "$raw_phase")"
	printf "track=%s\n" "$track"
	printf "phase=%s\n" "$phase"
}

eaw_resolve_prompt_binding_from_path() {
	local phase_file="$1"
	local prompt_path="$2"
	local binding key value prompt_track="" prompt_phase=""

	if ! binding="$(eaw_prompt_binding_from_path "$prompt_path")"; then
		echo "ERROR: phase file '$phase_file' has invalid prompt.path '$prompt_path'; expected templates/prompts/<track>/<phase>/prompt_v*.md or prompts/<track>/<phase>/prompt_v*.md" >&2
		return 1
	fi

	while IFS='=' read -r key value; do
		case "$key" in
		track) prompt_track="$value" ;;
		phase) prompt_phase="$value" ;;
		esac
	done <<<"$binding"

	if [[ -z "$prompt_track" || -z "$prompt_phase" ]]; then
		echo "ERROR: phase file '$phase_file' has invalid prompt.path '$prompt_path'; could not derive track/phase binding" >&2
		return 1
	fi

	if ! prompt_resolve_active_metadata "$prompt_track" "$prompt_phase" >/dev/null; then
		echo "ERROR: phase file '$phase_file' has prompt.path '$prompt_path' that is not resolvable via ACTIVE" >&2
		return 1
	fi

	printf "track=%s\n" "$prompt_track"
	printf "phase=%s\n" "$prompt_phase"
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
	compgen -G "$card_dir/state_card_*.yaml" >/dev/null || compgen -G "$intake_dir/state_card_*.yaml" >/dev/null || compgen -G "$intake_dir/track_*.yaml" >/dev/null || compgen -G "$intake_dir/phase_*.yaml" >/dev/null
}

eaw_official_track_dir() {
	local track_id="${1:-}"
	local track_dir="$EAW_ROOT_DIR/tracks/$track_id"
	local tracks_registry="$EAW_ROOT_DIR/tracks.yaml"

	if [[ -z "$track_id" || ! -d "$track_dir" ]]; then
		return 1
	fi
	if [[ -f "$tracks_registry" ]] && ! awk -v id="$track_id" '/track_id:/ && $3 == id { found=1 } END { exit !found }' "$tracks_registry"; then
		return 1
	fi
	printf "%s\n" "$track_dir"
}

cmd_tracks() {
	local tracks_dir="$EAW_ROOT_DIR/tracks"
	local track_dir track_file track_id track_dir_name
	local -a track_ids=()
	local -a phase_candidates=()

	if [[ ! -d "$tracks_dir" ]]; then
		die "tracks directory not found: $tracks_dir"
	fi

	shopt -s nullglob
	for track_dir in "$tracks_dir"/*; do
		[[ -d "$track_dir" ]] || continue
		track_dir_name="${track_dir##*/}"
		track_file="$track_dir/track.yaml"
		if [[ ! -f "$track_file" ]]; then
			echo "ERROR: track '$track_dir_name' rejected: missing track.yaml" >&2
			continue
		fi

		phase_candidates=("$track_dir"/phases/*.yaml)
		if [[ ${#phase_candidates[@]} -eq 0 ]]; then
			echo "ERROR: track '$track_dir_name' rejected: no phase YAML files found in phases/" >&2
			continue
		fi

		track_id="$(eaw_yaml_track_scalar "$track_file" "id")"
		if [[ -z "$track_id" ]]; then
			echo "ERROR: track '$track_dir_name' rejected: missing track.id in track.yaml" >&2
			continue
		fi
		if [[ "$track_id" != "$track_dir_name" ]]; then
			echo "ERROR: track '$track_dir_name' rejected: track.id '$track_id' does not match directory name" >&2
			continue
		fi

		track_ids+=("$track_id")
	done
	shopt -u nullglob

	if [[ ${#track_ids[@]} -eq 0 ]]; then
		return 0
	fi

	printf '%s\n' "${track_ids[@]}" | LC_ALL=C sort -u
}

cmd_tracks_install() {
	local tracks_dir="$EAW_ROOT_DIR/tracks"
	local tracks_registry="$EAW_ROOT_DIR/tracks.yaml"
	local track_dir track_dir_name
	local -a discovered=()
	local -a valid_tracks=()
	local -a rejected_tracks=()

	if [[ ! -d "$tracks_dir" ]]; then
		die "tracks directory not found: $tracks_dir"
	fi

	shopt -s nullglob
	for track_dir in "$tracks_dir"/*; do
		[[ -d "$track_dir" ]] || continue
		discovered+=("${track_dir##*/}")
	done
	shopt -u nullglob

	printf "discovered: %d candidate(s)\n" "${#discovered[@]}"

	# Pre-register all candidates so eaw_official_track_dir resolves during validation.
	# Rejected candidates are removed from the registry after validation.
	{
		printf "tracks:\n"
		for track_dir_name in "${discovered[@]}"; do
			printf "  - track_id: %s\n" "$track_dir_name"
			printf "    status: candidate\n"
		done
	} >"$tracks_registry"

	for track_dir_name in "${discovered[@]}"; do
		if eaw_validate_workflow_track "$track_dir_name" >/dev/null 2>&1; then
			valid_tracks+=("$track_dir_name")
		else
			rejected_tracks+=("$track_dir_name")
			printf "REJECTED: %s\n" "$track_dir_name" >&2
			eaw_validate_workflow_track "$track_dir_name" 2>&1 | sed 's/^/  /' >&2 || true
		fi
	done

	{
		printf "tracks:\n"
		for track_dir_name in "${valid_tracks[@]}"; do
			printf "  - track_id: %s\n" "$track_dir_name"
			printf "    status: installed\n"
		done
	} >"$tracks_registry"

	printf "installed: %d\n" "${#valid_tracks[@]}"
	for track_dir_name in "${valid_tracks[@]}"; do
		printf "  - %s\n" "$track_dir_name"
	done
	if [[ ${#rejected_tracks[@]} -gt 0 ]]; then
		printf "rejected: %d\n" "${#rejected_tracks[@]}" >&2
		for track_dir_name in "${rejected_tracks[@]}"; do
			printf "  - %s\n" "$track_dir_name" >&2
		done
	fi
}

eaw_load_card_workflow_context() {
	local card_dir="$1"
	local card_name="${card_dir##*/}"
	local intake_dir="$card_dir/intake"
	local state_dir="$card_dir"
	local errors=0
	local track_file state_file initial_phase final_phase track_id state_track_id current_phase previous_phase phase_status
	local current_phase_file current_prompt_phase current_prompt_path current_prompt_track next_phase
	local raw_phase normalized_phase phase_file phase_id prompt_path prompt_binding prompt_track prompt_phase
	local raw_transition from_phase to_phase official_track_dir workflow_source
	local -a track_phase_list=()
	local -a transition_list=()
	local -a completed_phase_list=()
	local -a track_candidates=()
	local -a state_candidates=()
	local -a phase_candidates=()
	local -a official_phase_candidates=()
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
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_TRACK=""
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_PHASE=""
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_PATH=""
	EAW_CARD_WORKFLOW_NEXT_PHASE=""
	EAW_CARD_WORKFLOW_PHASE_STATUS=""
	EAW_CARD_WORKFLOW_PHASE_STATUS_EXPLICIT="false"
	EAW_CARD_WORKFLOW_SOURCE=""

	shopt -s nullglob
	track_candidates=("$intake_dir"/track_*.yaml)
	state_candidates=("$state_dir"/state_card_*.yaml)
	if [[ ${#state_candidates[@]} -eq 0 ]]; then
		state_candidates=("$intake_dir"/state_card_*.yaml)
	fi
	phase_candidates=("$intake_dir"/phase_*.yaml)
	shopt -u nullglob

	if [[ ${#track_candidates[@]} -eq 0 && ${#state_candidates[@]} -eq 0 && ${#phase_candidates[@]} -eq 0 ]]; then
		return 0
	fi

	if [[ ${#state_candidates[@]} -eq 0 ]]; then
		echo "ERROR: card ${card_name} has declarative workflow artifacts but is missing state_card_*.yaml in $state_dir or fallback $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if [[ ${#state_candidates[@]} -ne 1 ]]; then
		echo "ERROR: card ${card_name} must define exactly one state_card_*.yaml in $state_dir or fallback $intake_dir (MVP requires canonical YAML structure)" >&2
		return 1
	fi

	state_file="${state_candidates[0]}"
	EAW_CARD_WORKFLOW_STATE_FILE="$state_file"

	state_track_id="$(eaw_yaml_state_scalar "$state_file" "track_id")"
	current_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$state_file" "current_phase")")"
	previous_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$state_file" "previous_phase")")"
	phase_status="$(eaw_yaml_state_scalar "$state_file" "phase_status")"
	if eaw_yaml_state_has_key "$state_file" "phase_status"; then
		EAW_CARD_WORKFLOW_PHASE_STATUS_EXPLICIT="true"
	fi

	if [[ -z "$state_track_id" ]]; then
		echo "ERROR: card ${card_name} state file missing required field card_state.track_id: $state_file" >&2
		errors=$((errors + 1))
	fi
	if [[ -z "$current_phase" ]]; then
		echo "ERROR: card ${card_name} state file missing required field card_state.current_phase: $state_file" >&2
		errors=$((errors + 1))
	fi
	if [[ "$errors" -gt 0 ]]; then
		return 1
	fi

	if official_track_dir="$(eaw_official_track_dir "$state_track_id")"; then
		shopt -s nullglob
		official_phase_candidates=("$official_track_dir"/phases/*.yaml)
		shopt -u nullglob
		if [[ ! -f "$official_track_dir/track.yaml" ]]; then
			echo "ERROR: official track '${state_track_id}' is missing track.yaml in $official_track_dir" >&2
			return 1
		fi
		if [[ ${#official_phase_candidates[@]} -eq 0 ]]; then
			echo "ERROR: official track '${state_track_id}' is missing phase YAML files in $official_track_dir/phases" >&2
			return 1
		fi
		track_file="$official_track_dir/track.yaml"
		phase_candidates=("${official_phase_candidates[@]}")
		workflow_source="official"
	else
		if [[ ${#track_candidates[@]} -eq 0 ]]; then
			echo "ERROR: card ${card_name} has declarative workflow artifacts but is missing track_*.yaml in $intake_dir and no official track '${state_track_id}' was found in $EAW_ROOT_DIR/tracks" >&2
			return 1
		fi
		if [[ ${#phase_candidates[@]} -eq 0 ]]; then
			echo "ERROR: card ${card_name} has declarative workflow artifacts but is missing phase_*.yaml files in $intake_dir and no official track '${state_track_id}' was found in $EAW_ROOT_DIR/tracks" >&2
			return 1
		fi
		if [[ ${#track_candidates[@]} -ne 1 ]]; then
			echo "ERROR: card ${card_name} must define exactly one track_*.yaml in $intake_dir when no official track is installed" >&2
			return 1
		fi
		track_file="${track_candidates[0]}"
		workflow_source="legacy"
	fi

	EAW_CARD_WORKFLOW_TRACK_FILE="$track_file"
	track_id="$(eaw_yaml_track_scalar "$track_file" "id")"
	initial_phase="$(eaw_normalize_phase_id "$(eaw_yaml_track_scalar "$track_file" "initial_phase")")"
	final_phase="$(eaw_normalize_phase_id "$(eaw_yaml_track_scalar "$track_file" "final_phase")")"

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

		if ! prompt_binding="$(eaw_resolve_prompt_binding_from_path "$phase_file" "$prompt_path")"; then
			errors=$((errors + 1))
			continue
		fi
		prompt_phase=""
		while IFS='=' read -r key value; do
			case "$key" in
			phase) prompt_phase="$value" ;;
			esac
		done <<<"$prompt_binding"
		if [[ -z "$prompt_phase" ]]; then
			echo "ERROR: phase '$phase_id' has prompt.path '$prompt_path' but derived prompt phase is empty in $phase_file" >&2
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

	current_prompt_path="$(eaw_yaml_phase_prompt_path "$current_phase_file")"
	if ! prompt_binding="$(eaw_resolve_prompt_binding_from_path "$current_phase_file" "$current_prompt_path")"; then
		return 1
	fi
	current_prompt_track=""
	current_prompt_phase=""
	while IFS='=' read -r key value; do
		case "$key" in
		track) current_prompt_track="$value" ;;
		phase) current_prompt_phase="$value" ;;
		esac
	done <<<"$prompt_binding"
	if [[ -z "$current_prompt_track" || -z "$current_prompt_phase" ]]; then
		echo "ERROR: current phase '$current_phase' has prompt.path '$current_prompt_path' but derived prompt binding is incomplete in $current_phase_file" >&2
		return 1
	fi

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
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_TRACK="$current_prompt_track"
	EAW_CARD_WORKFLOW_CURRENT_PROMPT_PATH="$current_prompt_path"
	EAW_CARD_WORKFLOW_NEXT_PHASE="$next_phase"
	EAW_CARD_WORKFLOW_PHASE_STATUS="$phase_status"
	EAW_CARD_WORKFLOW_COMPLETED_PHASES="$(printf "%s\n" "${completed_phase_list[@]}")"
	EAW_CARD_WORKFLOW_SOURCE="$workflow_source"
	return 0
}

eaw_state_completed_phases_with_current() {
	local current_phase="$1"
	local raw_phase normalized_phase
	local -a completed_phase_list=()
	local -A completed_phase_set=()

	while IFS= read -r raw_phase; do
		[[ -n "$raw_phase" ]] || continue
		normalized_phase="$(eaw_normalize_phase_id "$raw_phase")"
		if [[ -n "${completed_phase_set[$normalized_phase]:-}" ]]; then
			continue
		fi
		completed_phase_set["$normalized_phase"]=1
		completed_phase_list+=("$normalized_phase")
	done <<<"${EAW_CARD_WORKFLOW_COMPLETED_PHASES:-}"

	if [[ -z "${completed_phase_set[$current_phase]:-}" ]]; then
		completed_phase_list+=("$current_phase")
	fi

	printf "%s\n" "${completed_phase_list[@]}"
}

eaw_state_scalar_or_default() {
	local state_file="$1"
	local key="$2"
	local default_value="$3"
	local value

	value="$(eaw_yaml_state_scalar "$state_file" "$key")"
	if [[ -n "$value" ]]; then
		printf "%s\n" "$value"
		return 0
	fi

	printf "%s\n" "$default_value"
}

eaw_render_state_yaml() {
	local state_file="$1"
	local previous_phase="$2"
	local current_phase="$3"
	local completed_phases="$4"
	local phase_status="$5"
	local phase_started_at="$6"
	local phase_completed="$7"
	local phase_completed_at="$8"

	awk \
		-v previous_phase="$previous_phase" \
		-v current_phase="$current_phase" \
		-v completed_phases="$completed_phases" \
		-v phase_status="$phase_status" \
		-v phase_started_at="$phase_started_at" \
		-v phase_completed="$phase_completed" \
		-v phase_completed_at="$phase_completed_at" '
		function emit_completed(    n, i, items) {
			if (completed_emitted) {
				return
			}
			completed_emitted = 1
			n = split(completed_phases, items, /\n/)
			if (n == 0 || (n == 1 && items[1] == "")) {
				print "  completed_phases: []"
				return
			}
			print "  completed_phases:"
			for (i = 1; i <= n; i++) {
				if (items[i] == "") {
					continue
				}
				print "    - " items[i]
			}
		}
		function emit_phase_status() {
			if (phase_status_emitted) {
				return
			}
			phase_status_emitted = 1
			print "  phase_status: " phase_status
		}
		function emit_phase_started_at() {
			if (phase_started_at_emitted) {
				return
			}
			phase_started_at_emitted = 1
			print "  phase_started_at: " phase_started_at
		}
		function emit_phase_completed() {
			if (phase_completed_emitted) {
				return
			}
			phase_completed_emitted = 1
			print "  phase_completed: " phase_completed
		}
		function emit_phase_completed_at() {
			if (phase_completed_at_emitted) {
				return
			}
			phase_completed_at_emitted = 1
			print "  phase_completed_at: " phase_completed_at
		}
		BEGIN {
			in_state = 0
			skip_completed = 0
			previous_seen = 0
			current_seen = 0
			phase_started_at_seen = 0
			phase_completed_seen = 0
			phase_completed_at_seen = 0
			phase_status_seen = 0
			phase_status_emitted = 0
			phase_started_at_emitted = 0
			phase_completed_emitted = 0
			phase_completed_at_emitted = 0
			completed_emitted = 0
		}
		/^card_state:[[:space:]]*$/ {
			in_state = 1
			print
			next
		}
		skip_completed {
			if ($0 ~ /^    - / || $0 ~ /^[[:space:]]*$/) {
				next
			}
			skip_completed = 0
		}
		in_state && /^[^[:space:]]/ {
			if (!previous_seen) {
				print "  previous_phase: " previous_phase
			}
			if (!current_seen) {
				print "  current_phase: " current_phase
			}
			if (!phase_started_at_seen) {
				emit_phase_started_at()
			}
			if (!phase_completed_seen) {
				emit_phase_completed()
			}
			if (!phase_completed_at_seen) {
				emit_phase_completed_at()
			}
			if (!phase_status_seen) {
				emit_phase_status()
			}
			emit_completed()
			in_state = 0
		}
		in_state && /^  previous_phase:[[:space:]]*/ {
			print "  previous_phase: " previous_phase
			previous_seen = 1
			next
		}
		in_state && /^  current_phase:[[:space:]]*/ {
			print "  current_phase: " current_phase
			current_seen = 1
			next
		}
		in_state && /^  phase_started_at:[[:space:]]*/ {
			emit_phase_started_at()
			phase_started_at_seen = 1
			next
		}
		in_state && /^  phase_completed:[[:space:]]*/ {
			emit_phase_completed()
			phase_completed_seen = 1
			next
		}
		in_state && /^  phase_completed_at:[[:space:]]*/ {
			emit_phase_completed_at()
			phase_completed_at_seen = 1
			next
		}
		in_state && /^  phase_status:[[:space:]]*/ {
			if (!phase_started_at_seen) {
				emit_phase_started_at()
			}
			if (!phase_completed_seen) {
				emit_phase_completed()
			}
			if (!phase_completed_at_seen) {
				emit_phase_completed_at()
			}
			emit_phase_status()
			phase_status_seen = 1
			next
		}
		in_state && /^  completed_phases:[[:space:]]*(\[[[:space:]]*\])?[[:space:]]*$/ {
			if (!phase_started_at_seen) {
				emit_phase_started_at()
			}
			if (!phase_completed_seen) {
				emit_phase_completed()
			}
			if (!phase_completed_at_seen) {
				emit_phase_completed_at()
			}
			if (!phase_status_seen) {
				emit_phase_status()
			}
			emit_completed()
			skip_completed = 1
			next
		}
		{
			print
		}
		END {
			if (in_state) {
				if (!previous_seen) {
					print "  previous_phase: " previous_phase
				}
				if (!current_seen) {
					print "  current_phase: " current_phase
				}
				if (!phase_started_at_seen) {
					emit_phase_started_at()
				}
				if (!phase_completed_seen) {
					emit_phase_completed()
				}
				if (!phase_completed_at_seen) {
					emit_phase_completed_at()
				}
				if (!phase_status_seen) {
					emit_phase_status()
				}
				emit_completed()
			}
		}
	' "$state_file"
}

eaw_state_phase_status_for_next() {
	if [[ "${EAW_CARD_WORKFLOW_PHASE_STATUS_EXPLICIT:-false}" == "true" ]]; then
		printf "%s\n" "${EAW_CARD_WORKFLOW_PHASE_STATUS:-}"
		return 0
	fi
	printf "LEGACY_UNSET\n"
}

eaw_card_template_type_for_track() {
	local track_id="${1:-}"
	if [[ -z "$track_id" ]] || ! eaw_official_track_dir "$track_id" >/dev/null 2>&1; then
		return 1
	fi
	printf "%s\n" "$track_id"
}

cmd_card_cli() {
	local card="${1:-}"
	shift || true

	if [[ -z "$card" ]]; then
		die "usage: eaw card <CARD> --track <TRACK> [\"<TITLE>\"]"
	fi

	local track=""
	local title=""
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--track)
			shift || true
			if [[ $# -eq 0 || -z "${1:-}" ]]; then
				die "usage: eaw card <CARD> --track <TRACK> [\"<TITLE>\"]"
			fi
			track="$1"
			;;
		--track=*)
			track="${1#--track=}"
			;;
		-h | --help)
			echo "usage: eaw card <CARD> --track <TRACK> [\"<TITLE>\"]"
			return 0
			;;
		*)
			if [[ -n "$title" ]]; then
				die "usage: eaw card <CARD> --track <TRACK> [\"<TITLE>\"]"
			fi
			title="$1"
			;;
		esac
		shift || true
	done

	if [[ -z "$track" ]]; then
		local tracks_registry="$EAW_ROOT_DIR/tracks.yaml"
		if [[ -f "$tracks_registry" ]]; then
			local -a registered_tracks=()
			while IFS= read -r _t; do
				[[ -n "$_t" ]] && registered_tracks+=("$_t")
			done < <(awk '/track_id:/ {print $2}' "$tracks_registry")
			if [[ ${#registered_tracks[@]} -eq 1 ]]; then
				track="${registered_tracks[0]}"
			elif [[ ${#registered_tracks[@]} -gt 1 ]]; then
				die "multiple tracks installed — specify with --track <TRACK>: $(printf '%s ' "${registered_tracks[@]}")"
			else
				die "no tracks installed — run 'eaw tracks install' first"
			fi
		else
			die "missing required argument: --track"
		fi
	fi
	if ! eaw_official_track_dir "$track" >/dev/null; then
		die "track '$track' is invalid or not installed"
	fi

	local template_type
	if ! template_type="$(eaw_card_template_type_for_track "$track")"; then
		die "track '$track' is unsupported for card creation"
	fi

	cmd_card "$template_type" "$card" "$title" "$track"
}

eaw_write_next_state() {
	local state_file="$1"
	local previous_phase="$2"
	local current_phase="$3"
	local completed_phases="$4"
	local phase_status="$5"
	local phase_started_at="$6"
	local phase_completed="$7"
	local phase_completed_at="$8"
	local tmp_file

	tmp_file="$(mktemp "${state_file}.tmp.XXXXXX")"
	eaw_render_state_yaml "$state_file" "$previous_phase" "$current_phase" "$completed_phases" "$phase_status" "$phase_started_at" "$phase_completed" "$phase_completed_at" >"$tmp_file"
	mv "$tmp_file" "$state_file"
}

eaw_write_phase_status() {
	local state_file="$1"
	local phase_status="$2"
	local previous_phase="$3"
	local current_phase="$4"
	local completed_phases="$5"
	local phase_started_at="$6"
	local phase_completed="$7"
	local phase_completed_at="$8"
	local tmp_file

	tmp_file="$(mktemp "${state_file}.tmp.XXXXXX")"
	eaw_render_state_yaml "$state_file" "$previous_phase" "$current_phase" "$completed_phases" "$phase_status" "$phase_started_at" "$phase_completed" "$phase_completed_at" >"$tmp_file"
	mv "$tmp_file" "$state_file"
}

eaw_render_phase_template_with_card() {
	local template_file="$1"
	local output_file="$2"
	local card="$3"

	sed "s/<CARD>/${card}/g" "$template_file" >"$output_file"
}

eaw_detect_card_template_type() {
	local card="$1"
	local card_dir="$2"
	local track_id
	local -a state_candidates=()

	shopt -s nullglob
	state_candidates=("$card_dir"/state_card_*.yaml)
	shopt -u nullglob

	if [[ ${#state_candidates[@]} -eq 1 ]]; then
		track_id="$(eaw_yaml_state_scalar "${state_candidates[0]}" "track_id")"
	fi

	printf "%s\n" "${track_id:-feature}"
}

eaw_card_markdown_list_after_label() {
	local file="$1"
	local label="$2"
	awk -v label="$label" '
		BEGIN { capture=0 }
		{
			line=$0
			gsub(/\r/, "", line)
			if (!capture && (line == label || line == label ":")) {
				capture=1
				next
			}
			if (capture) {
				if (line ~ /^- /) {
					seen_items=1
					print line
					next
				}
				if (line ~ /^[[:space:]]*$/) {
					if (seen_items) {
						exit
					}
					next
				}
				exit
			}
		}
	' "$file"
}

eaw_card_markdown_section_list() {
	local file="$1"
	local section="$2"
	awk -v section="$section" '
		function flush_and_exit() {
			if (seen_items) {
				exit
			}
		}
		{
			line=$0
			gsub(/\r/, "", line)
			if (!capture && line == section) {
				capture=1
				next
			}
			if (capture) {
				if (line ~ /^## /) {
					flush_and_exit()
					exit
				}
				if (line ~ /^- /) {
					seen_items=1
					print line
					next
				}
					if (line ~ /^[[:space:]]*$/) {
						if (seen_items) {
							next
						}
						next
					}
				if (seen_items) {
					exit
				}
			}
		}
	' "$file"
}

eaw_card_change_plan_involved_files() {
	local change_plan_file="$1"
	awk '
		/^   - \// {
			line=$0
			sub(/^   - /, "", line)
			print line
			next
		}
		/^   Validacao tecnica obrigatoria:/ {
			exit
		}
	' "$change_plan_file"
}

eaw_card_write_allowlist_entries() {
	local card_dir="$1"
	local scope_lock_file="$card_dir/implementation/00_scope.lock.md"
	local change_plan_file="$card_dir/implementation/10_change_plan.md"
	local card_allowlist_file=""
	local file
	local -a markdown_candidates=()

	if [[ -f "$scope_lock_file" ]]; then
		eaw_card_markdown_section_list "$scope_lock_file" "## Allowlist de Escrita" | sed '/^[[:space:]]*$/d'
		return 0
	fi

	shopt -s nullglob
	markdown_candidates=("$card_dir"/*.md "$card_dir"/intake/*.md)
	shopt -u nullglob
	for file in "${markdown_candidates[@]}"; do
		[[ -f "$file" ]] || continue
		if eaw_card_markdown_list_after_label "$file" "WRITE_ALLOWLIST" | grep -q '^- '; then
			card_allowlist_file="$file"
			break
		fi
	done
	if [[ -n "$card_allowlist_file" ]]; then
		eaw_card_markdown_list_after_label "$card_allowlist_file" "WRITE_ALLOWLIST" | sed '/^[[:space:]]*$/d'
		return 0
	fi

	if [[ -f "$change_plan_file" ]]; then
		eaw_card_change_plan_involved_files "$change_plan_file" | sed 's/^/- /'
		return 0
	fi

	printf -- "- %s\n" "$card_dir"
}

eaw_card_write_allowlist_block() {
	local card_dir="$1"
	local allowlist

	allowlist="$(eaw_card_write_allowlist_entries "$card_dir" | awk '!seen[$0]++')"
	if [[ -n "$allowlist" ]]; then
		printf "%s\n" "$allowlist"
		return 0
	fi

	printf -- "- %s\n" "$card_dir"
}

eaw_card_critical_paths_block() {
	local card_dir="$1"
	local -a critical_paths=()

	critical_paths+=("$EAW_ROOT_DIR/scripts/eaw")
	if [[ -n "${EAW_CARD_WORKFLOW_STATE_FILE:-}" ]]; then
		critical_paths+=("$EAW_CARD_WORKFLOW_STATE_FILE")
	fi
	if [[ -n "${EAW_CARD_WORKFLOW_TRACK_FILE:-}" ]]; then
		critical_paths+=("$EAW_CARD_WORKFLOW_TRACK_FILE")
	fi
	if [[ -n "${EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE:-}" ]]; then
		critical_paths+=("$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE")
	fi
	if [[ -f "$card_dir/investigations/00_intake.md" ]]; then
		critical_paths+=("$card_dir/investigations/00_intake.md")
	fi

	printf '%s\n' "${critical_paths[@]}" | awk 'NF && !seen[$0]++ { printf "- %s\n", $0 }'
}

eaw_runtime_environment_block() {
	local card="$1"
	local card_dir="$2"
	local track_id="$3"
	local step_id="$4"
	local workdir="${EAW_WORKDIR:-}"
	local write_allowlist="$5"
	local critical_paths="$6"
	local target_repos="$7"

	cat <<EOF
RUNTIME_ENVIRONMENT

CARD_ID: $card
TRACK_ID: $track_id
STEP_ID: $step_id
WORKDIR: $workdir
CARD_DIR: $card_dir
OUT_DIR: $EAW_OUT_DIR

TARGET_REPOSITORIES:
$target_repos

WRITE_ALLOWLIST:
$write_allowlist

CRITICAL_PATHS:
$critical_paths
EOF
}

eaw_scaffold_phase_artifact() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local rel_path="$4"
	local target_path="$card_dir/$rel_path"
	local target_dir
	local type

	target_dir="$(dirname "$target_path")"
	assert_write_scope "workflow_phase" "ensure_dir artifact_parent" "$target_dir" "$card_dir"
	ensure_dir "$target_dir"

	if [[ -f "$target_path" ]]; then
		echo "RUNTIME: phase=$phase_id preserve_artifact=$rel_path"
		return 0
	fi

	case "$rel_path" in
	investigations/00_intake.md)
		type="$(eaw_detect_card_template_type "$card" "$card_dir")"
		eaw_render_phase_template_with_card "$EAW_TEMPLATES_DIR/intake_${type}.md" "$target_path" "$card"
		;;
	investigations/20_findings.md)
		eaw_render_phase_template_with_card "$EAW_TEMPLATES_DIR/20_findings.md" "$target_path" "$card"
		;;
	investigations/30_hypotheses.md)
		eaw_render_phase_template_with_card "$EAW_TEMPLATES_DIR/30_hypotheses.md" "$target_path" "$card"
		;;
	investigations/40_next_steps.md)
		eaw_render_phase_template_with_card "$EAW_TEMPLATES_DIR/40_next_steps.md" "$target_path" "$card"
		;;
	implementation/00_scope.lock.md)
		cat >"$target_path" <<EOF
# Scope Lock - Card $card

## In Scope

## Out of Scope
EOF
		;;
	implementation/10_change_plan.md)
		cat >"$target_path" <<EOF
# Change Plan - Card $card

## Steps

## Validation
EOF
		;;
	implementation/20_patch_notes.md)
		cat >"$target_path" <<EOF
# Patch Notes - Card $card

## Changes

## Risks
EOF
		;;
	*)
		cat >"$target_path" <<EOF
# ${phase_id} artifact

Generated by phase-driven execution for card $card.
EOF
		;;
	esac

	echo "RUNTIME: phase=$phase_id created_artifact=$rel_path"
}

eaw_render_phase_prompt_template() {
	local template_file="$1"
	local output_file="$2"
	local phase_header="$3"
	local card="$4"
	local type="$5"
	local card_dir="$6"
	local target_repos="$7"
	local excluded_repos="$8"
	local warnings_block="$9"
	local track_id="${10}"
	local step_id="${11}"
	local write_allowlist="${12}"
	local critical_paths="${13}"
	local runtime_environment="${14}"
	local tooling_hints="${15:-}"
	local tooling_hints_serialized=""

	if [[ -n "$tooling_hints" ]]; then
		tooling_hints_serialized="${tooling_hints//$'\n'/__EAW_TOOLING_HINT_NL__}"
	fi

	assert_write_scope "workflow_phase" "write phase prompt" "$output_file" "$card_dir"
	ensure_dir "$(dirname "$output_file")"

	awk \
		-v phase_header="$phase_header" \
		-v card="$card" \
		-v type="$type" \
		-v round="${EAW_PHASE_PROMPT_ROUND:-1}" \
		-v eaw_workdir="${EAW_WORKDIR:-}" \
		-v runtime_root="$EAW_ROOT_DIR" \
		-v config_source="$REPOS_CONF" \
		-v out_dir="$EAW_OUT_DIR" \
		-v card_dir="$card_dir" \
		-v target_repos="$target_repos" \
		-v excluded_repos="$excluded_repos" \
		-v warnings_block="$warnings_block" \
		-v track_id="$track_id" \
		-v step_id="$step_id" \
		-v write_allowlist="$write_allowlist" \
		-v critical_paths="$critical_paths" \
		-v runtime_environment="$runtime_environment" \
		-v tooling_hints="$tooling_hints_serialized" \
		'
		{
			if ($0 == "{{RUNTIME_ENVIRONMENT}}") {
				print runtime_environment
				next
			}
			if ($0 == "{{TARGET_REPOS}}") {
				print target_repos
				next
			}
			if ($0 == "{{EXCLUDED_REPOS}}") {
				print excluded_repos
				next
			}
			if ($0 == "{{WARNINGS_BLOCK}}") {
				print warnings_block
				next
			}
			if ($0 == "{{TOOLING_HINTS}}") {
				if (tooling_hints != "") {
					gsub(/__EAW_TOOLING_HINT_NL__/, "\n", tooling_hints)
					print tooling_hints
				}
				next
			}
			gsub(/\{\{PHASE_HEADER\}\}/, phase_header)
			gsub(/\{\{CARD\}\}/, card)
			gsub(/\{\{TYPE\}\}/, type)
			gsub(/\{\{ROUND\}\}/, round)
			gsub(/\{\{EAW_WORKDIR\}\}/, eaw_workdir)
			gsub(/\{\{RUNTIME_ROOT\}\}/, runtime_root)
			gsub(/\{\{CONFIG_SOURCE\}\}/, config_source)
			gsub(/\{\{OUT_DIR\}\}/, out_dir)
			gsub(/\{\{CARD_DIR\}\}/, card_dir)
			gsub(/\{\{TRACK_ID\}\}/, track_id)
			gsub(/\{\{STEP_ID\}\}/, step_id)
			gsub(/\{\{WRITE_ALLOWLIST\}\}/, write_allowlist)
			gsub(/\{\{CRITICAL_PATHS\}\}/, critical_paths)
			print
		}
		' "$template_file" >"$output_file"

	echo "RUNTIME: wrote_prompt=${output_file#$card_dir/}"
}

eaw_primary_target_repo() {
	local target_repos="$1"
	printf "%s\n" "$target_repos" | awk 'NF { sub(/^- /, "", $0); print; exit }'
}

eaw_render_tooling_hints_block() {
	local phase_file="$1"
	local card="$2"
	local type="$3"
	local card_dir="$4"
	local track_id="$5"
	local step_id="$6"
	local target_repos="$7"
	local primary_target_repo hint rendered
	local count=0

	primary_target_repo="$(eaw_primary_target_repo "$target_repos")"

	while IFS= read -r hint; do
		[[ -n "$hint" ]] || continue
		rendered="$hint"
		rendered="${rendered//\{\{CARD\}\}/$card}"
		rendered="${rendered//<CARD>/$card}"
		rendered="${rendered//\{\{TYPE\}\}/$type}"
		rendered="${rendered//<TYPE>/$type}"
		rendered="${rendered//\{\{EAW_WORKDIR\}\}/${EAW_WORKDIR:-}}"
		rendered="${rendered//<WORKDIR>/${EAW_WORKDIR:-}}"
		rendered="${rendered//\{\{OUT_DIR\}\}/$EAW_OUT_DIR}"
		rendered="${rendered//<OUTDIR>/$EAW_OUT_DIR}"
		rendered="${rendered//\{\{CARD_DIR\}\}/$card_dir}"
		rendered="${rendered//<CARD_DIR>/$card_dir}"
		rendered="${rendered//\{\{TRACK_ID\}\}/$track_id}"
		rendered="${rendered//<TRACK_ID>/$track_id}"
		rendered="${rendered//\{\{STEP_ID\}\}/$step_id}"
		rendered="${rendered//<STEP_ID>/$step_id}"
		rendered="${rendered//\{\{TARGET_REPO\}\}/$primary_target_repo}"
		rendered="${rendered//<TARGET_REPO>/$primary_target_repo}"
		rendered="${rendered//\{\{TARGET_REPOS\}\}/$primary_target_repo}"
		rendered="${rendered//<TARGET_REPOS>/$primary_target_repo}"
		if [[ "$count" -eq 0 ]]; then
			printf "## Tooling Hints\n\n"
		fi
		printf -- "- %s\n" "$rendered"
		count=$((count + 1))
	done < <(eaw_yaml_phase_tooling_hints "$phase_file")
}

eaw_phase_prompt_output_relpath() {
	local prompt_alias
	prompt_alias="$(eaw_normalize_phase_id "${1:-}")"
	printf "prompts/%s.md\n" "$prompt_alias"
}

eaw_generate_phase_prompt_artifacts() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local phase_id="${EAW_CARD_WORKFLOW_CURRENT_PHASE:-}"
	local phase_file="${EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE:-}"
	local type template_file output_file
	local repo_blocks target_repos excluded_repos
	local prompt_alias prompt_relpath
	local track_id step_id write_allowlist critical_paths runtime_environment tooling_hints
	local prompt_track prompt_phase
	local -a declared_prompts=()

	# phase.prompt.path is the source of truth for track and phase.
	# Both are resolved at workflow context load time and available here.
	prompt_track="${EAW_CARD_WORKFLOW_CURRENT_PROMPT_TRACK:-}"
	prompt_phase="${EAW_CARD_WORKFLOW_CURRENT_PROMPT_PHASE:-}"
	if [[ -z "$prompt_track" || -z "$prompt_phase" ]]; then
		echo "ERROR: prompt track/phase not resolved for phase '$phase_id'; workflow context must be loaded before generating prompts" >&2
		return 1
	fi

	type="$(eaw_detect_card_template_type "$card" "$card_dir")"
	repo_blocks="$(collect_repos_lists)"
	target_repos="$(printf "%s\n" "$repo_blocks" | sed -n '1,/^$/p' | sed '/^$/d')"
	excluded_repos="$(printf "%s\n" "$repo_blocks" | sed -n '/^$/,$p' | sed '1d;/^$/d')"

	if [[ -n "$phase_file" && -f "$phase_file" ]]; then
		while IFS= read -r prompt_alias; do
			[[ -n "$prompt_alias" ]] || continue
			declared_prompts+=("$prompt_alias")
		done < <(eaw_yaml_phase_output_prompts "$phase_file")
	fi

	if [[ ${#declared_prompts[@]} -eq 0 ]]; then
		declared_prompts=("$phase_id")
	fi

	track_id="${EAW_CARD_WORKFLOW_TRACK_ID:-$type}"
	step_id="${EAW_CARD_WORKFLOW_CURRENT_PHASE:-$phase_id}"
	write_allowlist="$(eaw_card_write_allowlist_block "$card_dir")"
	critical_paths="$(eaw_card_critical_paths_block "$card_dir")"
	runtime_environment="$(eaw_runtime_environment_block "$card" "$card_dir" "$track_id" "$step_id" "$write_allowlist" "$critical_paths" "$target_repos")"
	tooling_hints="$(eaw_render_tooling_hints_block "$phase_file" "$card" "$type" "$card_dir" "$track_id" "$step_id" "$target_repos")"

	for prompt_alias in "${declared_prompts[@]}"; do
		prompt_alias="$(eaw_normalize_phase_id "$prompt_alias")"
		template_file="$(load_prompt "$prompt_track" "$prompt_phase" "$card" "$EAW_OUT_DIR")" || return 1
		prompt_relpath="$(eaw_phase_prompt_output_relpath "$prompt_alias")"
		output_file="$card_dir/$prompt_relpath"
		eaw_render_phase_prompt_template "$template_file" "$output_file" "${prompt_alias^^}" "$card" "$type" "$card_dir" "$target_repos" "$excluded_repos" "- none" "$track_id" "$step_id" "$write_allowlist" "$critical_paths" "$runtime_environment" "$tooling_hints"
	done
}

eaw_execute_workflow_phase() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local phase_id="${EAW_CARD_WORKFLOW_CURRENT_PHASE:-}"
	local phase_file="${EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE:-}"
	local rel_path

	if [[ -z "$phase_id" || -z "$phase_file" ]]; then
		echo "ERROR: workflow phase execution missing loaded phase context for card $card" >&2
		return 1
	fi

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		assert_write_scope "workflow_phase" "ensure_dir phase_output_dir" "$card_dir/$rel_path" "$card_dir"
		ensure_dir "$card_dir/$rel_path"
		echo "RUNTIME: phase=$phase_id created_dir=$rel_path"
	done < <(eaw_yaml_phase_output_directories "$phase_file")

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		eaw_scaffold_phase_artifact "$card" "$card_dir" "$phase_id" "$rel_path"
	done < <(eaw_yaml_phase_output_artifacts "$phase_file")

	eaw_generate_phase_prompt_artifacts "$card"
	echo "RUNTIME: phase=$phase_id action=phase_driven_execution"
	return 0
}

eaw_warn_compatibility_wrapper() {
	local command_name="$1"
	printf "WARNING: '%s' is deprecated and planned for removal in v1.0. Prefer 'eaw next'.\n" "$command_name" >&2
}

eaw_phase_index_in_track() {
	local track_file="$1"
	local target_phase="$2"
	local index=0
	local phase_name

	while IFS= read -r phase_name; do
		[[ -n "$phase_name" ]] || continue
		if [[ "$phase_name" == "$target_phase" ]]; then
			printf "%s\n" "$index"
			return 0
		fi
		index=$((index + 1))
	done < <(eaw_yaml_track_phases "$track_file")

	return 1
}

eaw_execute_current_phase_for_wrapper() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"

	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	OUTDIR="$card_dir"
	run_phase "workflow_phase_${EAW_CARD_WORKFLOW_CURRENT_PHASE}" true eaw_execute_workflow_phase "$card"
}

eaw_materialize_current_phase() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"

	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	OUTDIR="$card_dir"
	run_phase "workflow_phase_${EAW_CARD_WORKFLOW_CURRENT_PHASE}" true eaw_execute_workflow_phase "$card"
}

eaw_mark_current_phase_complete_for_wrapper() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local current_phase
	local current_phase_file
	local previous_phase
	local completed_phases
	local phase_status
	local phase_started_at
	local phase_completed_at

	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	current_phase_file="$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE"
	previous_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$EAW_CARD_WORKFLOW_STATE_FILE" "previous_phase")")"
	completed_phases="${EAW_CARD_WORKFLOW_COMPLETED_PHASES:-}"
	phase_status="$(eaw_state_phase_status_for_next)"
	phase_started_at="$(eaw_state_scalar_or_default "$EAW_CARD_WORKFLOW_STATE_FILE" "phase_started_at" "null")"

	if ! eaw_validate_phase_completion "$card" "$card_dir" "$current_phase" "$current_phase_file"; then
		return 1
	fi
	if [[ "$phase_status" == "COMPLETE" ]]; then
		return 0
	fi

	phase_completed_at="$(utc_timestamp)"
	eaw_write_phase_status "$EAW_CARD_WORKFLOW_STATE_FILE" "COMPLETE" "$previous_phase" "$current_phase" "$completed_phases" "$phase_started_at" "true" "$phase_completed_at"
	return 0
}

eaw_advance_to_next_phase_for_wrapper() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local current_phase
	local current_phase_file
	local next_phase
	local completed_phases
	local phase_started_at

	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	current_phase_file="$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE"
	if [[ "$current_phase" == "$EAW_CARD_WORKFLOW_FINAL_PHASE" ]]; then
		echo "CARD ${card}: workflow already complete"
		return 0
	fi

	if ! eaw_validate_phase_completion "$card" "$card_dir" "$current_phase" "$current_phase_file"; then
		return 1
	fi

	next_phase="$EAW_CARD_WORKFLOW_NEXT_PHASE"
	completed_phases="$(eaw_state_completed_phases_with_current "$current_phase")"
	phase_started_at="$(utc_timestamp)"
	eaw_write_next_state "$EAW_CARD_WORKFLOW_STATE_FILE" "$current_phase" "$next_phase" "$completed_phases" "RUN" "$phase_started_at" "false" "null"

	echo "CARD ${card}: ${current_phase} -> ${next_phase}"
	eaw_materialize_current_phase "$card" || return 1
	return 0
}

eaw_wrapper_materialize_until_phase() {
	local card="$1"
	local target_phase="$2"
	local card_dir="$EAW_OUT_DIR/$card"
	local current_phase
	local current_index
	local target_index

	if ! eaw_card_has_workflow_config "$card_dir"; then
		echo "ERROR: card ${card} is missing canonical workflow YAMLs in $card_dir/intake (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	current_index="$(eaw_phase_index_in_track "$EAW_CARD_WORKFLOW_TRACK_FILE" "$current_phase")" || return 1
	target_index="$(eaw_phase_index_in_track "$EAW_CARD_WORKFLOW_TRACK_FILE" "$target_phase")" || return 1

	if (( current_index > target_index )); then
		echo "ERROR: card ${card} is already beyond compatibility target phase '${target_phase}' (current_phase=${current_phase})" >&2
		return 1
	fi

	while true; do
		if ! eaw_load_card_workflow_context "$card_dir"; then
			return 1
		fi
		current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"

		if [[ "$current_phase" == "$target_phase" ]]; then
			eaw_execute_current_phase_for_wrapper "$card"
			return $?
		fi

		eaw_execute_current_phase_for_wrapper "$card" || return 1
		eaw_mark_current_phase_complete_for_wrapper "$card" || return 1
		eaw_advance_to_next_phase_for_wrapper "$card" || return 1
	done
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

	echo "RUNTIME: loaded track id=$EAW_CARD_WORKFLOW_TRACK_ID file=$EAW_CARD_WORKFLOW_TRACK_FILE source=$EAW_CARD_WORKFLOW_SOURCE"
	echo "RUNTIME: loaded state file=$EAW_CARD_WORKFLOW_STATE_FILE current_phase=$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	echo "RUNTIME: loaded phase file=$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE prompt_track=$EAW_CARD_WORKFLOW_CURRENT_PROMPT_TRACK prompt_phase=$EAW_CARD_WORKFLOW_CURRENT_PROMPT_PHASE prompt_path=$EAW_CARD_WORKFLOW_CURRENT_PROMPT_PATH"
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
	local track_id="${4:-${type,,}}"
	local outdir="$EAW_OUT_DIR/$card"
	# expose OUTDIR for run_phase and others
	OUTDIR="$outdir"
	ensure_dir "$outdir"

	# Preserve the lifecycle engine, but load declarative workflow context before
	# proceeding with the remaining phases so the runtime can validate state and
	# resolve the next track phase deterministically.
	run_phase "init_runtime" true phase_init_runtime "$type" "$card" "$title" "$outdir" "$track_id" || return 1
	run_phase "load_workflow_context" true phase_load_workflow_context "$card" || return 1
	run_phase "resolve_workflow_transition" true phase_resolve_workflow_transition "$card" || return 1
	run_phase "load_config" false phase_load_config "$outdir"
	run_phase "resolve_repos" false phase_resolve_repos
	run_phase "finalize" false phase_finalize "$card" "$outdir"

	if eaw_card_has_workflow_config "$outdir"; then
		eaw_materialize_current_phase "$card" || return 1
	fi
}

cmd_next() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local current_phase current_phase_file next_phase completed_phases phase_started_at previous_phase validation_output

	if ! eaw_card_has_workflow_config "$card_dir"; then
		echo "ERROR: card ${card} is missing canonical workflow YAMLs in $card_dir/intake (MVP requires canonical YAML structure)" >&2
		return 1
	fi

	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	current_phase_file="$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE"
	if [[ "$current_phase" == "$EAW_CARD_WORKFLOW_FINAL_PHASE" ]]; then
		OUTDIR="$card_dir"
		if ! grep -q '"event_type":"track_completed"' "${OUTDIR}/execution_journal.jsonl" 2>/dev/null; then
			eaw_journal_append "${EAW_CARD_WORKFLOW_CARD}" "${EAW_CARD_WORKFLOW_TRACK_ID}" \
				"${EAW_CARD_WORKFLOW_FINAL_PHASE}" "OK" "0" "track_completed"
		fi
		echo "CARD ${card}: workflow already complete"
		return 0
	fi

	eaw_materialize_current_phase "$card" || return 1
	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi
	current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	current_phase_file="$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE"

	if ! validation_output="$(eaw_validate_phase_completion_strict "$card" "$card_dir" "$current_phase" "$current_phase_file" 2>&1)"; then
		if [[ "$validation_output" == *"is incomplete; missing required artifacts:"* || "$validation_output" == *"is incomplete; unfilled required artifacts:"* ]]; then
			printf "%s\n" "$validation_output" >&2
			previous_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$EAW_CARD_WORKFLOW_STATE_FILE" "previous_phase")")"
			completed_phases="${EAW_CARD_WORKFLOW_COMPLETED_PHASES:-}"
			phase_started_at="$(eaw_state_scalar_or_default "$EAW_CARD_WORKFLOW_STATE_FILE" "phase_started_at" "$(utc_timestamp)")"
			eaw_write_phase_status "$EAW_CARD_WORKFLOW_STATE_FILE" "RUN" "$previous_phase" "$current_phase" "$completed_phases" "$phase_started_at" "false" "null"
			echo "CARD ${card}: ${current_phase} remains current; missing required artifacts"
			return 0
		fi
		printf "%s\n" "$validation_output" >&2
		return 1
	fi

	next_phase="$EAW_CARD_WORKFLOW_NEXT_PHASE"
	completed_phases="$(eaw_state_completed_phases_with_current "$current_phase")"
	phase_started_at="$(utc_timestamp)"
	eaw_write_next_state "$EAW_CARD_WORKFLOW_STATE_FILE" "$current_phase" "$next_phase" "$completed_phases" "RUN" "$phase_started_at" "false" "null"

	echo "CARD ${card}: ${current_phase} -> ${next_phase}"
	eaw_materialize_current_phase "$card" || return 1
	return 0
}

cmd_complete() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local current_phase current_phase_file completed_phases previous_phase phase_started_at phase_completed_at

	if ! eaw_card_has_workflow_config "$card_dir"; then
		echo "ERROR: card ${card} is missing canonical workflow YAMLs in $card_dir/intake (MVP requires canonical YAML structure)" >&2
		return 1
	fi
	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	current_phase="$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	current_phase_file="$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE"
	previous_phase="$(eaw_normalize_phase_id "$(eaw_yaml_state_scalar "$EAW_CARD_WORKFLOW_STATE_FILE" "previous_phase")")"
	completed_phases="${EAW_CARD_WORKFLOW_COMPLETED_PHASES:-}"
	phase_started_at="$(eaw_state_scalar_or_default "$EAW_CARD_WORKFLOW_STATE_FILE" "phase_started_at" "null")"

	if ! eaw_validate_phase_completion_strict "$card" "$card_dir" "$current_phase" "$current_phase_file"; then
		return 1
	fi

	OUTDIR="$card_dir"
	if [[ "$current_phase" == "$EAW_CARD_WORKFLOW_FINAL_PHASE" ]]; then
		if ! grep -q '"event_type":"card_completed"' "${OUTDIR}/execution_journal.jsonl" 2>/dev/null; then
			eaw_journal_append "${EAW_CARD_WORKFLOW_CARD}" "${EAW_CARD_WORKFLOW_TRACK_ID}" \
				"${EAW_CARD_WORKFLOW_FINAL_PHASE}" "OK" "0" "card_completed"
		fi
	fi
	phase_completed_at="$(utc_timestamp)"
	eaw_write_phase_status "$EAW_CARD_WORKFLOW_STATE_FILE" "COMPLETE" "$previous_phase" "$current_phase" "$completed_phases" "$phase_started_at" "true" "$phase_completed_at"
	echo "CARD ${card}: ${current_phase} marked COMPLETE"
	return 0
}
