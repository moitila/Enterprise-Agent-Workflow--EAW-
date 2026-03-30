#!/usr/bin/env bash

eaw_status_usage() {
	echo "usage: eaw status <CARD> | eaw status --all" >&2
}

eaw_status_completed_phases_emit() {
	local completed_phases="${1:-}"
	local phase=""
	local emitted=0

	while IFS= read -r phase; do
		[[ -n "$phase" ]] || continue
		printf "  - %s\n" "$phase"
		emitted=1
	done <<<"$completed_phases"

	if [[ "$emitted" -eq 0 ]]; then
		echo "  - none"
	fi
}

eaw_status_pending_artifacts_emit() {
	local card_dir="$1"
	local phase_file="$2"
	local rel_path=""
	local emitted=0

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		if [[ ! -e "$card_dir/$rel_path" ]]; then
			printf "  - %s\n" "$rel_path"
			emitted=1
		fi
	done < <(eaw_phase_completion_required_artifacts "$phase_file")

	if [[ "$emitted" -eq 0 ]]; then
		echo "  - none"
	fi
}

eaw_status_latest_journal_entry() {
	local card_dir="$1"
	local journal_file="$card_dir/execution_journal.jsonl"

	if [[ -s "$journal_file" ]]; then
		tail -n 1 "$journal_file"
	else
		echo "none (execution_journal.jsonl missing or empty)"
	fi
}

eaw_status_render_single() {
	local card="$1"
	local card_dir="$EAW_OUT_DIR/$card"
	local state_card_id=""

	if [[ ! -d "$card_dir" ]]; then
		echo "ERROR: card $card not found in $EAW_OUT_DIR" >&2
		return 1
	fi

	if ! eaw_load_card_workflow_context "$card_dir"; then
		return 1
	fi

	state_card_id="$(eaw_yaml_state_scalar "$EAW_CARD_WORKFLOW_STATE_FILE" "card_id")"
	if [[ -z "$state_card_id" ]]; then
		state_card_id="$card"
	fi

	printf "card_id: %s\n" "$state_card_id"
	printf "track_id: %s\n" "$EAW_CARD_WORKFLOW_TRACK_ID"
	printf "current_phase: %s\n" "$EAW_CARD_WORKFLOW_CURRENT_PHASE"
	printf "phase_status: %s\n" "$EAW_CARD_WORKFLOW_PHASE_STATUS"
	echo "completed_phases:"
	eaw_status_completed_phases_emit "${EAW_CARD_WORKFLOW_COMPLETED_PHASES:-}"
	echo "pending_required_artifacts:"
	eaw_status_pending_artifacts_emit "$card_dir" "$EAW_CARD_WORKFLOW_CURRENT_PHASE_FILE"
	printf "latest_journal_entry: %s\n" "$(eaw_status_latest_journal_entry "$card_dir")"
}

eaw_status_render_all() {
	local path=""
	local card=""
	local -a cards=()

	shopt -s nullglob
	for path in "$EAW_OUT_DIR"/*; do
		[[ -d "$path" ]] || continue
		if compgen -G "$path/state_card_*.yaml" >/dev/null || compgen -G "$path/intake/state_card_*.yaml" >/dev/null; then
			cards+=("$(basename "$path")")
		fi
	done
	shopt -u nullglob

	printf "card_id | track | phase | status\n"
	if [[ ${#cards[@]} -eq 0 ]]; then
		echo "(no cards found)"
		return 0
	fi

	while IFS= read -r card; do
		[[ -n "$card" ]] || continue
		if ! eaw_load_card_workflow_context "$EAW_OUT_DIR/$card"; then
			return 1
		fi
		printf "%s | %s | %s | %s\n" \
			"$card" \
			"$EAW_CARD_WORKFLOW_TRACK_ID" \
			"$EAW_CARD_WORKFLOW_CURRENT_PHASE" \
			"$EAW_CARD_WORKFLOW_PHASE_STATUS"
	done < <(printf "%s\n" "${cards[@]}" | LC_ALL=C sort)
}

cmd_status() {
	if [[ $# -eq 0 ]]; then
		eaw_status_usage
		return 2
	fi

	case "${1:-}" in
	--help | -h)
		echo "usage: eaw status <CARD> | eaw status --all"
		return 0
		;;
	--all)
		if [[ $# -ne 1 ]]; then
			eaw_status_usage
			return 2
		fi
		eaw_status_render_all
		;;
	*)
		if [[ $# -ne 1 ]]; then
			eaw_status_usage
			return 2
		fi
		eaw_status_render_single "$1"
		;;
	esac
}
