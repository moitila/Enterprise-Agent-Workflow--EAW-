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
		in_phase && /^[^[:space:]]/ { in_phase=0; in_completion=0; in_required=0; in_obj=0 }
		in_phase && /^  completion:[[:space:]]*$/ { in_completion=1; next }
		in_completion && /^  [^[:space:]]/ { in_completion=0; in_required=0; in_obj=0 }
		in_completion && /^    required_artifacts:[[:space:]]*$/ { in_required=1; next }
		in_required && /^    [^[:space:]-]/ { in_required=0; in_obj=0 }
		in_required && in_obj && /^        / { next }
		in_required && /^      - path:[[:space:]]/ {
			in_obj=1
			line=$0
			sub(/^      - path:[[:space:]]*/, "", line)
			print line
			next
		}
		in_required && /^      - / {
			in_obj=0
			line=$0
			sub(/^      - /, "", line)
			print line
		}
	' "$file"
}

eaw_phase_completion_artifact_object_metadata() {
	local phase_file="$1"
	local target="$2"
	awk -v target="$target" '
		function emit() {
			if (min_bytes != "") printf "min_bytes=%s\n", min_bytes
			if (validation_mode != "") printf "validation_mode=%s\n", validation_mode
			if (headings != "") printf "required_headings=%s\n", headings
		}
		BEGIN {
			in_phase=0; in_completion=0; in_required=0
			found=0; in_obj=0; in_headings=0
			min_bytes=""; validation_mode=""; headings=""
		}
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_completion=0; in_required=0 }
		in_phase && /^  completion:[[:space:]]*$/ { in_completion=1; next }
		in_completion && /^  [^[:space:]]/ { in_completion=0; in_required=0 }
		in_completion && /^    required_artifacts:[[:space:]]*$/ { in_required=1; next }
		in_required && /^    [^[:space:]-]/ { if (found) { emit(); exit } in_required=0 }
		in_required && /^      - / {
			if (found && in_obj) { emit(); exit }
			in_obj=0; in_headings=0
			if (/^      - path:[[:space:]]/) {
				line=$0; sub(/^      - path:[[:space:]]*/, "", line)
				sub(/[[:space:]]+$/, "", line)
				if (line == target) { found=1; in_obj=1 }
			}
			next
		}
		in_required && found && in_obj && in_headings && /^          - / {
			val=$0; sub(/^          - /, "", val)
			gsub(/^"|"$/, "", val)
			sub(/[[:space:]]+$/, "", val)
			headings=(headings == "" ? val : headings "|" val)
			next
		}
		in_required && found && in_obj && in_headings && /^        [^[:space:]]/ { in_headings=0 }
		in_required && found && in_obj && /^        min_bytes:[[:space:]]/ {
			val=$0; sub(/^        min_bytes:[[:space:]]*/, "", val)
			sub(/[[:space:]]+$/, "", val); min_bytes=val; next
		}
		in_required && found && in_obj && /^        validation_mode:[[:space:]]/ {
			val=$0; sub(/^        validation_mode:[[:space:]]*/, "", val)
			sub(/[[:space:]]+$/, "", val); validation_mode=val; next
		}
		in_required && found && in_obj && /^        required_headings:[[:space:]]*$/ {
			in_headings=1; next
		}
		END { if (found && in_obj) emit() }
	' "$phase_file"
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

eaw_phase_completion_detect_card_template_type() {
	local card="$1"
	local card_dir="$2"

	if [[ -f "$card_dir/bug_${card}.md" ]]; then
		printf "bug\n"
	elif [[ -f "$card_dir/spike_${card}.md" ]]; then
		printf "spike\n"
	elif compgen -G "$card_dir/state_card_repo_onboarding.yaml" >/dev/null 2>&1; then
		printf "repo_onboarding\n"
	else
		printf "feature\n"
	fi
}

eaw_phase_completion_render_expected_scaffold() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local rel_path="$4"
	local type template_file

	case "$rel_path" in
	investigations/00_intake.md)
		type="$(eaw_phase_completion_detect_card_template_type "$card" "$card_dir")"
		template_file="$EAW_TEMPLATES_DIR/intake_${type}.md"
		sed "s/<CARD>/${card}/g" "$template_file"
		;;
	investigations/20_findings.md)
		sed "s/<CARD>/${card}/g" "$EAW_TEMPLATES_DIR/20_findings.md"
		;;
	investigations/30_hypotheses.md)
		sed "s/<CARD>/${card}/g" "$EAW_TEMPLATES_DIR/30_hypotheses.md"
		;;
	investigations/40_next_steps.md)
		sed "s/<CARD>/${card}/g" "$EAW_TEMPLATES_DIR/40_next_steps.md"
		;;
	implementation/00_scope.lock.md)
		cat <<EOF
# Scope Lock - Card $card

## In Scope

## Out of Scope
EOF
		;;
	implementation/10_change_plan.md)
		cat <<EOF
# Change Plan - Card $card

## Steps

## Validation
EOF
		;;
	implementation/20_patch_notes.md)
		cat <<EOF
# Patch Notes - Card $card

## Changes

## Risks
EOF
		;;
	*)
		cat <<EOF
# ${phase_id} artifact

Generated by phase-driven execution for card $card.
EOF
		;;
	esac
}

eaw_phase_completion_render_source_scaffold() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local rel_path="$4"
	local type template_file

	case "$rel_path" in
	investigations/00_intake.md)
		type="$(eaw_phase_completion_detect_card_template_type "$card" "$card_dir")"
		template_file="$EAW_TEMPLATES_DIR/intake_${type}.md"
		cat "$template_file"
		;;
	investigations/20_findings.md)
		cat "$EAW_TEMPLATES_DIR/20_findings.md"
		;;
	investigations/30_hypotheses.md)
		cat "$EAW_TEMPLATES_DIR/30_hypotheses.md"
		;;
	investigations/40_next_steps.md)
		cat "$EAW_TEMPLATES_DIR/40_next_steps.md"
		;;
	*)
		eaw_phase_completion_render_expected_scaffold "$card" "$card_dir" "$phase_id" "$rel_path"
		;;
	esac
}

eaw_phase_completion_artifact_has_meaningful_content() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local rel_path="$4"
	local file="$card_dir/$rel_path"
	local scaffold_file
	local source_scaffold_file

	if [[ ! -s "$file" ]]; then
		return 1
	fi

	scaffold_file="$(mktemp)"
	eaw_phase_completion_render_expected_scaffold "$card" "$card_dir" "$phase_id" "$rel_path" >"$scaffold_file"
	if cmp -s "$file" "$scaffold_file"; then
		rm -f "$scaffold_file"
		return 1
	fi

	source_scaffold_file="$(mktemp)"
	eaw_phase_completion_render_source_scaffold "$card" "$card_dir" "$phase_id" "$rel_path" >"$source_scaffold_file"
	if cmp -s "$file" "$source_scaffold_file"; then
		rm -f "$scaffold_file" "$source_scaffold_file"
		return 1
	fi
	rm -f "$scaffold_file" "$source_scaffold_file"
	# Size floor: reject if below minimum regardless of scaffold identity
	local size_check_min="${SIZE_FLOOR:-500}"
	local file_size
	file_size="$(wc -c < "$file" 2>/dev/null || echo 0)"
	if [[ "$file_size" -lt "$size_check_min" ]]; then
		rm -f "$scaffold_file"
		return 1   # below size floor → not meaningful
	fi
	return 0
}

eaw_phase_completion_evaluate_required_artifacts_filled() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local phase_file="$4"
	local rel_path
	local -a unfilled_artifacts=()

	if ! eaw_phase_completion_evaluate_required_artifacts_exist "$card" "$card_dir" "$phase_id" "$phase_file"; then
		return 1
	fi

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		if ! eaw_phase_completion_artifact_has_meaningful_content "$card" "$card_dir" "$phase_id" "$rel_path"; then
			unfilled_artifacts+=("$rel_path")
		fi
	done < <(eaw_phase_completion_required_artifacts "$phase_file")

	if [[ ${#unfilled_artifacts[@]} -gt 0 ]]; then
		printf "ERROR: card %s phase '%s' is incomplete; unfilled required artifacts:" "$card" "$phase_id" >&2
		printf " %s" "${unfilled_artifacts[@]}" >&2
		printf "\n" >&2
		return 1
	fi

	return 0
}

eaw_phase_completion_evaluate_required_artifacts_substantive() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local phase_file="$4"
	local rel_path metadata meta_line min_bytes validation_mode headings file_size failed heading
	local -a warning_artifacts=()
	local -a blocking_artifacts=()
	local -a heading_list

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		metadata="$(eaw_phase_completion_artifact_object_metadata "$phase_file" "$rel_path")"
		[[ -n "$metadata" ]] || continue
		min_bytes=""
		validation_mode=""
		headings=""
		while IFS= read -r meta_line; do
			case "$meta_line" in
			min_bytes=*) min_bytes="${meta_line#min_bytes=}" ;;
			validation_mode=*) validation_mode="${meta_line#validation_mode=}" ;;
			required_headings=*) headings="${meta_line#required_headings=}" ;;
			esac
		done <<<"$metadata"
		[[ -n "$validation_mode" ]] || validation_mode="warning"
		failed=0
		# Apply global default when min_bytes not declared per-artifact in YAML
		min_bytes="${min_bytes:-500}"
		if [[ -n "$min_bytes" && -e "$card_dir/$rel_path" ]]; then
			file_size="$(wc -c <"$card_dir/$rel_path")"
			if [[ "$file_size" -lt "$min_bytes" ]]; then
				failed=1
			fi
		fi
		if [[ "$failed" -eq 0 && -n "$headings" && -e "$card_dir/$rel_path" ]]; then
			IFS='|' read -ra heading_list <<<"$headings"
			for heading in "${heading_list[@]}"; do
				if ! grep -qF "$heading" "$card_dir/$rel_path"; then
					failed=1
					break
				fi
			done
		fi
		if [[ "$failed" -eq 1 ]]; then
			if [[ "$validation_mode" == "blocking" ]]; then
				blocking_artifacts+=("$rel_path")
			else
				warning_artifacts+=("$rel_path")
			fi
		fi
	done < <(eaw_phase_completion_required_artifacts "$phase_file")

	if [[ ${#warning_artifacts[@]} -gt 0 ]]; then
		printf "WARNING: card %s phase '%s' has artifacts not meeting criteria:" "$card" "$phase_id" >&2
		printf " %s" "${warning_artifacts[@]}" >&2
		printf "\n" >&2
	fi

	if [[ ${#blocking_artifacts[@]} -gt 0 ]]; then
		printf "ERROR: card %s phase '%s' is incomplete; invalid required artifacts:" "$card" "$phase_id" >&2
		printf " %s" "${blocking_artifacts[@]}" >&2
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

eaw_phase_completion_evaluate_strict() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local phase_file="$4"
	local strategy

	strategy="$(eaw_phase_completion_strategy_name "$phase_file")"
	case "$strategy" in
	"" | required_artifacts_exist)
		if ! eaw_phase_completion_evaluate_required_artifacts_filled "$card" "$card_dir" "$phase_id" "$phase_file"; then
			return 1
		fi
		eaw_phase_completion_evaluate_required_artifacts_substantive "$card" "$card_dir" "$phase_id" "$phase_file"
		;;
	*)
		eaw_phase_completion_evaluate "$card" "$card_dir" "$phase_id" "$phase_file"
		;;
	esac
}

eaw_card_enforce_mandatory_analysis_audit() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local rel_path
	local -a missing_artifacts=()

	case "$phase_id" in
	implementation_planning | implementation_executor) ;;
	*)
		return 0
		;;
	esac

	for rel_path in \
		investigations/20_findings.md \
		investigations/30_hypotheses.md \
		investigations/40_next_steps.md; do
		if [[ ! -s "$card_dir/$rel_path" ]]; then
			missing_artifacts+=("$rel_path")
		fi
	done

	if [[ "$phase_id" == "implementation_executor" ]]; then
		for rel_path in \
			implementation/00_scope.lock.md \
			implementation/10_change_plan.md; do
			if [[ ! -s "$card_dir/$rel_path" ]]; then
				missing_artifacts+=("$rel_path")
			fi
		done
	fi

	if [[ ${#missing_artifacts[@]} -gt 0 ]]; then
		printf "ERROR: card %s phase '%s' blocked; desvio de escopo: artefatos obrigatorios ausentes ou vazios:" "$card" "$phase_id" >&2
		printf " %s" "${missing_artifacts[@]}" >&2
		printf "\n" >&2
		return 1
	fi

	return 0
}

eaw_phase_completion_render_artifact_status_checklist() {
	local card="$1"
	local card_dir="$2"
	local phase_id="$3"
	local phase_file="$4"
	local rel_path label metadata meta_line min_bytes validation_mode headings file_size failed heading
	local -a heading_list

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		if [[ ! -e "$card_dir/$rel_path" ]]; then
			label="[missing]"
		elif ! eaw_phase_completion_artifact_has_meaningful_content "$card" "$card_dir" "$phase_id" "$rel_path"; then
			label="[unfilled]"
		else
			label="[ok]"
			metadata="$(eaw_phase_completion_artifact_object_metadata "$phase_file" "$rel_path")"
			if [[ -n "$metadata" ]]; then
				min_bytes=""
				validation_mode=""
				headings=""
				while IFS= read -r meta_line; do
					case "$meta_line" in
					min_bytes=*) min_bytes="${meta_line#min_bytes=}" ;;
					validation_mode=*) validation_mode="${meta_line#validation_mode=}" ;;
					required_headings=*) headings="${meta_line#required_headings=}" ;;
					esac
				done <<<"$metadata"
				[[ -n "$validation_mode" ]] || validation_mode="warning"
				failed=0
				if [[ -n "$min_bytes" ]]; then
					file_size="$(wc -c <"$card_dir/$rel_path")"
					if [[ "$file_size" -lt "$min_bytes" ]]; then
						failed=1
					fi
				fi
				if [[ "$failed" -eq 0 && -n "$headings" ]]; then
					IFS='|' read -ra heading_list <<<"$headings"
					for heading in "${heading_list[@]}"; do
						if ! grep -qF "$heading" "$card_dir/$rel_path"; then
							failed=1
							break
						fi
					done
				fi
				if [[ "$failed" -eq 1 ]]; then
					if [[ "$validation_mode" == "blocking" ]]; then
						label="[invalid]"
					else
						label="[warning]"
					fi
				fi
			fi
		fi
		printf "%-10s %s\n" "$label" "$rel_path"
	done < <(eaw_phase_completion_required_artifacts "$phase_file")
}
