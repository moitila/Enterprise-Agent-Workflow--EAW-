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





cmd_prompt_implement_phase() {
	local card="$1"
	local out_root="$EAW_OUT_DIR"
	local card_dir="$out_root/$card"
	local prompt_file="$card_dir/agent_prompt.md"
	local next_steps_file="$card_dir/investigations/40_next_steps.md"
	local scope_lock_file="$card_dir/implementation/00_scope.lock.md"
	local change_plan_file="$card_dir/implementation/10_change_plan.md"
	local patch_notes_file="$card_dir/implementation/20_patch_notes.md"
	local required_files=(
		"$next_steps_file"
		"$scope_lock_file"
		"$change_plan_file"
		"$patch_notes_file"
	)
	local file

	if [[ ! -d "$card_dir" ]]; then
		echo "ERROR: card output directory not found: $card_dir" >&2
		exit 1
	fi

	for file in "${required_files[@]}"; do
		if [[ ! -f "$file" ]]; then
			echo "ERROR: missing required input: $file" >&2
			exit 1
		fi
	done

	{
		echo "=== EAW IMPLEMENT AGENT PROMPT CARD ${card} ==="
		echo "EAW_WORKDIR=${EAW_WORKDIR:-}"
		echo "RUNTIME_ROOT=$EAW_ROOT_DIR"
		echo "OUT_DIR=$out_root"
		echo "CARD_DIR=$card_dir"
		echo
		cat <<EOF
Você é o agente do VSCode e deve executar a fase IMPLEMENT do card ${card} com disciplina EAW.

REGRAS OBRIGATÓRIAS:

- Leia obrigatoriamente \$CARD_DIR/investigations/40_next_steps.md antes de executar mudanças.
- Respeite estritamente o escopo permitido em \$CARD_DIR/implementation/00_scope.lock.md.
- Aplique apenas mudança mínima e determinística, conforme \$CARD_DIR/implementation/10_change_plan.md.
- Registre evidências reais de cada alteração em \$CARD_DIR/implementation/20_patch_notes.md.
- Não expandir escopo e não refatorar, exceto se estiver explicitamente planejado.
- Se qualquer input obrigatório estiver ausente, abortar imediatamente com ERROR e exit != 0.
EOF
	} | tee "$prompt_file"

	echo "Wrote $prompt_file" >&2
}
