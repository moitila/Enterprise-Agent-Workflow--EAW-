#!/usr/bin/env bash

cmd_analyze() {
	local card="${1:-}"
	local out_root="$EAW_OUT_DIR"
	local card_dir
	local findings_template hypotheses_template planning_template
	local findings_prompt_file
	local hypotheses_prompt_file
	local planning_prompt_file
	local intake_file
	local type=""
	local warnings=()
	local repo_blocks target_repos excluded_repos warnings_block eaw_workdir_value

	render_analyze_prompt() {
		local phase_header="$1"
		local body_template="$2"
		local output_file="$3"

		cat "$body_template" | awk \
				-v phase_header="$phase_header" \
				-v card="$card" \
				-v type="$type" \
			-v eaw_workdir="$eaw_workdir_value" \
			-v runtime_root="$EAW_ROOT_DIR" \
			-v config_source="$REPOS_CONF" \
				-v out_dir="$out_root" \
				-v card_dir="$card_dir" \
				-v target_repos="$target_repos" \
				-v excluded_repos="$excluded_repos" \
				-v warnings_block="$warnings_block" \
				'
				{
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
				gsub(/\{\{PHASE_HEADER\}\}/, phase_header)
				gsub(/\{\{CARD\}\}/, card)
				gsub(/\{\{TYPE\}\}/, type)
				gsub(/\{\{EAW_WORKDIR\}\}/, eaw_workdir)
				gsub(/\{\{RUNTIME_ROOT\}\}/, runtime_root)
				gsub(/\{\{CONFIG_SOURCE\}\}/, config_source)
				gsub(/\{\{OUT_DIR\}\}/, out_dir)
				gsub(/\{\{CARD_DIR\}\}/, card_dir)
				print
			}
			' | tee "$output_file"

		echo "Wrote $output_file" >&2
	}

	if [[ "$card" == "--help" || "$card" == "-h" ]]; then
		usage
		return 0
	fi

	card_dir="$out_root/$card"
	findings_prompt_file="$card_dir/investigations/findings_agent_prompt.md"
	hypotheses_prompt_file="$card_dir/investigations/hypotheses_agent_prompt.md"
	planning_prompt_file="$card_dir/investigations/planning_agent_prompt.md"
	intake_file="$card_dir/investigations/00_intake.md"

	detect_card_type_with_warnings "$card" "$card_dir" type warnings

	if [[ ! -f "$intake_file" ]]; then
		append_warn warnings "missing intake file: $intake_file"
	else
		case "$type" in
		bug)
			validate_intake_heading_group "$intake_file" warnings "Resumo do problema ou Resumo" '^##[[:space:]]*(Resumo do problema|Resumo)[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Comportamento esperado" '^##[[:space:]]*Comportamento esperado[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Comportamento atual" '^##[[:space:]]*Comportamento atual[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Passos para reproduzir" '^##[[:space:]]*Passos para reproduzir[[:space:]]*$'
			;;
		feature)
			validate_intake_heading_group "$intake_file" warnings "Problema ou Objetivo" '^##[[:space:]]*(Problema|Objetivo)[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Critérios de aceite" '^##[[:space:]]*Critérios de aceite[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Escopo" '^##[[:space:]]*Escopo([[:space:]]*\(In/Out\))?[[:space:]]*$'
			;;
		spike)
			validate_intake_heading_group "$intake_file" warnings "Pergunta ou Hipótese" '^##[[:space:]]*(Pergunta[[:space:]]*/[[:space:]]*Hipótese|Pergunta|Hipótese)[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Critério de conclusão" '^##[[:space:]]*Critério de conclusão[[:space:]]*$'
			;;
		esac
		if ! intake_has_section_headings "$intake_file" || intake_is_structurally_incomplete "$type" "$intake_file"; then
			append_warn warnings "intake appears structurally incomplete."
			append_warn warnings "DO NOT START INVESTIGATION BEFORE COMPLETING REQUIRED SECTIONS."
		fi
	fi

	ensure_dir "$card_dir"
	ensure_dir "$card_dir/investigations"
	ensure_dir "$card_dir/inputs"
	eaw_workdir_value="${EAW_WORKDIR:-}"

	if ! findings_template="$(load_prompt "default" "analyze_findings" "$card" "$out_root")"; then
		die "failed to resolve analyze_findings prompt via ACTIVE"
	fi
	if ! hypotheses_template="$(load_prompt "default" "analyze_hypotheses" "$card" "$out_root")"; then
		die "failed to resolve analyze_hypotheses prompt via ACTIVE"
	fi
	if ! planning_template="$(load_prompt "default" "analyze_planning" "$card" "$out_root")"; then
		die "failed to resolve analyze_planning prompt via ACTIVE"
	fi

	repo_blocks="$(collect_repos_lists)"
	target_repos="$(printf "%s\n" "$repo_blocks" | sed -n '1,/^$/p' | sed '/^$/d')"
	excluded_repos="$(printf "%s\n" "$repo_blocks" | sed -n '/^$/,$p' | sed '1d;/^$/d')"
	if [[ ${#warnings[@]} -eq 0 ]]; then
		warnings_block="- none"
	else
		warnings_block=""
		for warn in "${warnings[@]}"; do
			if [[ -n "$warnings_block" ]]; then
				warnings_block+=$'\n'
			fi
			if [[ "$warn" == "DO NOT START INVESTIGATION BEFORE COMPLETING REQUIRED SECTIONS." ]]; then
				warnings_block+="WARNING: $warn"
			else
				warnings_block+="WARN: $warn"
			fi
		done
	fi

	render_analyze_prompt "FINDINGS" "$findings_template" "$findings_prompt_file"
	render_analyze_prompt "HYPOTHESES" "$hypotheses_template" "$hypotheses_prompt_file"
	render_analyze_prompt "PLANNING" "$planning_template" "$planning_prompt_file"

	# create TEST_PLAN placeholder in outdir
	local test_plan="$card_dir/TEST_PLAN_${card}.md"
	if [[ ! -f "$test_plan" ]]; then
		cat >"$test_plan" <<TP
# Test Plan for ${type}_${card}

## Summary

Describe deterministic tests to validate changes.

## Unit Tests

- Add tests for ...

## Integration Tests

- Run ...

TP
		echo "Wrote $test_plan"
	fi
}
