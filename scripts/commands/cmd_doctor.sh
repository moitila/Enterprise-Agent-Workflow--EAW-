#!/usr/bin/env bash

cmd_doctor() {
	local warnings=0
	local errors=0
	local status="OK"
	local config_version=""

	echo "EAW doctor"
	echo "Resolved dirs:"
	echo "  RUNTIME_ROOT=$EAW_ROOT_DIR"
	echo "  CONFIG_SOURCE=$REPOS_CONF"
	echo "  EAW_ROOT_DIR=$EAW_ROOT_DIR"
	echo "  EAW_WORKDIR=${EAW_WORKDIR:-}"
	echo "  EAW_CONFIG_DIR=$EAW_CONFIG_DIR"
	echo "  EAW_TEMPLATES_DIR=$EAW_TEMPLATES_DIR"
	echo "  EAW_OUT_DIR=$EAW_OUT_DIR"
	echo "  Tip: use 'eaw status <CARD>' for a single card or 'eaw status --all' for the global status list."

	echo "Tools:"
	if command -v git >/dev/null 2>&1; then echo "  git: OK"; else
		echo "  git: MISSING"
		warnings=$((warnings + 1))
	fi
	if command -v rg >/dev/null 2>&1; then
		echo "  rg: OK"
	elif command -v grep >/dev/null 2>&1; then
		echo "  rg: MISSING (grep fallback: OK)"
		warnings=$((warnings + 1))
	else
		echo "  rg/grep: MISSING"
		errors=$((errors + 1))
	fi
	if command -v awk >/dev/null 2>&1; then
		if echo '' | awk 'BEGIN { match("test", /t(e)/, arr); print arr[1] }' 2>/dev/null | grep -q 'e'; then
			echo "  awk: OK"
		else
			echo "  awk: WARN (match/3 not supported; runtime requires gawk)"
			warnings=$((warnings + 1))
		fi
	else
		echo "  awk: MISSING"
		errors=$((errors + 1))
	fi
	if command -v sed >/dev/null 2>&1; then echo "  sed: OK"; else
		echo "  sed: MISSING"
		errors=$((errors + 1))
	fi
	echo "  bash: $(bash --version | head -n 1)"

	echo "Files:"
	if [[ -f "$REPOS_CONF" ]]; then echo "  repos.conf: OK ($REPOS_CONF)"; else
		echo "  repos.conf: MISSING ($REPOS_CONF)"
		[[ -n "${EAW_WORKDIR:-}" ]] && errors=$((errors + 1)) || warnings=$((warnings + 1))
	fi
	if [[ -f "$SEARCH_CONF" ]]; then echo "  search.conf: OK ($SEARCH_CONF)"; else
		echo "  search.conf: MISSING ($SEARCH_CONF)"
		warnings=$((warnings + 1))
	fi
	if [[ -f "$EAW_CONF" ]]; then
		if config_version="$(read_config_version "$EAW_CONF")"; then
			echo "  eaw.conf: OK ($EAW_CONF, config_version=$config_version)"
		else
			echo "  eaw.conf: WARN ($EAW_CONF, config_version missing)"
			warnings=$((warnings + 1))
		fi
	else
		echo "  eaw.conf: $(eaw_conf_optional_formal_label) ($EAW_CONF missing; $(eaw_conf_optional_formal_contract_note))"
	fi

	if [[ -z "${EAW_SMOKE_SH:-}" ]]; then
		echo "  EAW_SMOKE_SH: WARN (not set)"
		warnings=$((warnings + 1))
	else
		echo "  EAW_SMOKE_SH: OK ($EAW_SMOKE_SH)"
	fi

	if [[ "$errors" -gt 0 ]]; then
		status="ERROR"
	elif [[ "$warnings" -gt 0 ]]; then
		status="WARN"
	fi
	echo "STATUS: $status (errors=$errors warnings=$warnings)"
	return 0
}
