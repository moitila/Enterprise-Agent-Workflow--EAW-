#!/usr/bin/env bash
set -euo pipefail

EAW_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf "%s\n" "$*" >&2; }

die() {
	printf "ERROR: %s\n" "$1" >&2
	exit 1
}

ensure_dir() {
	mkdir -p "$1"
}

iso_date() { date -u +%Y-%m-%d; }

# Resolve repository path: support absolute (/), home (~), or relative to EAW root
# Usage: resolve_repo_path "<path>"
# Output: canonical absolute path
resolve_repo_path() {
	local path="$1"
	if [[ -z "$path" ]]; then
		die "resolve_repo_path: empty path"
	fi
	if [[ "$path" == /* ]]; then
		# Absolute path
		printf '%s\n' "$path"
	elif [[ "$path" == ~/* ]]; then
		# Home-relative path
		printf '%s\n' "${path/#\~/$HOME}"
	else
		# Relative to EAW root
		printf '%s\n' "$EAW_BASE_DIR/$path"
	fi
}

render_template() {
	local tpl=$1
	shift
	local out=$1
	shift
	local card=$1
	shift
	local title=$1
	shift
	local type=$1
	shift
	local date=$1
	shift
	sed \
		-e "s/{{CARD}}/${card}/g" \
		-e "s/{{TITLE}}/${title}/g" \
		-e "s/{{TYPE}}/${type}/g" \
		-e "s/{{DATE}}/${date}/g" \
		"$tpl" >"$out"
}

# read repos.conf with lines key|path
load_repos() {
	local f="$1"
	if [[ ! -f "$f" ]]; then
		log "repos.conf missing: $f"
		return 1
	fi
	awk -F"|" '!/^\s*#/ && NF>=2 {print $1 "|" $2}' "$f"
}

# read search.conf and return non-empty non-comment lines
load_search_patterns() {
	local f="$1"
	if [[ ! -f "$f" ]]; then
		log "search.conf missing: $f"
		return 1
	fi
	grep -E -v '^\s*#' "$f" | sed '/^\s*$/d'
}

gather_context_for_repo() {
	local repoKey="$1"
	local repoPath="$2"
	local outdir="$3"

	# Validate repo exists and is a git repo
	if [[ ! -d "$repoPath" ]]; then
		log "repo path not found: $repoPath"
		return 1
	fi
	if ! git -C "$repoPath" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		log "not a git repo: $repoPath"
		return 1
	fi

	ensure_dir "$outdir"
	git -C "$repoPath" status --porcelain >"$outdir/git-status.txt" 2>&1 || true
	git -C "$repoPath" rev-parse --abbrev-ref HEAD >"$outdir/git-branch.txt" 2>&1 || true
	git -C "$repoPath" rev-parse HEAD >"$outdir/git-commit.txt" 2>&1 || true
	git -C "$repoPath" diff >"$outdir/git-diff.patch" 2>&1 || true
	git -C "$repoPath" diff --name-only >"$outdir/changed-files.txt" 2>&1 || true
}

collect_search_hits() {
	local repoKey="$1"
	local repoPath="$2"
	local outdir="$3"
	local searchConf="$4"
	local patterns
	patterns=$(load_search_patterns "$searchConf") || return 0
	ensure_dir "$outdir"
	local rg_cmd
	if command -v rg >/dev/null 2>&1; then
		rg_cmd="rg -n"
	elif command -v grep >/dev/null 2>&1; then
		rg_cmd="grep -R --line-number -n"
	else
		log "neither rg nor grep is available; skipping symbol search"
		echo "MISSING_TOOL" >"$outdir/rg-symbols.txt"
		return 0
	fi
	# Aggregate
	: >"$outdir/rg-symbols.txt"
	while IFS= read -r pat; do
		if [[ -z "$pat" ]]; then continue; fi
		if [[ "$rg_cmd" == "rg -n" ]]; then
			rg -n --hidden --no-ignore -S -- "$pat" "$repoPath" >>"$outdir/rg-symbols.txt" 2>/dev/null || true
		else
			grep -R --line-number -n --exclude-dir=.git -E "$pat" "$repoPath" >>"$outdir/rg-symbols.txt" 2>/dev/null || true
		fi
	done <<<"$patterns"
}
