#!/usr/bin/env bash




cmd_card() {
	local type="$1"
	local card="$2"
	local title="$3"
	local outdir="$EAW_OUT_DIR/$card"
	# expose OUTDIR for run_phase and others
	OUTDIR="$outdir"
	ensure_dir "$outdir"

	# run lifecycle phases in order; preserve original behavior and tolerances
	run_phase "init_runtime" true phase_init_runtime "$type" "$card" "$title" "$outdir" || return 1
	run_phase "load_config" false phase_load_config "$outdir"
	run_phase "resolve_repos" false phase_resolve_repos
	run_phase "collect_context" false phase_collect_context "$card" "$outdir"
	run_phase "search_hits" false phase_search_hits "$outdir"
	run_phase "finalize" false phase_finalize "$card" "$outdir"
}




