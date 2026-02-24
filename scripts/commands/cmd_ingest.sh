#!/usr/bin/env bash

cmd_ingest() {
	local card="$1"
	local src_path="$2"
	local outdir="$EAW_OUT_DIR/$card"
	if [[ ! -f "$src_path" ]]; then
		echo "Source file not found: $src_path" >&2
		exit 1
	fi
	ensure_dir "$outdir/inputs"
	local fname
	fname=$(basename "$src_path")
	cp "$src_path" "$outdir/inputs/"
	echo "Copied $src_path -> $outdir/inputs/$fname"

	# update main dossier
	# detect type and main md
	local type=""
	for t in feature spike bug; do
		if [[ -f "$outdir/${t}_${card}.md" ]]; then
			type="$t"
			break
		fi
	done
	if [[ -z "$type" ]]; then
		echo "Cannot find main dossier to attach evidence: expected ${type}_${card}.md" >&2
		exit 1
	fi
	local main_md="$outdir/${type}_${card}.md"
	local ts
	ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

	# insert or append Attached Evidence section
	if grep -q "^## Attached Evidence" "$main_md"; then
		# append bullet
		printf "- %s - %s\n" "$fname" "$ts" >>"$main_md"
	else
		printf "\n## Attached Evidence\n- %s - %s\n" "$fname" "$ts" >>"$main_md"
	fi
	echo "Registered evidence in $main_md"
}
