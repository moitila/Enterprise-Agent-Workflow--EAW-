#!/usr/bin/env bash
# migrate_artifact_yaml_format.sh — BL-CI-03 / H1+H5
# Converts required_artifacts from string format to object format in all phase YAMLs
# that use COMPLETION_STRATEGY: required_artifacts_exist.
#
# Usage:
#   migrate_artifact_yaml_format.sh [--dry-run] [<tracks_dir>]
#
# Options:
#   --dry-run     List YAML files to be changed without modifying them
#   <tracks_dir>  Path to tracks directory (default: directory of this script's
#                 runtime root, i.e. RUNTIME_ROOT/tracks)
#
# Output format (stdout):
#   DRY-RUN: <file>                  — file would be migrated
#   SKIP (already migrated): <file>  — file already in object format
#   SKIP (no string items): <file>   — nothing to convert
#   MIGRATED: <file>                 — file was converted
#   CANDIDATE min_bytes:0 — <file>   — artifact template < 400 bytes (check manually)
#   SUMMARY: migrated=N skipped=N dry_run=N
#
# Exit code: 0 always (non-destructive; failures logged to stderr)

set -euo pipefail

# --- argument parsing ---
DRY_RUN=0
TRACKS_DIR=""

while [[ $# -gt 0 ]]; do
	case "$1" in
	--dry-run)
		DRY_RUN=1
		shift
		;;
	-*)
		echo "ERROR: unknown option '$1'" >&2
		exit 1
		;;
	*)
		TRACKS_DIR="$1"
		shift
		;;
	esac
done

# Resolve TRACKS_DIR from script location (RUNTIME_ROOT/tracks)
if [[ -z "$TRACKS_DIR" ]]; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	TRACKS_DIR="${SCRIPT_DIR}/../../tracks"
fi

TRACKS_DIR="$(cd "$TRACKS_DIR" 2>/dev/null && pwd)" || {
	echo "ERROR: tracks directory not found: $TRACKS_DIR" >&2
	exit 1
}

# --- counters ---
count_migrated=0
count_skipped=0
count_dry=0

# --- transform function ---
# Converts string-format required_artifacts items in a YAML file to object format.
# Returns 0 if the file has items to migrate (string format found), 1 if already fully
# in object format or no items at all.
_file_needs_migration() {
	local file="$1"
	# Check for string-format items: lines matching "      - <path>" (not "      - path:")
	awk '
		/^    required_artifacts:/ { in_ra=1; next }
		in_ra && /^      - [^{]/ && !/^      - path:/ { found=1; exit }
		in_ra && /^  [a-z]/ { in_ra=0 }
		END { exit !found }
	' "$file"
}

_migrate_file() {
	local file="$1"
	local tmpfile
	tmpfile="$(mktemp)"

	awk '
		/^    required_artifacts:/ {
			in_ra=1
			print
			next
		}
		in_ra && /^      - path:/ {
			# Already object format — leave as-is and stay in section
			print
			next
		}
		in_ra && /^      - / && !/^      - path:/ {
			# String format item: extract path and emit object
			line=$0
			sub(/^      - /, "", line)
			print "      - path: " line
			print "        min_bytes: 500"
			print "        validation_mode: blocking"
			next
		}
		in_ra && /^  [a-z]/ {
			in_ra=0
		}
		{ print }
	' "$file" > "$tmpfile"

	if cmp -s "$file" "$tmpfile"; then
		rm -f "$tmpfile"
		return 1   # no change needed
	fi

	mv "$tmpfile" "$file"
	return 0
}

# --- small-artifact candidate detection ---
_check_small_artifacts() {
	local file="$1"
	local runtime_root
	runtime_root="$(cd "$TRACKS_DIR/.." && pwd)"

	awk '/^    required_artifacts:/{in_ra=1;next} in_ra && /^      - /{
		path=$0; sub(/^      - (path: )?/,"",path)
		print path
	} in_ra && /^  [a-z]/{in_ra=0}' "$file" | while IFS= read -r rel_path; do
		# Look for source scaffold templates — check in templates/ directories
		# This is a heuristic: we check if any scaffold file for this artifact path exists
		# and is small. We do not need to be exhaustive here.
		local base
		base="$(basename "$rel_path")"
		local candidates
		candidates="$(find "$runtime_root/templates" -name "$base" 2>/dev/null | head -3)"
		while IFS= read -r candidate_file; do
			[[ -f "$candidate_file" ]] || continue
			local sz
			sz="$(wc -c < "$candidate_file" 2>/dev/null || echo 999)"
			if [[ "$sz" -lt 400 ]]; then
				echo "CANDIDATE min_bytes:0 — $file (artifact: $rel_path, template_size=${sz})"
			fi
		done <<<"$candidates"
	done
}

# --- main loop ---
while IFS= read -r yaml_file; do
	# Check if file has string-format items to migrate
	if ! _file_needs_migration "$yaml_file"; then
		# Check if already fully object format or nothing to do
		if awk '/^    required_artifacts:/{in_ra=1;next} in_ra && /^      - path:/{found=1;exit}' "$yaml_file" | grep -q .; then
			echo "SKIP (already migrated): $yaml_file"
		else
			echo "SKIP (no string items): $yaml_file"
		fi
		(( count_skipped++ )) || true
		continue
	fi

	if [[ "$DRY_RUN" -eq 1 ]]; then
		echo "DRY-RUN: $yaml_file"
		(( count_dry++ )) || true
		continue
	fi

	if _migrate_file "$yaml_file"; then
		echo "MIGRATED: $yaml_file"
		_check_small_artifacts "$yaml_file"
		(( count_migrated++ )) || true
	else
		echo "SKIP (no change): $yaml_file"
		(( count_skipped++ )) || true
	fi

done < <(grep -rl "required_artifacts_exist" "$TRACKS_DIR" --include="*.yaml" | sort)

echo "SUMMARY: migrated=${count_migrated} skipped=${count_skipped} dry_run=${count_dry}"
