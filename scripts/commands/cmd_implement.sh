#!/usr/bin/env bash

cmd_implement() {
	local card="${1:-}"
	local card_dir impl_dir type
	local created=0
	local preserved=0
	local planning_rel="prompts/default/implementation_planning/prompt_v1.md"
	local executor_rel="prompts/default/implementation_executor/prompt_v1.md"
	local planning_template="$EAW_TEMPLATES_DIR/$planning_rel"
	local executor_template="$EAW_TEMPLATES_DIR/$executor_rel"
	local fallback_planning="$EAW_ROOT_DIR/templates/$planning_rel"
	local fallback_executor="$EAW_ROOT_DIR/templates/$executor_rel"
	local planning_prompt executor_prompt
	local repo_blocks target_repos excluded_repos
	local eaw_workdir_value warnings_block
	local type_warnings=()

	render_implement_prompt() {
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
			-v out_dir="$EAW_OUT_DIR" \
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

	if [[ -z "$card" ]]; then
		die "missing <CARD> argument"
	fi
	if [[ ! "$card" =~ ^[A-Za-z0-9_-]+$ ]]; then
		die "invalid <CARD> '$card' (expected [A-Za-z0-9_-]+)"
	fi

	card_dir="$EAW_OUT_DIR/$card"
	if [[ ! -d "$card_dir" ]]; then
		die "card output directory not found: $card_dir"
	fi

	detect_card_type_with_warnings "$card" "$card_dir" type type_warnings

	impl_dir="$card_dir/implementation"
	if [[ -d "$impl_dir" ]]; then
		echo "PRESERVED: $impl_dir"
		preserved=$((preserved + 1))
	else
		ensure_dir "$impl_dir"
		echo "CREATED: $impl_dir"
		created=$((created + 1))
	fi

	for name in 00_scope.lock.md 10_change_plan.md 20_patch_notes.md; do
		local target="$impl_dir/$name"
		if [[ -f "$target" ]]; then
			echo "PRESERVED: $target"
			preserved=$((preserved + 1))
			continue
		fi
		case "$name" in
		00_scope.lock.md)
			cat >"$target" <<EOF
# Scope Lock - Card $card

## In Scope

## Out of Scope
EOF
			;;
		10_change_plan.md)
			cat >"$target" <<EOF
# Change Plan - Card $card

## Steps

## Validation
EOF
			;;
		20_patch_notes.md)
			cat >"$target" <<EOF
# Patch Notes - Card $card

## Changes

## Risks
EOF
			;;
		esac
		echo "CREATED: $target"
		created=$((created + 1))
	done

	if [[ ! -f "$planning_template" ]]; then
		if [[ -f "$fallback_planning" ]]; then
			planning_template="$fallback_planning"
		else
			die "template not found: $planning_template"
		fi
	fi
	if [[ ! -f "$executor_template" ]]; then
		if [[ -f "$fallback_executor" ]]; then
			executor_template="$fallback_executor"
		else
			die "template not found: $executor_template"
		fi
	fi

	planning_prompt="$impl_dir/implementation_planning_agent_prompt.md"
	executor_prompt="$impl_dir/implementation_executor_agent_prompt.md"
	repo_blocks="$(collect_repos_lists)"
	target_repos="$(printf "%s\n" "$repo_blocks" | sed -n '1,/^$/p' | sed '/^$/d')"
	excluded_repos="$(printf "%s\n" "$repo_blocks" | sed -n '/^$/,$p' | sed '1d;/^$/d')"
	eaw_workdir_value="${EAW_WORKDIR:-}"
	warnings_block="- none"

	render_implement_prompt "IMPLEMENTATION PLANNING" "$planning_template" "$planning_prompt"
	render_implement_prompt "IMPLEMENTATION EXECUTOR" "$executor_template" "$executor_prompt"

	echo "SUMMARY: created=$created preserved=$preserved"
}
