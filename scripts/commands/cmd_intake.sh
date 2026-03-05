#!/usr/bin/env bash

cmd_intake() {
	local card="$1"
	local round_arg="${2:-}"
	local round="1"
	local out_root="$EAW_OUT_DIR"
	local card_dir="$out_root/$card"
	local investigations_dir="$card_dir/investigations"
	local body_rel="prompts/default/intake/prompt_v1.md"
	local body_template="$EAW_TEMPLATES_DIR/$body_rel"
	local fallback_body="$EAW_ROOT_DIR/templates/$body_rel"
	local prompt_file="$investigations_dir/intake_agent_prompt.round_${round}.md"
	local eaw_workdir_value="${EAW_WORKDIR:-<resolved>}"
	local config_source="$REPOS_CONF"

	if [[ -n "$round_arg" ]]; then
		if [[ "$round_arg" =~ ^--round=([0-9]+)$ ]]; then
			round="${BASH_REMATCH[1]}"
		else
			die "usage: eaw intake <CARD> [--round=N]"
		fi
	fi

	if [[ ! -f "$body_template" ]]; then
		if [[ -f "$fallback_body" ]]; then
			body_template="$fallback_body"
		else
			die "template not found: $body_template"
		fi
	fi

	prompt_file="$investigations_dir/intake_agent_prompt.round_${round}.md"
	ensure_dir "$card_dir"
	ensure_dir "$investigations_dir"

	{
		cat "$body_template"
	} | sed \
		-e "s|{{CARD}}|$card|g" \
		-e "s|{{ROUND}}|$round|g" \
		-e "s|{{EAW_WORKDIR}}|$eaw_workdir_value|g" \
		-e "s|{{RUNTIME_ROOT}}|$EAW_ROOT_DIR|g" \
		-e "s|{{CONFIG_SOURCE}}|$config_source|g" \
		-e "s|{{OUT_DIR}}|$out_root|g" \
		-e "s|{{CARD_DIR}}|$card_dir|g" \
		| tee "$prompt_file"

	echo "Wrote $prompt_file" >&2
}
