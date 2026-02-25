#!/usr/bin/env bash

cmd_intake() {
	local card="$1"
	local round_arg="${2:-}"
	local round="1"
	local out_root="$EAW_OUT_DIR"
	local card_dir="$out_root/$card"
	local investigations_dir="$card_dir/investigations"
	local template="$EAW_TEMPLATES_DIR/intake/pt-br/intake_prompt_v2.md"
	local prompt_file="$investigations_dir/intake_agent_prompt.round_${round}.md"
	local eaw_workdir_value="${EAW_WORKDIR:-<resolved>}"

	if [[ -n "$round_arg" ]]; then
		if [[ "$round_arg" =~ ^--round=([0-9]+)$ ]]; then
			round="${BASH_REMATCH[1]}"
		else
			die "usage: eaw intake <CARD> [--round=N]"
		fi
	fi

	if [[ ! -f "$template" ]]; then
		die "template not found: $template"
	fi

	prompt_file="$investigations_dir/intake_agent_prompt.round_${round}.md"
	ensure_dir "$card_dir"
	ensure_dir "$investigations_dir"

	sed \
		-e "s|{{CARD}}|$card|g" \
		-e "s|{{ROUND}}|$round|g" \
		-e "s|{{EAW_WORKDIR}}|$eaw_workdir_value|g" \
		-e "s|{{RUNTIME_ROOT}}|$EAW_ROOT_DIR|g" \
		-e "s|{{OUT_DIR}}|$out_root|g" \
		-e "s|{{CARD_DIR}}|$card_dir|g" \
		"$template" | tee "$prompt_file"

	echo "Wrote $prompt_file" >&2
}
