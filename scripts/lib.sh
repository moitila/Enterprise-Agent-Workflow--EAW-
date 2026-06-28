#!/usr/bin/env bash
set -euo pipefail

resolve_script_parent_dir() {
	local source_path="$1"
	while [[ -L "$source_path" ]]; do
		local source_dir
		source_dir="$(cd -P "$(dirname "$source_path")" && pwd)"
		source_path="$(readlink "$source_path")"
		[[ "$source_path" == /* ]] || source_path="$source_dir/$source_path"
	done
	cd -P "$(dirname "$source_path")/.." && pwd
}

EAW_BASE_DIR="$(resolve_script_parent_dir "${BASH_SOURCE[0]}")"

log() { printf "%s\n" "$*" >&2; }

die() {
	printf "ERROR: %s\n" "$1" >&2
	exit 1
}

eaw_require_command() {
	local cmd="$1"
	command -v "$cmd" >/dev/null 2>&1 || die "missing required tool: $cmd"
}

eaw_is_probably_text_file() {
	local file="$1"
	[[ -f "$file" ]] || return 1
	if [[ ! -s "$file" ]]; then
		return 0
	fi
	LC_ALL=C grep -Iq . "$file" 2>/dev/null
}

ensure_dir() {
	mkdir -p "$1"
}

iso_date() { date -u +%Y-%m-%d; }

utc_timestamp() { date -u +%Y-%m-%dT%H:%M:%SZ; }

resolve_workdirs() {
	local root_dir="${1:-$EAW_BASE_DIR}"
	EAW_ROOT_DIR="$root_dir"
	EAW_WORKDIR="${EAW_WORKDIR:-}"

	if [[ -n "$EAW_WORKDIR" ]]; then
		EAW_CONFIG_DIR="$EAW_WORKDIR/config"
		EAW_TEMPLATES_DIR="$EAW_ROOT_DIR/templates"
		EAW_TRACKS_DIR="$EAW_ROOT_DIR/tracks"
		EAW_OUT_DIR="${EAW_OUT_DIR:-$EAW_WORKDIR/out}"
	else
		EAW_CONFIG_DIR="$EAW_ROOT_DIR/config"
		EAW_TEMPLATES_DIR="$EAW_ROOT_DIR/templates"
		EAW_TRACKS_DIR="$EAW_ROOT_DIR/tracks"
		EAW_OUT_DIR="${EAW_OUT_DIR:-$EAW_ROOT_DIR/out}"
	fi
}

# Resolve repository path: support absolute (/), home (~), or relative to EAW root
# Usage: resolve_repo_path "<path>"
# Output: absolute resolved path (non-canonical)
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
		# Relative path follows workspace root when workspace mode is enabled.
		if [[ -n "${EAW_WORKDIR:-}" ]]; then
			printf '%s\n' "${EAW_WORKDIR}/$path"
		else
			printf '%s\n' "${EAW_ROOT_DIR:-$EAW_BASE_DIR}/$path"
		fi
	fi
}

canonicalize_scope_path() {
	local path="$1"
	if command -v realpath >/dev/null 2>&1; then
		realpath -m -- "$path"
		return 0
	fi
	if [[ "$path" != /* ]]; then
		path="$PWD/$path"
	fi
	local IFS='/'
	local -a parts
	local -a stack=()
	local part
	read -r -a parts <<<"$path"
	for part in "${parts[@]}"; do
		case "$part" in
		"" | ".")
			continue
			;;
		"..")
			if [[ ${#stack[@]} -gt 0 ]]; then
				unset 'stack[${#stack[@]}-1]'
			fi
			;;
		*)
			stack+=("$part")
			;;
		esac
	done
	if [[ ${#stack[@]} -eq 0 ]]; then
		printf '/\n'
		return 0
	fi
	printf '/%s\n' "$(
		IFS=/
		echo "${stack[*]}"
	)"
}

assert_write_scope() {
	local phase="$1"
	local command_name="$2"
	local target_path="$3"
	shift 3
	local target_abs
	target_abs="$(canonicalize_scope_path "$target_path")"
	local allowed_raw allowed_abs
	for allowed_raw in "$@"; do
		allowed_abs="$(canonicalize_scope_path "$allowed_raw")"
		if [[ "$target_abs" == "$allowed_abs" || "$target_abs" == "$allowed_abs/"* ]]; then
			return 0
		fi
	done
	printf 'WRITE_SCOPE_VIOLATION: phase=%s command=%s blocked_path=%s\n' \
		"$phase" "$command_name" "$target_abs" >&2
	return 97
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
	local sed_delim='|'
	local escaped_card escaped_title escaped_type escaped_date

	escape_sed_replacement() {
		local value="$1"
		local delimiter="$2"
		value="${value//\\/\\\\}"
		value="${value//&/\\&}"
		value="${value//"$delimiter"/\\$delimiter}"
		printf '%s' "$value"
	}

	escaped_card="$(escape_sed_replacement "$card" "$sed_delim")"
	escaped_title="$(escape_sed_replacement "$title" "$sed_delim")"
	escaped_type="$(escape_sed_replacement "$type" "$sed_delim")"
	escaped_date="$(escape_sed_replacement "$date" "$sed_delim")"
	sed \
		-e "s${sed_delim}{{CARD}}${sed_delim}${escaped_card}${sed_delim}g" \
		-e "s${sed_delim}{{TITLE}}${sed_delim}${escaped_title}${sed_delim}g" \
		-e "s${sed_delim}{{TYPE}}${sed_delim}${escaped_type}${sed_delim}g" \
		-e "s${sed_delim}{{DATE}}${sed_delim}${escaped_date}${sed_delim}g" \
		"$tpl" >"$out"
}

# read repos.conf with lines key|path
load_repos() {
	local f="$1"
	if [[ ! -f "$f" ]]; then
		log "repos.conf missing: $f"
		return 1
	fi
	awk -F"|" '!/^[[:space:]]*#/ && NF>=2 {print $1 "|" $2}' "$f"
}

# read search.conf and return non-empty non-comment lines
load_search_patterns() {
	local f="$1"
	if [[ ! -f "$f" ]]; then
		log "search.conf missing: $f"
		return 1
	fi
	grep -E -v '^[[:space:]]*#' "$f" | sed -e 's/\r$//' -e '/^[[:space:]]*$/d'
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
	# allowed to fail: best-effort collection; failures are captured in output
	if ! git -C "$repoPath" status --porcelain >"$outdir/git-status.txt" 2>&1; then
		echo "allowed to fail: best-effort collection; git status failed (see $outdir/git-status.txt)" >>"$outdir/_warnings.txt"
	fi
	if ! git -C "$repoPath" rev-parse --abbrev-ref HEAD >"$outdir/git-branch.txt" 2>&1; then
		echo "allowed to fail: best-effort collection; rev-parse branch failed (see $outdir/git-branch.txt)" >>"$outdir/_warnings.txt"
	fi
	if ! git -C "$repoPath" rev-parse HEAD >"$outdir/git-commit.txt" 2>&1; then
		echo "allowed to fail: best-effort collection; rev-parse HEAD failed (see $outdir/git-commit.txt)" >>"$outdir/_warnings.txt"
	fi
	# allowed to fail: best-effort collection; failures are captured in output
	if ! git -C "$repoPath" diff >"$outdir/git-diff.patch" 2>&1; then
		echo "allowed to fail: best-effort collection; git diff failed (see $outdir/git-diff.patch)" >>"$outdir/_warnings.txt"
	fi
	if git -C "$repoPath" diff --name-only >"$outdir/changed-files.txt" 2>&1; then
		sort -u "$outdir/changed-files.txt" -o "$outdir/changed-files.txt" 2>/dev/null || true
	else
		echo "allowed to fail: best-effort collection; git diff --name-only failed (see $outdir/changed-files.txt)" >>"$outdir/_warnings.txt"
	fi
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
			# allowed to fail: best-effort collection; failures are captured in output
			if ! rg -n --hidden --no-ignore -S -- "$pat" "$repoPath" >>"$outdir/rg-symbols.txt" 2>/dev/null; then
				echo "allowed to fail: best-effort collection; rg failed or no matches for pattern '$pat' (see $outdir/rg-symbols.txt)" >>"$outdir/_warnings.txt"
			fi
		else
			# allowed to fail: best-effort collection; failures are captured in output
			if ! grep -R --line-number -n --exclude-dir=.git -E "$pat" "$repoPath" >>"$outdir/rg-symbols.txt" 2>/dev/null; then
				echo "allowed to fail: best-effort collection; grep failed or no matches for pattern '$pat' (see $outdir/rg-symbols.txt)" >>"$outdir/_warnings.txt"
			fi
		fi
	done <<<"$patterns"
}
