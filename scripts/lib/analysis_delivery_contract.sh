#!/usr/bin/env bash

# Shared, fail-closed helpers for explicitly selected target evidence.
# The phase YAML is the authorization declaration; TARGET_REPOSITORIES alone
# never grants access to repository contents.

eaw_delivery_phase_sources() {
	local file="${1:-}"
	[[ -n "$file" && -f "$file" ]] || return 0
	awk '
		function emit() { if (in_item) printf "%s\t%s\t%s\n", repo, paths, required }
		BEGIN { in_phase=0; in_sources=0; in_item=0; in_paths=0 }
		/^phase:[[:space:]]*$/ { in_phase=1; next }
		in_phase && /^[^[:space:]]/ { in_phase=0; in_sources=0 }
		in_phase && /^  evidence_sources:[[:space:]]*$/ { in_sources=1; next }
		in_sources && /^  [^[:space:]]/ { in_sources=0; in_item=0; in_paths=0 }
		in_sources && /^    - repository:[[:space:]]*/ {
			emit()
			line=$0; sub(/^    - repository:[[:space:]]*/, "", line)
			repo=line; paths=""; required="false"; in_item=1; in_paths=0; next
		}
		in_sources && in_item && /^      paths:[[:space:]]*$/ { in_paths=1; next }
		in_sources && in_item && in_paths && /^        - / {
			line=$0; sub(/^        - /, "", line); if (substr(line,1,1)=="\047" || substr(line,1,1)=="\042") line=substr(line,2,length(line)-2)
			paths=paths (paths == "" ? "" : "\034") line; next
		}
		in_sources && in_item && /^      required:[[:space:]]*/ {
			line=$0; sub(/^      required:[[:space:]]*/, "", line); required=line; in_paths=0; next
		}
		in_sources && in_item && /^      [a-z_]+:/ { in_paths=0 }
		END { emit() }
	' "$file"
}

# Card-scoped source authorization: each exact path/glob is supplied by the
# card scope artifact; the phase only delegates to this named artifact.
eaw_delivery_scope_sources() {
	local file="${1:-}"
	[[ -n "$file" && -f "$file" ]] || return 0
	awk '
		function emit( i,n,a) { if (record) { n=split(paths,a,"\034"); for(i=1;i<=n;i++) if(a[i]!="") printf "%s\t%s\t%s\n", repo, a[i], required } }
		/^authorized_sources:[[:space:]]*$/ { in_sources=1; next }
		in_sources && /^[^[:space:]]/ { in_sources=0 }
		in_sources && /^  - (repo_key|repository):[[:space:]]*/ { emit(); v=$0; sub(/^  - (repo_key|repository):[[:space:]]*/, "", v); repo=v; paths=""; required=""; record=1; next }
		in_sources && record && /^    (path|paths):[[:space:]]*/ { v=$0; sub(/^    (path|paths):[[:space:]]*/, "", v); if(v!="") {if(substr(v,1,1)=="\047" || substr(v,1,1)=="\042") v=substr(v,2,length(v)-2); paths=paths (paths=="" ? "" : "\034") v}; in_paths=(v==""); next }
		in_sources && record && in_paths && /^      - / { v=$0; sub(/^      - /, "", v); if(substr(v,1,1)=="\047" || substr(v,1,1)=="\042") v=substr(v,2,length(v)-2); paths=paths (paths=="" ? "" : "\034") v; next }
		in_sources && record && /^    required:[[:space:]]*/ { v=$0; sub(/^    required:[[:space:]]*/, "", v); required=v; next }
		in_sources && record && /^    [a-z_]+:/ { in_paths=0 }
		END { emit() }
	' "$file"
}

eaw_delivery_resolve_scope_sources() {
	local scope_file="${1:-}" repos_conf="${2:-}" repo rel required root role candidate canonical
	[[ -f "$scope_file" && -s "$scope_file" && -f "$repos_conf" ]] || { echo "card evidence scope is missing or empty" >&2; return 2; }
	local entries
	entries="$(eaw_delivery_scope_sources "$scope_file")" || return 2
	[[ -n "$entries" ]] || { echo "card evidence scope has no authorized_sources entries" >&2; return 2; }
	while IFS=$'\t' read -r repo rel required; do
		[[ -n "$repo" ]] || continue
		[[ -n "$rel" ]] || { echo "card evidence scope path is empty: $repo" >&2; return 2; }
		[[ "$required" == true || "$required" == false ]] || { echo "invalid card evidence scope required flag: $repo" >&2; return 2; }
		[[ "$required" == true || "$required" == false ]] || { echo "invalid required flag in card source scope: $repo" >&2; return 2; }
		IFS='|' read -r _ root role < <(awk -F'|' -v key="$repo" '$1==key {print $1"|"$2"|"$3; exit}' "$repos_conf")
		[[ -n "${root:-}" && "$role" == target ]] || { echo "card source scope names unknown/non-target repository: $repo" >&2; return 2; }
		root="$(realpath -e -- "$root")" || return 2
		[[ -n "$rel" && "$rel" != /* && "$rel" != *"/../"* && "$rel" != ../* && "$rel" != *"/.." ]] || { echo "invalid card source scope path: $rel" >&2; return 2; }
		while IFS= read -r candidate; do
			[[ -f "$candidate" ]] || continue
			canonical="$(realpath -e -- "$candidate")" || return 2
			case "$canonical" in "$root"/*) ;; *) echo "card source scope escapes target root: $repo:$rel" >&2; return 2 ;; esac
			printf '%s\t%s\t%s\t%s\n' "$repo" "$rel" "$required" "$canonical"
		done < <(compgen -G "$root/$rel" || true)
	done <<< "$entries"
}

eaw_delivery_resolve_phase_sources() {
	local phase_file="${1:-}" repos_conf="${2:-}" entry repo rels required key root role rel candidate canonical
	[[ -f "$phase_file" && -f "$repos_conf" ]] || return 2
	entry="$(eaw_delivery_phase_sources "$phase_file")"
	[[ -n "$entry" ]] || return 0
	while IFS=$'\t' read -r repo rels required; do
		[[ -n "$repo" ]] || continue
		[[ "$required" == true || "$required" == false ]] || { echo "invalid required flag for evidence repository '$repo'" >&2; return 2; }
		IFS='|' read -r key root role < <(awk -F'|' -v key="$repo" '$1==key {print $1"|"$2"|"$3; exit}' "$repos_conf")
		[[ -n "${root:-}" && "${role:-}" == target ]] || { echo "evidence repository is not a mapped target: $repo" >&2; return 2; }
		[[ -d "$root" ]] || { echo "evidence repository root is unavailable: $repo" >&2; return 2; }
		root="$(realpath -e -- "$root")" || return 2
		[[ -n "$rels" ]] || { echo "evidence source paths are empty for '$repo'" >&2; return 2; }
		while IFS= read -r rel; do
			[[ -n "$rel" ]] || continue
			[[ "$rel" != /* && "$rel" != *"/../"* && "$rel" != ../* && "$rel" != *"/.." ]] || { echo "evidence path must be relative and traversal-free: $rel" >&2; return 2; }
			local found=0
			while IFS= read -r candidate; do
				[[ -f "$candidate" ]] || continue
				canonical="$(realpath -e -- "$candidate")" || return 2
				case "$canonical" in "$root"/*) ;; *) echo "evidence path escapes repository root: $rel" >&2; return 2 ;; esac
				printf '%s\t%s\t%s\t%s\n' "$repo" "$rel" "$required" "$canonical"
				found=1
			done < <(compgen -G "$root/$rel" || true)
			if [[ $found -eq 0 ]]; then
				printf '%s\t%s\t%s\t%s\n' "$repo" "$rel" "$required" 'UNAVAILABLE'
			fi
		done < <(printf '%s\n' "$rels" | tr '\034' '\n')
	done < <(printf '%s\n' "$entry" | tr '\n' '\034' | sed 's/\034$//' | tr '\034' '\n')
}

eaw_delivery_validate_evidence_declaration() {
	local phase_file="${1:-}" repos_conf="${2:-}" entry repo rels required
	local declaration
	declaration="$(awk '/^  evidence_sources:/ {print; exit}' "$phase_file")"
	entry="$(eaw_delivery_phase_sources "$phase_file")" || return
	if [[ -z "$entry" ]]; then
		[[ "$declaration" =~ \[\][[:space:]]*$ || -z "$declaration" ]] && return 0
		echo "evidence_sources must be [] or contain valid repository/path entries" >&2
		return 1
	fi
	while IFS=$'\t' read -r repo rels required; do
		[[ -n "$repo" && -n "$rels" ]] || { echo "evidence source requires repository and at least one path" >&2; return 1; }
		[[ "$required" == true || "$required" == false ]] || { echo "evidence source required must be true or false" >&2; return 1; }
		awk -F'|' -v key="$repo" '$1==key && $3=="target" {found=1} END {exit !found}' "$repos_conf" || { echo "unknown or non-target evidence repository: $repo" >&2; return 1; }
		while IFS= read -r rel; do
			[[ -n "$rel" && "$rel" != /* && "$rel" != *"/../"* && "$rel" != ../* && "$rel" != *"/.." ]] || { echo "invalid evidence path: $rel" >&2; return 1; }
		done < <(printf '%s\n' "$rels" | tr '\034' '\n')
	done < <(printf '%s\n' "$entry" | tr '\n' '\034' | sed 's/\034$//' | tr '\034' '\n')
}

# Read only records explicitly enumerated as required and available by the
# source inventory. This function is called only for phases declaring
# read_sources_from: required_inventory_sources.
eaw_delivery_resolve_inventory_sources() {
	local manifest="${1:-}" repos_conf="${2:-}" scope_file="${3:-}" repository rel required availability root canonical authorized
	[[ -s "$manifest" && -f "$repos_conf" ]] || return 0
	while IFS=$'\t' read -r repository rel required availability; do
		[[ "$required" == true && "$availability" == available ]] || continue
		authorized=0
		while IFS=$'\t' read -r auth_repo auth_pattern auth_required _; do
			[[ "$auth_repo" == "$repository" && "$auth_required" == true && "$rel" == $auth_pattern ]] && { authorized=1; break; }
		done < <(eaw_delivery_scope_sources "$scope_file")
		[[ $authorized -eq 1 ]] || continue
		IFS='|' read -r _ root role < <(awk -F'|' -v key="$repository" '$1==key {print $1"|"$2"|"$3; exit}' "$repos_conf")
		[[ -n "${root:-}" && "$role" == target ]] || { echo "inventory names unknown/non-target repository: $repository" >&2; return 1; }
		root="$(realpath -e -- "$root")" || return 1
		[[ -n "$rel" && "$rel" != /* && "$rel" != *"/../"* && "$rel" != ../* && "$rel" != *"/.." ]] || { echo "inventory source path is not a safe relative path: $rel" >&2; return 1; }
		[[ -f "$root/$rel" ]] || { echo "inventory marks unavailable/non-file path as available: $repository:$rel" >&2; return 1; }
		canonical="$(realpath -e -- "$root/$rel")" || return 1
		case "$canonical" in "$root"/*) ;; *) echo "inventory source escapes selected target root: $repository:$rel" >&2; return 1 ;; esac
		printf '%s\t%s\t%s\n' "$repository" "$rel" "$canonical"
	done < <(awk '
		/^sources:[[:space:]]*$/ { in_sources=1; next }
		in_sources && /^[^[:space:]]/ { in_sources=0 }
		in_sources && /^  - / { if (record) print repo "\t" path "\t" required "\t" availability; record=1; repo=""; path=""; required="false"; availability="unknown"; next }
		in_sources && record && /^    repository:[[:space:]]*/ {v=$0; sub(/^    repository:[[:space:]]*/,"",v); repo=v; next}
		in_sources && record && /^    path:[[:space:]]*/ {v=$0; sub(/^    path:[[:space:]]*/,"",v); path=v; if (substr(path,1,1)=="\047" || substr(path,1,1)=="\042") path=substr(path,2,length(path)-2); next}
		in_sources && record && /^    required:[[:space:]]*/ {v=$0; sub(/^    required:[[:space:]]*/,"",v); required=v; next}
		in_sources && record && /^    availability:[[:space:]]*/ {v=$0; sub(/^    availability:[[:space:]]*/,"",v); availability=v; next}
		END { if (record) print repo "\t" path "\t" required "\t" availability }
	' "$manifest")
}

# Validate package handoff state before a regression analysis package completes.
eaw_delivery_validate_package() {
	local package="${1:-}" status persistence persisted_paths target
	[[ -s "$package" ]] || { echo "delivery package is missing or empty: $package" >&2; return 1; }
	status="$(sed -nE 's/^[[:space:]`*-]*ANALYSIS_STATUS:[[:space:]`]*([^[:space:]`]+).*/\1/p' "$package" | tail -n 1)"
	persistence="$(sed -nE 's/^[[:space:]`*-]*PERSISTENCE_STATUS:[[:space:]`]*([^[:space:]`]+).*/\1/p' "$package" | tail -n 1)"
	[[ -n "$status" && -n "$persistence" ]] || { echo "delivery package must declare distinct ANALYSIS_STATUS and PERSISTENCE_STATUS" >&2; return 1; }
	case "$persistence" in
		PERSISTED)
			persisted_paths="$(awk '
				/^PERSISTED_PATHS:[[:space:]]*/ {v=$0; sub(/^PERSISTED_PATHS:[[:space:]]*/, "", v); if (v!="" && v!="none") print v; in_paths=1; next}
				in_paths && /^- \/\// {sub(/^- /, ""); print; next}
				in_paths && /^[^[:space:]-]/ {in_paths=0}
			' "$package")"
			[[ -n "$persisted_paths" ]] || { echo "PERSISTED requires exact absolute PERSISTED_PATHS" >&2; return 1; }
			while IFS= read -r target; do
				[[ "$target" == /* && -e "$target" ]] || { echo "persisted path is not absolute or does not exist: $target" >&2; return 1; }
			done <<< "$persisted_paths"
			;;
		NOT_AUTHORIZED|NOT_APPLICABLE|BLOCKED|FAILED) : ;;
		*) echo "unrecognized PERSISTENCE_STATUS: $persistence" >&2; return 1 ;;
	esac
	case "$status" in COMPLETE|INCOMPLETE) : ;; *) echo "unrecognized ANALYSIS_STATUS: $status" >&2; return 1 ;; esac
	if [[ "$status" == COMPLETE ]]; then
		grep -Eq 'COVERAGE_STATUS:[[:space:]]*(COMPLETE|GAPS_ACCEPTED)' "$package" || { echo "ANALYSIS_STATUS COMPLETE requires an explicit coverage disposition" >&2; return 1; }
		if grep -Eq 'REQUIRED_AVAILABLE_NOT_EXAMINED:[[:space:]]*(true|yes)' "$package"; then
			echo "required available evidence remains unexamined; analysis cannot be COMPLETE" >&2; return 1
		fi
	fi
}

# Persist one artifact only when the literal target path appears in the
# effective allowlist. The destination directory must already exist so this
# helper cannot create unlisted hierarchy as a side effect.
eaw_delivery_persist_file() {
	local source="${1:-}" target="${2:-}" allowlist="${3:-}" temp canonical_parent
	[[ -f "$source" && -f "$allowlist" && "$target" == /* ]] || { echo "invalid persistence arguments" >&2; return 2; }
	grep -Fxq -- "$target" "$allowlist" || { echo "target path is not exactly allowlisted: $target" >&2; return 1; }
	[[ -d "$(dirname "$target")" ]] || { echo "allowlisted destination directory does not exist: $(dirname "$target")" >&2; return 1; }
	canonical_parent="$(realpath -e -- "$(dirname "$target")")" || return 1
	[[ "$canonical_parent/$(basename "$target")" == "$target" ]] || { echo "destination path is non-canonical or traverses a symlink: $target" >&2; return 1; }
	temp="$(mktemp "$canonical_parent/.eaw-delivery.XXXXXXXX")" || return 1
	if ! cat -- "$source" > "$temp"; then rm -f -- "$temp"; return 1; fi
	mv -f -- "$temp" "$target"
}
