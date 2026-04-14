#!/usr/bin/env bash

cmd_rollback() {
	local card="$1"
	local card_dir="$EAW_WORKDIR/out/$card"
	local scope_lock="$card_dir/implementation/00_scope.lock.md"

	if [[ ! -d "$card_dir" ]]; then
		echo "CARD $card: not found" >&2
		return 1
	fi

	if [[ ! -f "$scope_lock" ]]; then
		echo "CARD $card: no scope.lock found (no implementation to rollback)" >&2
		return 1
	fi

	# Extract target files from scope.lock (lines with backtick-wrapped paths)
	local files
	files="$(grep -E '^\s*-\s*`[^`]+`' "$scope_lock" | sed 's/.*`\([^`]*\)`.*/\1/' | head -20)"

	if [[ -z "$files" ]]; then
		echo "CARD $card: no target files found in scope.lock" >&2
		return 1
	fi

	# Resolve target repo from repos.conf
	local target_repo
	target_repo="$(grep '|target' "$EAW_CONFIG_DIR/repos.conf" | head -1 | cut -d'|' -f2)"

	if [[ -z "$target_repo" || ! -d "$target_repo" ]]; then
		echo "CARD $card: target repo not found" >&2
		return 1
	fi

	echo "CARD $card: rolling back files in $target_repo"
	local file restored=0 failed=0
	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		local full_path="$target_repo/$file"
		if [[ -f "$full_path" ]]; then
			if (cd "$target_repo" && git checkout HEAD -- "$file" 2>/dev/null); then
				echo "  restored: $file"
				restored=$((restored + 1))
			else
				echo "  FAILED: $file (git checkout failed)" >&2
				failed=$((failed + 1))
			fi
		else
			echo "  skipped: $file (not found)"
		fi
	done <<< "$files"

	echo "CARD $card: rollback complete — restored=$restored failed=$failed"
	[[ "$failed" -eq 0 ]]
}
