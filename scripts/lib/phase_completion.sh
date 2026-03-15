#!/usr/bin/env bash

eaw_phase_completion_strategy_name() {
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
		in_phase && /^[^[:space:]]/ { in_phase=0; in_completion=0 }
		in_phase && /^  completion:[[:space:]]*$/ { in_completion=1; next }
		in_completion && /^  [^[:space:]]/ { in_completion=0 }
		in_completion && /^    strategy:[[:space:]]*/ {
			line=$0
			sub(/^    strategy:[[:space:]]*/, "", line)
			print trim(line)
			exit
		}
	' "$file"
}

eaw_phase_completion_required_artifacts() {
	local file="$1"
	awk '
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_completion=0; in_required=0 }
		in_phase && /^  completion:[[:space:]]*$/ { in_completion=1; next }
		in_completion && /^  [^[:space:]]/ { in_completion=0; in_required=0 }
		in_completion && /^    required_artifacts:[[:space:]]*$/ { in_required=1; next }
		in_required && /^    [^[:space:]-]/ { in_required=0 }
		in_required && /^      - / {
			line=$0
			sub(/^      - /, "", line)
			print line
		}
	' "$file"
}

eaw_phase_completion_evaluate_required_artifacts_exist() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local phase_file="$4"
	local rel_path
	local -a missing_artifacts=()

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		if [[ ! -e "$card_dir/$rel_path" ]]; then
			missing_artifacts+=("$rel_path")
		fi
	done < <(eaw_phase_completion_required_artifacts "$phase_file")

	if [[ ${#missing_artifacts[@]} -gt 0 ]]; then
		printf "ERROR: card %s phase '%s' is incomplete; missing required artifacts:" "$card" "$phase_id" >&2
		printf " %s" "${missing_artifacts[@]}" >&2
		printf "\n" >&2
		return 1
	fi

	return 0
}

eaw_phase_completion_evaluate() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local phase_file="$4"
	local strategy

	strategy="$(eaw_phase_completion_strategy_name "$phase_file")"
	case "$strategy" in
	"" | required_artifacts_exist)
		eaw_phase_completion_evaluate_required_artifacts_exist "$card" "$card_dir" "$phase_id" "$phase_file"
		;;
	*)
		echo "ERROR: card ${card} phase '${phase_id}' uses unsupported completion strategy '${strategy}'" >&2
		return 1
		;;
	esac
}
