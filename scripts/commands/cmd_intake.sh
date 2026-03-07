#!/usr/bin/env bash

cmd_intake() {
	local card="${1:-}"
	local round_arg="${2:-}"
	local round="1"
	local out_root="$EAW_OUT_DIR"
	local card_dir_anchor="out/<CARD>"
	local card_dir
	local investigations_dir
	local body_template
	local prompt_file
	local eaw_workdir_value="${EAW_WORKDIR:-<resolved>}"
	local config_source="$REPOS_CONF"

	if [[ "$card" == "--help" || "$card" == "-h" ]]; then
		usage
		return 0
	fi

	if [[ -n "$round_arg" ]]; then
		if [[ "$round_arg" =~ ^--round=([0-9]+)$ ]]; then
			round="${BASH_REMATCH[1]}"
		else
			die "usage: eaw intake <CARD> [--round=N]"
		fi
	fi

	if ! body_template="$(load_prompt "default" "intake" "$card" "$out_root")"; then
		die "failed to resolve intake prompt via ACTIVE"
	fi

	card_dir="$out_root/$card"
	investigations_dir="$card_dir/investigations"
	prompt_file="$investigations_dir/intake_agent_prompt.round_${round}.md"
	assert_write_scope "intake" "ensure_dir card_dir" "$card_dir" "$out_root"
	assert_write_scope "intake" "ensure_dir investigations" "$investigations_dir" "$out_root"
	assert_write_scope "intake" "write intake prompt" "$prompt_file" "$out_root"
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
		-e "s|{{CARD_DIR}}|$card_dir_anchor|g" \
		| tee "$prompt_file"

	echo "Wrote $prompt_file" >&2
}
