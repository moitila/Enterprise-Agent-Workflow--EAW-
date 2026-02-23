#!/usr/bin/env bash

cmd_init() {
	local force="false"
	local workdir=""
	local upgrade="false"
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--workdir)
			shift
			if [[ $# -lt 1 || -z "${1:-}" ]]; then
				echo "Missing value for --workdir" >&2
				exit 1
			fi
			workdir="$1"
			;;
		--force)
			force="true"
			;;
		--upgrade)
			upgrade="true"
			;;
		*)
			echo "Unknown init option: $1" >&2
			usage
			exit 1
			;;
		esac
		shift
	done

	if [[ -n "$workdir" ]]; then
		init_workspace_workdir "$workdir" "$force" "$upgrade"
		return 0
	fi

	if [[ "$upgrade" == "true" ]]; then
		echo "--upgrade requires --workdir <path>" >&2
		exit 1
	fi

	ensure_dir "$CONFIG_DIR"
	if [[ -f "$SCRIPT_DIR/sync-repos-config.sh" ]]; then
		bash "$SCRIPT_DIR/sync-repos-config.sh"
	else
		if [[ ! -f "$REPOS_CONF" ]]; then
			cp "$CONFIG_DIR/repos.example.conf" "$REPOS_CONF"
			echo "Created $REPOS_CONF"
		else
			echo "$REPOS_CONF already exists; skipping"
		fi
	fi
	if [[ ! -f "$SEARCH_CONF" ]]; then
		cp "$CONFIG_DIR/search.example.conf" "$SEARCH_CONF"
		echo "Created $SEARCH_CONF"
	else
		echo "$SEARCH_CONF already exists; skipping"
	fi
}
