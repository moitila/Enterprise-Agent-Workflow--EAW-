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
	local track_id
	local -a state_candidates=()

	shopt -s nullglob
	state_candidates=("$card_dir"/state_card_*.yaml)
	shopt -u nullglob

	if [[ ${#state_candidates[@]} -eq 0 ]]; then
		echo "eaw_phase_completion_detect_card_template_type: no state_card_*.yaml found in $card_dir" >&2
		return 1
	elif [[ ${#state_candidates[@]} -gt 1 ]]; then
		echo "eaw_phase_completion_detect_card_template_type: multiple state_card_*.yaml found in $card_dir" >&2
		return 1
	fi

	track_id="$(eaw_yaml_state_scalar "${state_candidates[0]}" "track_id")"

	if [[ -z "$track_id" ]]; then
		echo "eaw_phase_completion_detect_card_template_type: track_id missing in ${state_candidates[0]}" >&2
		return 1
	fi

	if [[ ! "$track_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		echo "eaw_phase_completion_detect_card_template_type: track_id contains invalid characters: $track_id" >&2
		return 1
	fi

	track_id="${track_id,,}"

	if [[ -f "${EAW_TEMPLATES_DIR}/intake_${track_id}.md" ]]; then
		printf "%s\n" "$track_id"
		return 0
	fi

	# Legacy fallback when no dedicated template exists
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

## Base Obrigatoria

## Hipotese(s) Base

## Contexto

## In Scope

## Out of Scope

## Allowlist de Escrita
Substitua este bloco por paths absolutos reais — um por linha, sem exemplos fictícios.

## Regra de Escrita
EOF
		;;
	implementation/10_change_plan.md)
		cat <<EOF
# Change Plan - Card $card

## Steps

## Validacao Read-only

## Validacao Pos-PR

## Rollback
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

	if [[ "$rel_path" == "investigations/20_handoff.json" ]]; then
		local normalized
		normalized="$(tr -d '\n\r\t ' <"$file" 2>/dev/null || true)"
		[[ "$normalized" == *'"from_phase":"'* ]] || return 1
		[[ "$normalized" == *'"status":"completed"'* || "$normalized" == *'"status":"skipped"'* || "$normalized" == *'"status":"failed"'* ]] || return 1
		[[ "$normalized" == *'"messages":['* ]] || return 1
		[[ "$normalized" == *'"codes":['* ]] || return 1
		[[ "$normalized" != *'"scaffold":true'* ]] || return 1
		return 0
	fi

	if [[ "$rel_path" == "investigations/10_phase_output.json" ]]; then
		local normalized
		normalized="$(tr -d '\n\r\t ' <"$file" 2>/dev/null || true)"
		[[ "$normalized" == *'"phase_id":"'* ]] || return 1
		[[ "$normalized" == *'"status":"'* ]] || return 1
		[[ "$normalized" == *'"summary":"'* ]] || return 1
		return 0
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

	# FIX-IDENTITY: reject unrendered template variables (identity, not size). The
	# card-token scaffold case (<CARD>) is already covered by the anti-scaffold cmp
	# above (the template IS the scaffold); here we additionally reject files that
	# still carry unrendered {{...}} template variables.
	if grep -Eq '\{\{[A-Za-z0-9_]+\}\}' "$file"; then
		return 1
	fi

	# FIX-SCOPELOCK: scope.lock has its own deterministic structural parse (no size).
	# Runs AFTER the anti-scaffold cmp so the byte-identical minimal scaffold stays
	# rejected, while the enriched scaffold (write_allowlist: [] / headings) is accepted.
	if [[ "$rel_path" == "implementation/00_scope.lock.md" ]]; then
		if grep -q 'write_allowlist:' "$file"; then
			return 0
		fi
		if grep -q '^## In Scope' "$file" && grep -q '^## Out of Scope' "$file"; then
			if grep -q '^## Allowlist de Escrita' "$file"; then
				if awk '/^## Allowlist de Escrita/{f=1;next} f && /^## /{exit} f && /\//{print;exit}' "$file" | grep -q '/'; then
					return 0
				fi
			fi
		fi
		return 1
	fi

	# FIX-EMPTY-HEADINGS: for markdown artifacts, reject files that consist only of
	# heading lines (# / ##) and blank lines — this is an unfilled scaffold regardless
	# of which template it came from (e.g. 5-heading intake with all sections empty).
	if [[ "$rel_path" == *.md ]]; then
		local non_heading_lines
		non_heading_lines="$(grep -cvE '^[[:space:]]*$|^#' "$file" 2>/dev/null)" || non_heading_lines=0
		if [[ "$non_heading_lines" -eq 0 ]]; then
			return 1
		fi
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
	local rel_path metadata meta_line validation_mode headings failed heading
	local -a warning_artifacts=()
	local -a blocking_artifacts=()
	local -a heading_list

	while IFS= read -r rel_path; do
		[[ -n "$rel_path" ]] || continue
		metadata="$(eaw_phase_completion_artifact_object_metadata "$phase_file" "$rel_path")"
		[[ -n "$metadata" ]] || continue
		validation_mode=""
		headings=""
		while IFS= read -r meta_line; do
			case "$meta_line" in
			validation_mode=*) validation_mode="${meta_line#validation_mode=}" ;;
			required_headings=*) headings="${meta_line#required_headings=}" ;;
			esac
		done <<<"$metadata"
		[[ -n "$validation_mode" ]] || validation_mode="warning"
		failed=0
		if [[ "$rel_path" == "investigations/20_handoff.json" || "$rel_path" == "investigations/10_phase_output.json" ]]; then
			continue
		fi
		# No size floor: substantiveness is validated by required_headings only (identity).
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

	# Mapa fixo artefato->fase produtora (mantem o recorte por fase: 00_scope.lock/
	# 10_change_plan so em implementation_executor).
	local -a rel_paths=(
		investigations/20_findings.md
		investigations/30_hypotheses.md
		investigations/40_next_steps.md
	)
	local -a producers=(
		findings
		hypotheses
		planning
	)
	if [[ "$phase_id" == "implementation_executor" ]]; then
		rel_paths+=(
			implementation/00_scope.lock.md
			implementation/10_change_plan.md
		)
		producers+=(
			implementation_planning
			implementation_planning
		)
	fi

	# Fonte duravel do skip (H2): completed_phases do state_card_<track>.yaml em card_dir.
	local state_unresolved=0
	local state_file="" track_id="" completed=""
	local -a state_matches=()
	local match
	while IFS= read -r match; do
		[[ -n "$match" ]] && state_matches+=("$match")
	done < <(compgen -G "$card_dir/state_card_*.yaml" 2>/dev/null || true)
	if [[ ${#state_matches[@]} -ne 1 || ! -r "${state_matches[0]:-}" ]]; then
		state_unresolved=1
	else
		state_file="${state_matches[0]}"
		track_id="$(basename "$state_file")"
		track_id="${track_id#state_card_}"
		track_id="${track_id%.yaml}"
		completed="$(eaw_yaml_state_completed_phases "$state_file" 2>/dev/null || true)"
	fi

	local -A completed_set=()
	if [[ "$state_unresolved" -eq 0 ]]; then
		local phase_line
		while IFS= read -r phase_line; do
			[[ -n "$phase_line" ]] && completed_set["$phase_line"]=1
		done <<<"$completed"
	fi

	# Clausula (2) le a track oficial da track corrente; irresolvivel -> fail-safe.
	local track_dir="" track_dir_unresolved=0
	if [[ "$state_unresolved" -eq 0 ]]; then
		if ! track_dir="$(eaw_official_track_dir "$track_id" 2>/dev/null)"; then
			track_dir_unresolved=1
			track_dir=""
		fi
	fi

	local i producer require phase_file artifact_re
	for i in "${!rel_paths[@]}"; do
		rel_path="${rel_paths[$i]}"
		producer="${producers[$i]}"
		if [[ "$state_unresolved" -eq 1 ]]; then
			require=1
		elif [[ -z "${completed_set[$producer]:-}" ]]; then
			require=0
		elif [[ "$track_dir_unresolved" -eq 1 ]]; then
			require=1
		else
			phase_file="$track_dir/phases/${producer}.yaml"
			if [[ ! -r "$phase_file" ]]; then
				require=1
			else
				artifact_re="$(printf '%s' "$rel_path" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g')"
				if grep -Eq "^[[:space:]]*-[[:space:]]+(path:[[:space:]]+)?${artifact_re}[[:space:]]*$" "$phase_file"; then
					require=1
				else
					require=0
				fi
			fi
		fi
		if [[ "$require" -eq 1 ]] && ! eaw_phase_completion_artifact_has_meaningful_content "$card" "$card_dir" "$producer" "$rel_path"; then
			missing_artifacts+=("$rel_path")
		fi
	done

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
