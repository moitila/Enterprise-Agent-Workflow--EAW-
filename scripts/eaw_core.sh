#!/usr/bin/env bash

usage() {
	cat <<EOF
Usage: eaw init [--workdir <path>] [--force] [--upgrade]
Example:
  eaw init --workdir ./.eaw --upgrade
  eaw card <CARD> --track <TRACK> ["<TITLE>"]
  eaw intake <CARD> [--round=N]
  eaw analyze <CARD>
  eaw implement <CARD>
  eaw suggest-prompt <CARD> --track <TRACK> --phase <PHASE>
  eaw prompt validate
  eaw validate-prompt <TRACK> <PHASE> <CANDIDATE>
  eaw propose-prompt <CARD> <TRACK> <PHASE> <BASE_CANDIDATE> <NEW_CANDIDATE>
  eaw apply-prompt <TRACK> <PHASE> <CANDIDATE>
  eaw validate
  eaw doctor
EOF
}

scaffold_template_names() {
	printf '%s\n' \
		10_baseline \
		20_findings \
		30_hypotheses \
		40_next_steps
}

workspace_template_names() {
	printf '%s\n' \
		feature \
		bug \
		spike \
		intake_feature \
		intake_bug \
		intake_spike
	scaffold_template_names
}

copy_workspace_nested_templates() {
	local default_tpl_dir="$1"
	local tpl_dir="$2"
	local overwrite="$3"
	local rel src dst dst_parent
	local nested_templates=(
		"prompts/default/intake/prompt_v1.md"
		"prompts/default/intake/prompt_v1.meta"
		"prompts/default/intake/ACTIVE"
		"prompts/default/analyze_findings/prompt_v1.md"
		"prompts/default/analyze_findings/prompt_v1.meta"
		"prompts/default/analyze_findings/ACTIVE"
		"prompts/default/analyze_hypotheses/prompt_v1.md"
		"prompts/default/analyze_hypotheses/prompt_v1.meta"
		"prompts/default/analyze_hypotheses/ACTIVE"
		"prompts/default/analyze_planning/prompt_v1.md"
		"prompts/default/analyze_planning/prompt_v1.meta"
		"prompts/default/analyze_planning/ACTIVE"
		"prompts/default/implementation_planning/prompt_v1.md"
		"prompts/default/implementation_planning/prompt_v1.meta"
		"prompts/default/implementation_planning/ACTIVE"
		"prompts/default/implementation_executor/prompt_v1.md"
		"prompts/default/implementation_executor/prompt_v1.meta"
		"prompts/default/implementation_executor/ACTIVE"
	)

	for rel in "${nested_templates[@]}"; do
		src="$default_tpl_dir/$rel"
		dst="$tpl_dir/$rel"
		if [[ ! -f "$src" ]]; then
			continue
		fi

		dst_parent="$(dirname "$dst")"
		ensure_dir "$dst_parent"
		if [[ -f "$dst" && "$overwrite" != "true" ]]; then
			echo "$dst already exists; use --force to overwrite"
		else
			cp "$src" "$dst"
			echo "Created $dst"
		fi
	done
}

read_config_version() {
	local conf="$1"
	if [[ ! -f "$conf" ]]; then
		return 1
	fi
	local v
	v=$(awk -F'=' '/^[[:space:]]*config_version[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}' "$conf")
	if [[ -n "$v" ]]; then
		printf "%s\n" "$v"
		return 0
	fi
	return 1
}

eaw_conf_optional_formal_label() {
	printf "OPTIONAL_FORMAL"
}

eaw_conf_optional_formal_contract_note() {
	printf "contrato opcional formal ativo (defaults v1)"
}

check_config_version_validate() {
	local warnings_ref="$1"
	if [[ ! -f "$EAW_CONF" ]]; then
		echo "INFO: $EAW_CONF missing; $(eaw_conf_optional_formal_contract_note)"
		return 0
	fi

	local cv
	if cv="$(read_config_version "$EAW_CONF")"; then
		if [[ "$cv" =~ ^[0-9]+$ ]] && [[ "$cv" -lt "$REQUIRED_CONFIG_VERSION" ]]; then
			if [[ -n "${EAW_WORKDIR:-}" ]]; then
				echo "WARNING: config_version=$cv is older than required=$REQUIRED_CONFIG_VERSION; run: ./scripts/eaw init --workdir \"$EAW_WORKDIR\" --upgrade"
			else
				echo "WARNING: config_version=$cv is older than required=$REQUIRED_CONFIG_VERSION; update $EAW_CONF"
			fi
			eval "$warnings_ref=\$(( $warnings_ref + 1 ))"
		fi
	else
		echo "WARNING: $EAW_CONF exists but config_version is missing; add: config_version=$REQUIRED_CONFIG_VERSION"
		eval "$warnings_ref=\$(( $warnings_ref + 1 ))"
	fi
}

write_or_skip() {
	local target="$1"
	local force="$2"
	local content="$3"
	if [[ -f "$target" && "$force" != "true" ]]; then
		echo "$target already exists; use --force to overwrite"
		return 0
	fi
	printf "%s\n" "$content" >"$target"
	echo "Created $target"
}

write_eaw_conf_if_needed() {
	local cfg="$1"
	local workdir="$2"
	local force="$3"
	local upgrade="$4"
	local conf="$cfg/eaw.conf"
	local new_conf="$cfg/eaw.conf.new"

	if [[ ! -f "$conf" ]]; then
		printf "config_version=%s\n" "$REQUIRED_CONFIG_VERSION" >"$conf"
		echo "Created $conf"
		return 0
	fi

	local current_v
	if current_v="$(read_config_version "$conf")"; then
		if [[ "$current_v" =~ ^[0-9]+$ ]] && [[ "$current_v" -lt "$REQUIRED_CONFIG_VERSION" ]] && [[ "$upgrade" == "true" ]]; then
			printf "config_version=%s\n" "$REQUIRED_CONFIG_VERSION" >"$new_conf"
			echo "$conf has older config_version=$current_v; wrote upgrade hint to $new_conf"
		fi
	else
		if [[ "$upgrade" == "true" ]]; then
			printf "config_version=%s\n" "$REQUIRED_CONFIG_VERSION" >"$new_conf"
			echo "$conf is missing config_version; wrote $new_conf"
		else
			echo "$conf exists but config_version is missing; run: ./scripts/eaw init --workdir \"$workdir\" --upgrade"
		fi
	fi

	if [[ "$force" == "true" ]]; then
		printf "config_version=%s\n" "$REQUIRED_CONFIG_VERSION" >"$conf"
		echo "Created $conf"
	fi
}

init_workspace_workdir() {
	local workdir="$1"
	local force="$2"
	local upgrade="$3"
	local overwrite_templates="false"
	local cfg="$workdir/config"
	local tpl="$workdir/templates"
	local out="$workdir/out"
	local repos_conf="$cfg/repos.conf"
	local search_conf="$cfg/search.conf"
	local default_search="$EAW_ROOT_DIR/config/search.example.conf"
	local default_tpl_dir="$EAW_ROOT_DIR/templates"

	ensure_dir "$cfg"
	ensure_dir "$tpl"
	ensure_dir "$out"

	if [[ "$force" == "true" || "$upgrade" == "true" ]]; then
		overwrite_templates="true"
	fi

	write_or_skip "$repos_conf" "$force" "# Format: key|path|role(optional)
# Example:
# backend|/absolute/path/to/repo|target
# shared-infra|/absolute/path/to/infra|infra"

	while IFS= read -r name; do
		local src_tpl="$default_tpl_dir/$name.md"
		local dst_tpl="$tpl/$name.md"
		if [[ -f "$src_tpl" ]]; then
			if [[ -f "$dst_tpl" && "$overwrite_templates" != "true" ]]; then
				echo "$dst_tpl already exists; use --force to overwrite"
			else
				cp "$src_tpl" "$dst_tpl"
				echo "Created $dst_tpl"
			fi
		fi
	done < <(workspace_template_names)

	copy_workspace_nested_templates "$default_tpl_dir" "$tpl" "$overwrite_templates"

	if [[ -f "$default_search" ]]; then
		if [[ -f "$search_conf" && "$force" != "true" ]]; then
			echo "$search_conf already exists; use --force to overwrite"
		else
			cp "$default_search" "$search_conf"
			echo "Created $search_conf"
		fi
	else
		write_or_skip "$search_conf" "$force" "# Add one search pattern per line
# Example:
# TODO|FIXME"
	fi

	write_eaw_conf_if_needed "$cfg" "$workdir" "$force" "$upgrade"
}

validate_runtime_workdir() {
	if [[ -n "${EAW_WORKDIR:-}" ]]; then
		if [[ ! -d "$EAW_CONFIG_DIR" || ! -f "$REPOS_CONF" ]]; then
			echo "EAW_WORKDIR is set but workspace config is incomplete." >&2
			echo "Run:" >&2
			echo "  ./scripts/eaw init --workdir \"$EAW_WORKDIR\"" >&2
			exit 1
		fi
	fi
}

normalize_prompt_candidate() {
	local candidate="$1"
	if [[ "$candidate" =~ ^v[0-9]+$ ]]; then
		printf "%s\n" "$candidate"
		return 0
	fi
	if [[ "$candidate" =~ ^[0-9]+$ ]]; then
		printf "v%s\n" "$candidate"
		return 0
	fi
	return 1
}

is_safe_prompt_slug() {
	local value="$1"
	[[ "$value" =~ ^[a-z0-9][a-z0-9_-]*$ ]]
}

validate_prompt_slug() {
	local kind="$1"
	local value="$2"
	if is_safe_prompt_slug "$value"; then
		return 0
	fi
	echo "FAIL: invalid $kind '$value' (expected safe slug [a-z0-9_-])" >&2
	return 1
}

prompt_phase_dir() {
	local track="$1"
	local phase="$2"
	local by_phase by_track
	by_phase="$EAW_TEMPLATES_DIR/prompts/$phase"
	by_track="$EAW_TEMPLATES_DIR/prompts/$track/$phase"
	if [[ -d "$by_phase" ]]; then
		printf "%s\n" "$by_phase"
		return 0
	fi
	if [[ -d "$by_track" ]]; then
		printf "%s\n" "$by_track"
		return 0
	fi
	printf "%s\n" "$by_phase"
}

prompt_phase_dir_from_root() {
	local templates_root="$1"
	local track="$2"
	local phase="$3"
	local by_phase by_track
	by_phase="$templates_root/prompts/$phase"
	by_track="$templates_root/prompts/$track/$phase"
	if [[ -d "$by_phase" ]]; then
		printf "%s\n" "$by_phase"
		return 0
	fi
	if [[ -d "$by_track" ]]; then
		printf "%s\n" "$by_track"
		return 0
	fi
	printf "%s\n" "$by_phase"
}

prompt_resolve_active_metadata() {
	local track="$1"
	local phase="$2"
	local workspace_dir root_templates_root root_dir dir source_root
	local active_file raw_active active_value normalized_active md_file meta_file file_name prompt_used

	workspace_dir="$(prompt_phase_dir "$track" "$phase")"
	root_templates_root="$EAW_ROOT_DIR/templates"
	root_dir="$(prompt_phase_dir_from_root "$root_templates_root" "$track" "$phase")"

	if [[ -d "$workspace_dir" ]]; then
		dir="$workspace_dir"
		source_root="$EAW_TEMPLATES_DIR"
	elif [[ -d "$root_dir" ]]; then
		dir="$root_dir"
		source_root="$root_templates_root"
	else
		echo "ERROR: prompt directory not found for track '$track' phase '$phase': $workspace_dir" >&2
		return 1
	fi

	active_file="$dir/ACTIVE"
	if [[ ! -f "$active_file" ]]; then
		echo "ERROR: ACTIVE file not found for track '$track' phase '$phase': $active_file" >&2
		return 1
	fi

	raw_active="$(tr -d '\r' <"$active_file")"
	active_value="$(trim_spaces "$raw_active")"
	if [[ -z "$active_value" ]]; then
		echo "ERROR: ACTIVE is empty for track '$track' phase '$phase': $active_file" >&2
		return 1
	fi
	if ! normalized_active="$(normalize_prompt_candidate "$active_value")"; then
		echo "ERROR: ACTIVE has invalid version '$active_value' for track '$track' phase '$phase': $active_file" >&2
		return 1
	fi

	md_file="$dir/prompt_${normalized_active}.md"
	if [[ ! -f "$md_file" ]]; then
		echo "ERROR: ACTIVE points to missing prompt file for track '$track' phase '$phase' version '$normalized_active': $md_file" >&2
		return 1
	fi

	meta_file="$dir/prompt_${normalized_active}.meta"
	if [[ ! -f "$meta_file" ]]; then
		echo "ERROR: ACTIVE points to missing prompt metadata for track '$track' phase '$phase' version '$normalized_active': $meta_file" >&2
		return 1
	fi

	file_name="${md_file##*/}"
	prompt_used="${phase}_${normalized_active}"
	printf "phase=%s\n" "$phase"
	printf "track=%s\n" "$track"
	printf "source_root=%s\n" "$source_root"
	printf "phase_dir=%s\n" "$dir"
	printf "active=%s\n" "$normalized_active"
	printf "file=%s\n" "$file_name"
	printf "md_file=%s\n" "$md_file"
	printf "meta_file=%s\n" "$meta_file"
	printf "prompt_used=%s\n" "$prompt_used"
}

prompt_provenance_append() {
	local card="$1"
	local out_root="$2"
	local phase="$3"
	local track="$4"
	local source_root="$5"
	local phase_dir="$6"
	local active="$7"
	local file_name="$8"
	local prompt_used="$9"
	local provenance_dir provenance_file tmp_entries tmp_dedup tmp_yaml

	provenance_dir="$out_root/$card/provenance"
	provenance_file="$provenance_dir/prompts_used.yaml"
	ensure_dir "$provenance_dir"

	tmp_entries="$(mktemp "$provenance_dir/prompts_used.entries.XXXXXX")"
	tmp_dedup="$(mktemp "$provenance_dir/prompts_used.dedup.XXXXXX")"
	tmp_yaml="$(mktemp "$provenance_dir/prompts_used.yaml.XXXXXX")"

	if [[ -f "$provenance_file" ]]; then
		awk '
			function flush() {
				if (phase != "") {
					printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", phase, track, source_root, phase_dir, active, file, prompt_used
				}
			}
			/^  - phase: / {
				flush()
				phase=$0
				sub(/^  - phase: /, "", phase)
				track=""
				source_root=""
				phase_dir=""
				active=""
				file=""
				prompt_used=""
				next
			}
			/^    track: / { track=$0; sub(/^    track: /, "", track); next }
			/^    source_root: / { source_root=$0; sub(/^    source_root: /, "", source_root); next }
			/^    phase_dir: / { phase_dir=$0; sub(/^    phase_dir: /, "", phase_dir); next }
			/^    active: / { active=$0; sub(/^    active: /, "", active); next }
			/^    file: / { file=$0; sub(/^    file: /, "", file); next }
			/^    prompt_used: / { prompt_used=$0; sub(/^    prompt_used: /, "", prompt_used); next }
			END { flush() }
		' "$provenance_file" >>"$tmp_entries"
	fi

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$phase" "$track" "$source_root" "$phase_dir" "$active" "$file_name" "$prompt_used" >>"$tmp_entries"

	awk -F'\t' 'NF >= 7 { rec[$1]=$0 } END { for (k in rec) print rec[k] }' "$tmp_entries" | LC_ALL=C sort -t$'\t' -k1,1 >"$tmp_dedup"

	{
		printf "prompts:\n"
		while IFS=$'\t' read -r entry_phase entry_track entry_source_root entry_phase_dir entry_active entry_file entry_prompt_used; do
			[[ -n "$entry_phase" ]] || continue
			printf "  - phase: %s\n" "$entry_phase"
			printf "    track: %s\n" "$entry_track"
			printf "    source_root: %s\n" "$entry_source_root"
			printf "    phase_dir: %s\n" "$entry_phase_dir"
			printf "    active: %s\n" "$entry_active"
			printf "    file: %s\n" "$entry_file"
			printf "    prompt_used: %s\n" "$entry_prompt_used"
		done <"$tmp_dedup"
	} >"$tmp_yaml"

	mv "$tmp_yaml" "$provenance_file"
	rm -f "$tmp_entries" "$tmp_dedup"
}

load_prompt() {
	local track="$1"
	local phase="$2"
	local card="$3"
	local out_root="$4"
	local resolution key value
	local source_root phase_dir active file_name md_file prompt_used

	if ! resolution="$(prompt_resolve_active_metadata "$track" "$phase")"; then
		return 1
	fi

	while IFS='=' read -r key value; do
		case "$key" in
		source_root) source_root="$value" ;;
		phase_dir) phase_dir="$value" ;;
		active) active="$value" ;;
		file) file_name="$value" ;;
		md_file) md_file="$value" ;;
		prompt_used) prompt_used="$value" ;;
		esac
	done <<<"$resolution"

	if [[ -n "$card" && -n "$out_root" ]]; then
		prompt_provenance_append "$card" "$out_root" "$phase" "$track" "$source_root" "$phase_dir" "$active" "$file_name" "$prompt_used"
	fi

	printf "%s\n" "$md_file"
}

prompt_resolve_active_md_file() {
	local track="$1"
	local phase="$2"
	local resolution key value md_file=""
	if ! resolution="$(prompt_resolve_active_metadata "$track" "$phase")"; then
		return 1
	fi
	while IFS='=' read -r key value; do
		if [[ "$key" == "md_file" ]]; then
			md_file="$value"
			break
		fi
	done <<<"$resolution"
	printf "%s\n" "$md_file"
}

prompt_list_markdown_candidates() {
	local root="$EAW_TEMPLATES_DIR/prompts"
	if [[ ! -d "$root" ]]; then
		return 0
	fi
	find "$root" -type f -name 'prompt_v*.md' | LC_ALL=C sort
}

prompt_highest_candidate_base() {
	local dir="$1"
	local path name version max=-1
	for path in "$dir"/prompt_v*.md; do
		if [[ ! -f "$path" ]]; then
			continue
		fi
		name="${path##*/}"
		if [[ "$name" =~ ^prompt_v([0-9]+)\.md$ ]]; then
			version="${BASH_REMATCH[1]}"
			if ((version > max)); then
				max="$version"
			fi
		fi
	done
	if ((max < 0)); then
		return 1
	fi
	printf "prompt_v%s\n" "$max"
}

prompt_resolve_md_file() {
	local track="$1"
	local phase="$2"
	local candidate="${3:-}"
	local dir base md_file
	dir="$(prompt_phase_dir "$track" "$phase")"
	if [[ ! -d "$dir" ]]; then
		echo "ERROR: prompt directory not found for phase '$phase': $dir" >&2
		return 1
	fi
	if [[ -n "$candidate" && "$candidate" != "latest" ]]; then
		if ! base="$(prompt_candidate_base "$candidate")"; then
			echo "ERROR: invalid candidate '$candidate' (expected vN or N)" >&2
			return 1
		fi
		md_file="$dir/${base}.md"
		if [[ -f "$md_file" ]]; then
			printf "%s\n" "$md_file"
			return 0
		fi
	fi
	if ! base="$(prompt_highest_candidate_base "$dir")"; then
		echo "ERROR: no prompt candidate found in $dir" >&2
		return 1
	fi
	printf "%s/%s.md\n" "$dir" "$base"
}

prompt_candidate_base() {
	local candidate="$1"
	local version
	if ! version="$(normalize_prompt_candidate "$candidate")"; then
		return 1
	fi
	printf "prompt_%s\n" "$version"
}

prompt_meta_value() {
	local file="$1"
	local key="$2"
	awk -F'=' -v want="$key" '
		/^[[:space:]]*#/ { next }
		/^[[:space:]]*$/ { next }
		{
			k=$1
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", k)
			if (k != want) {
				next
			}
			sub(/^[^=]*=/, "", $0)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
			print $0
			exit
		}
	' "$file"
}

trim_spaces() {
	local s="$1"
	s="${s#"${s%%[![:space:]]*}"}"
	s="${s%"${s##*[![:space:]]}"}"
	printf "%s\n" "$s"
}

parse_repos_conf_line() {
	local line="$1"
	local lineno="$2"
	local key path role extra

	line="${line//$'\r'/}"
	if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
		return 1
	fi
	if [[ "$line" != *"|"* ]]; then
		echo "ERROR: repos.conf:$lineno invalid format (expected key|path or key|path|role): $line"
		return 2
	fi

	IFS='|' read -r key path role extra <<<"$line"
	key="$(trim_spaces "$key")"
	path="$(trim_spaces "$path")"
	role="$(trim_spaces "${role:-}")"
	extra="$(trim_spaces "${extra:-}")"

	if [[ -n "$extra" ]]; then
		echo "ERROR: repos.conf:$lineno invalid format (too many '|'): $line"
		return 2
	fi
	if [[ -z "$key" || -z "$path" ]]; then
		echo "ERROR: repos.conf:$lineno key/path cannot be empty: $line"
		return 2
	fi
	if [[ -z "$role" ]]; then
		role="target"
	fi
	case "$role" in
	target | infra) ;;
	*)
		echo "ERROR: repos.conf:$lineno invalid role '$role' (expected target|infra): $line"
		return 2
		;;
	esac

	printf "%s|%s|%s\n" "$key" "$path" "$role"
	return 0
}

collect_repos_lists() {
	# print two blocks separated by a blank line:
	# TARGET_REPOS block then EXCLUDED_REPOS block
	local line lineno normalized key path role
	local target_tmp excluded_tmp
	target_tmp="$(mktemp)"
	excluded_tmp="$(mktemp)"

	if [[ -f "$REPOS_CONF" ]]; then
		lineno=0
		while IFS= read -r line; do
			lineno=$((lineno + 1))
			if normalized="$(parse_repos_conf_line "$line" "$lineno" 2>/dev/null)"; then
				IFS='|' read -r key path role <<<"$normalized"
				if [[ "$role" == "target" ]]; then
					printf -- "- %s => %s\n" "$key" "$path" >>"$target_tmp"
				else
					printf -- "- %s => %s (%s)\n" "$key" "$path" "$role" >>"$excluded_tmp"
				fi
			fi
		done <"$REPOS_CONF"
	fi

	if [[ -s "$target_tmp" ]]; then
		LC_ALL=C sort "$target_tmp"
	else
		echo "(none)"
	fi
	echo
	if [[ -s "$excluded_tmp" ]]; then
		LC_ALL=C sort "$excluded_tmp"
	else
		echo "(none)"
	fi

	rm -f "$target_tmp" "$excluded_tmp"
}

run_phase() {
	# run_phase <phase-name> <fatal:true|false> <fn> [args...]
	local phase="$1"
	shift
	local fatal="$1"
	shift || true
	local fn="$1"
	shift
	local start end dur rc status
	local note=""
	# emit phase_started event (H3/H6)
	eaw_journal_append "${EAW_CARD_WORKFLOW_CARD:-}" "${EAW_CARD_WORKFLOW_TRACK_ID:-}" "$phase" "STARTED" "0" "phase_started"
	start=$(date +%s%3N)
	if "$fn" "$@"; then
		rc=0
		status="OK"
	else
		rc=$?
		status="FAIL"
	fi
	end=$(date +%s%3N)
	dur=$((end - start))
	# record to execution log
	printf "%s|%s|%s|%s\n" "$phase" "$status" "$dur" "$note" >>"$OUTDIR/execution.log"
	# emit phase_completed event (H4/H6)
	eaw_journal_append "${EAW_CARD_WORKFLOW_CARD:-}" "${EAW_CARD_WORKFLOW_TRACK_ID:-}" "$phase" "$status" "$dur" "phase_completed"
	# print summary line
	echo "[phase] $phase -> $status (${dur}ms)"
	if [[ "$status" != "OK" && "$fatal" == "true" ]]; then
		echo "phase '$phase' failed (fatal) with rc=$rc" >&2
		return "$rc"
	fi
	return 0
}

phase_init_runtime() {
	# $1 = template type, $2 = card, $3 = title, $4 = outdir, $5 = track_id(optional)
	local type="$1" card="$2" title="$3" outdir="$4" track_id_override="${5:-}"
	# deterministic runtime for phases
	export LC_ALL=C
	export TZ=UTC
	ensure_dir "$outdir"
	local tpl
	tpl="$EAW_TEMPLATES_DIR/$(echo "$type" | tr '[:upper:]' '[:lower:]').md"
	if [[ ! -f "$tpl" ]]; then
		echo "Template not found: $tpl" >&2
		return 1
	fi
	local date
	date=$(iso_date)
	local target_md="$outdir/${type}_${card}.md"
	render_template "$tpl" "$target_md" "$card" "$title" "$type" "$date"
	echo "Wrote $target_md"
	local intake_runtime_dir="$outdir/intake"
	local ingest_dir="$outdir/ingest"
	local intake_dir="$outdir/investigations"
	local intake_file="$intake_dir/00_intake.md"
	local intake_tpl="$EAW_TEMPLATES_DIR/intake_${type}.md"
	local ingest_input_file="$ingest_dir/sources.md"
	local state_runtime_file=""
	# Determine whether the effective track declares an ingest phase (H1, H8).
	# This check must precede any conditional scaffold creation.
	local track_has_ingest="false"
	local _effective_track_id="${track_id_override:-${type,,}}"
	local _check_track_file="$EAW_ROOT_DIR/tracks/${_effective_track_id}/track.yaml"
	if [[ -f "$_check_track_file" ]] && grep -qE '^    - ingest[[:space:]]*$' "$_check_track_file"; then
		track_has_ingest="true"
	fi
	ensure_dir "$intake_runtime_dir"
	if [[ "$track_has_ingest" == "true" ]]; then
		ensure_dir "$ingest_dir"
	fi
	ensure_dir "$intake_dir"
	if compgen -G "$outdir/state_card_*.yaml" >/dev/null; then
		state_runtime_file="$(compgen -G "$outdir/state_card_*.yaml" | LC_ALL=C sort | head -n 1)"
	elif compgen -G "$intake_runtime_dir/state_card_*.yaml" >/dev/null; then
		state_runtime_file="$(compgen -G "$intake_runtime_dir/state_card_*.yaml" | LC_ALL=C sort | head -n 1)"
	fi
	if [[ -z "$state_runtime_file" ]]; then
		local track_id="${_effective_track_id}"
		local state_file current_phase track_file phase_started_at
		if [[ -z "$track_id" || ! -d "$EAW_ROOT_DIR/tracks/$track_id" ]]; then
			track_id="standard"
		fi
		track_file="$EAW_ROOT_DIR/tracks/$track_id/track.yaml"
		current_phase="intake"
		if [[ -f "$track_file" ]]; then
			current_phase="$(awk '
				/^track:[[:space:]]*$/ { in_track=1; next }
				in_track && /^[^[:space:]]/ { in_track=0 }
				in_track && /^  initial_phase:[[:space:]]*/ {
					line=$0
					sub(/^  initial_phase:[[:space:]]*/, "", line)
					gsub(/^"|"$/, "", line)
					print line
					exit
				}
			' "$track_file")"
			[[ -n "$current_phase" ]] || current_phase="intake"
		fi
		phase_started_at="$(utc_timestamp)"
		state_file="$outdir/state_card_${track_id}.yaml"
		cat >"$state_file" <<EOF
config_version: 1

card_state:
  card_id: CARD_${card}
  track_id: ${track_id}
  current_phase: ${current_phase}
  phase_started_at: ${phase_started_at}
  phase_completed: false
  phase_completed_at: null
  previous_phase: null
  phase_status: RUN
  completed_phases: []
  created_at: "${date}"
  updated_at: "${date}"
EOF
		echo "Wrote $state_file"
	fi
	# Create ingest/sources.md only for tracks that declare ingest (H3, H8).
	if [[ "$track_has_ingest" == "true" ]]; then
		if [[ ! -f "$ingest_input_file" && -f "$intake_tpl" ]]; then
			cp "$intake_tpl" "$ingest_input_file"
			echo "Wrote $ingest_input_file"
		fi
	fi
	# Create investigations/00_intake.md only for tracks without ingest (H1, H8).
	# For tracks that declare ingest, 00_intake.md is created by the intake phase execution.
	if [[ "$track_has_ingest" != "true" ]]; then
		if [[ ! -f "$intake_file" ]]; then
			if [[ -f "$intake_tpl" ]]; then
				cp "$intake_tpl" "$intake_file"
			else
				echo "WARNING: missing intake template for type '$type': $intake_tpl; using minimal fallback"
				cat >"$intake_file" <<EOF
# Intake ${type^^} ${card}

## Resumo

## Comportamento esperado

## Comportamento atual

## Passos para reproduzir
EOF
			fi
			echo "Wrote $intake_file"
		fi
	fi
	# Create investigation scaffolds (non-breaking, idempotent)
	while IFS= read -r scaffold_name; do
		local scaffold_file="$intake_dir/${scaffold_name}.md"
		local scaffold_tpl="$EAW_TEMPLATES_DIR/${scaffold_name}.md"
		if [[ ! -f "$scaffold_file" ]]; then
			if [[ -f "$scaffold_tpl" ]]; then
				cp "$scaffold_tpl" "$scaffold_file"
				echo "Wrote $scaffold_file"
			else
				echo "WARNING: missing scaffold template: $scaffold_tpl; using minimal fallback"
				cat >"$scaffold_file" <<EOF
# ${scaffold_name^^} — Card ${card}

## Status

Placeholder for ${scaffold_name} investigation phase.
EOF
			fi
		fi
	done < <(scaffold_template_names)
	# initialize execution.log
	: >"$outdir/execution.log"
	printf "phase|status|duration_ms|note\n" >>"$outdir/execution.log"
	return 0
}

phase_load_config() {
	# verify minimal config presence; not fatal if repos.conf missing (best-effort)
	local outdir="$1"
	if [[ ! -f "$REPOS_CONF" ]]; then
		echo "Missing $REPOS_CONF; proceeding without repository context (best-effort)" >&2
		return 0
	fi
	return 0
}

phase_resolve_repos() {
	# build normalized lists from repos.conf
	REPO_ENTRIES=()
	EXCLUDED_REPO_ENTRIES=()
	if [[ -f "$REPOS_CONF" ]]; then
		local line lineno normalized key path role
		lineno=0
		while IFS= read -r line; do
			lineno=$((lineno + 1))
			if normalized="$(parse_repos_conf_line "$line" "$lineno")"; then
				IFS='|' read -r key path role <<<"$normalized"
				if [[ "$role" == "target" ]]; then
					REPO_ENTRIES+=("$normalized")
				else
					EXCLUDED_REPO_ENTRIES+=("$normalized")
				fi
			else
				case "$?" in
				1)
					continue
					;;
				2)
					continue
					;;
				esac
			fi
		done <"$REPOS_CONF"
	fi
	if [[ "${#EXCLUDED_REPO_ENTRIES[@]}" -gt 0 ]]; then
		echo "Excluded repositories by role=infra:"
		for entry in "${EXCLUDED_REPO_ENTRIES[@]}"; do
			IFS='|' read -r key path role <<<"$entry"
			echo "  - $key => $path ($role)"
		done
	fi
	return 0
}

phase_collect_context() {
	local card="$1" outdir="$2"
	# iterate resolved repos and gather context
	for entry in "${REPO_ENTRIES[@]:-}"; do
		IFS='|' read -r key path role <<<"$entry"
		if [[ -z "$key" || -z "$path" ]]; then
			continue
		fi
		repoPath="$(resolve_repo_path "$path")"
		repoOutDir="$outdir/context/$key"
		ensure_dir "$repoOutDir"
		echo "Collecting context for $key -> $repoPath"
		# gather context; failures are tolerated and produce _warnings.txt within gather_context_for_repo
		if ! gather_context_for_repo "$key" "$repoPath" "$repoOutDir"; then
			echo "allowed to fail: gather_context_for_repo failed for $key (see $repoOutDir)" >>"$repoOutDir/_warnings.txt"
		fi
	done
	return 0
}

phase_search_hits() {
	local outdir="$1"
	for entry in "${REPO_ENTRIES[@]:-}"; do
		IFS='|' read -r key path role <<<"$entry"
		if [[ -z "$key" || -z "$path" ]]; then
			continue
		fi
		repoPath="$(resolve_repo_path "$path")"
		repoOutDir="$outdir/context/$key"
		if ! collect_search_hits "$key" "$repoPath" "$repoOutDir" "$SEARCH_CONF"; then
			echo "allowed to fail: collect_search_hits failed for $key (see $repoOutDir)" >>"$repoOutDir/_warnings.txt"
		fi
	done
	return 0
}

phase_finalize() {
	local card="$1" outdir="$2"
	# summarize execution.log to stdout
	if [[ -f "$outdir/execution.log" ]]; then
		echo "Execution log for $card:" >&2
		sed -n '1,200p' "$outdir/execution.log" >&2 || true
	fi
	return 0
}

# --- end lifecycle engine ----------------------------------------------------

append_warn() {
	local warn_ref="$1"
	local msg="$2"
	eval "$warn_ref+=(\"\$msg\")"
}

grep_heading_match() {
	local file="$1"
	local pattern="$2"
	if command -v rg >/dev/null 2>&1; then
		rg -i -q -- "$pattern" "$file"
	else
		grep -Eiq -- "$pattern" "$file"
	fi
}

validate_intake_heading_group() {
	local file="$1"
	local warn_ref="$2"
	local label="$3"
	local pattern="$4"
	if ! grep_heading_match "$file" "$pattern"; then
		append_warn "$warn_ref" "intake missing heading for '${label}'"
	fi
}

detect_card_type_with_warnings() {
	local card="$1"
	local outdir="$2"
	local type_ref="$3"
	local warn_ref="$4"
	local found=()

	if [[ -f "$outdir/bug_${card}.md" ]]; then
		found+=("bug")
	fi
	if [[ -f "$outdir/feature_${card}.md" ]]; then
		found+=("feature")
	fi
	if [[ -f "$outdir/spike_${card}.md" ]]; then
		found+=("spike")
	fi

	if [[ "${#found[@]}" -eq 0 ]]; then
		append_warn "$warn_ref" "no dossier file found in $outdir; defaulting type to bug"
		eval "$type_ref='bug'"
		return 0
	fi

	if [[ "${#found[@]}" -gt 1 ]]; then
		append_warn "$warn_ref" "ambiguous card type (${found[*]}); applying priority bug > feature > spike"
	fi

	if [[ " ${found[*]} " == *" bug "* ]]; then
		eval "$type_ref='bug'"
		return 0
	fi
	if [[ " ${found[*]} " == *" feature "* ]]; then
		eval "$type_ref='feature'"
		return 0
	fi
	eval "$type_ref='spike'"
}

count_required_intake_headings() {
	local type="$1"
	local file="$2"
	local count=0
	case "$type" in
	bug)
		if grep_heading_match "$file" '^##[[:space:]]*(Resumo do problema|Resumo)[[:space:]]*$'; then count=$((count + 1)); fi
		if grep_heading_match "$file" '^##[[:space:]]*Comportamento esperado[[:space:]]*$'; then count=$((count + 1)); fi
		if grep_heading_match "$file" '^##[[:space:]]*Comportamento atual[[:space:]]*$'; then count=$((count + 1)); fi
		if grep_heading_match "$file" '^##[[:space:]]*Passos para reproduzir[[:space:]]*$'; then count=$((count + 1)); fi
		;;
	feature)
		if grep_heading_match "$file" '^##[[:space:]]*(Problema|Objetivo)[[:space:]]*$'; then count=$((count + 1)); fi
		if grep_heading_match "$file" '^##[[:space:]]*Critérios de aceite[[:space:]]*$'; then count=$((count + 1)); fi
		if grep_heading_match "$file" '^##[[:space:]]*Escopo([[:space:]]*\(In/Out\))?[[:space:]]*$'; then count=$((count + 1)); fi
		;;
	spike)
		if grep_heading_match "$file" '^##[[:space:]]*(Pergunta[[:space:]]*/[[:space:]]*Hipótese|Pergunta|Hipótese)[[:space:]]*$'; then count=$((count + 1)); fi
		if grep_heading_match "$file" '^##[[:space:]]*Critério de conclusão[[:space:]]*$'; then count=$((count + 1)); fi
		;;
	esac
	echo "$count"
}

intake_is_structurally_incomplete() {
	local type="$1"
	local file="$2"
	local size_bytes=0
	local required_hits=0
	size_bytes=$(wc -c <"$file" | tr -d '[:space:]')
	required_hits="$(count_required_intake_headings "$type" "$file")"
	if [[ "$size_bytes" -lt 50 || "$required_hits" -le 1 ]]; then
		return 0
	fi
	return 1
}

intake_has_section_headings() {
	local file="$1"
	if command -v rg >/dev/null 2>&1; then
		rg -q -- '^[[:space:]]*##[[:space:]]+\S' "$file"
	else
		grep -Eq -- '^[[:space:]]*##[[:space:]]+\S' "$file"
	fi
}

# Append one JSON event to the Execution Journal for the current card.
# H2: writes to ${OUTDIR}/execution_journal.jsonl (separate file, JSON Lines).
# H3: centralised wrapper — all journal writes go through this function.
# H5: no-op when OUTDIR or card_id is empty (safe in unit-test contexts).
eaw_journal_append() {
	local card_id="$1"
	local track="$2"
	local phase="$3"
	local status="$4"
	local duration_ms="$5"
	local event_type="${6:-phase_completed}"
	# H5/H6: guard — do not write without a card context
	[[ -n "${OUTDIR:-}" && -n "${card_id:-}" ]] || return 0
	local timestamp agent mode
	timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	agent="runtime"
	mode="phase_driven"
	printf '{"card_id":"%s","track":"%s","phase":"%s","timestamp":"%s","agent":"%s","mode":"%s","status":"%s","duration_ms":%s,"event_type":"%s"}\n' \
		"$card_id" "$track" "$phase" "$timestamp" "$agent" "$mode" "$status" "$duration_ms" "$event_type" \
		>>"${OUTDIR}/execution_journal.jsonl"
}

# Parse the context_pack list from a phase YAML file.
# Emits one alias per line; silent if context_pack is absent (backward compatible).
eaw_yaml_phase_context_pack() {
	local file="$1"
	awk '
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_cp=0 }
		in_phase && /^  context_pack:[[:space:]]*$/ { in_cp=1; next }
		in_cp && /^  [^[:space:]-]/ { in_cp=0 }
		in_cp && /^    - / {
			line=$0
			sub(/^    - /, "", line)
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
			if (line != "") print line
		}
	' "$file"
}
