#!/usr/bin/env bash

cmd_validate() {
	local errors=0
	local warnings=0
	local line lineno normalized key path role resolved_path card_dir impl_dir impl_name impl_path

	echo "EAW validate"
	echo "Resolved dirs:"
	echo "  EAW_ROOT_DIR=$EAW_ROOT_DIR"
	echo "  EAW_WORKDIR=${EAW_WORKDIR:-}"
	echo "  EAW_CONFIG_DIR=$EAW_CONFIG_DIR"
	echo "  EAW_TEMPLATES_DIR=$EAW_TEMPLATES_DIR"
	echo "  EAW_OUT_DIR=$EAW_OUT_DIR"

	if [[ -n "${EAW_WORKDIR:-}" ]]; then
		if [[ ! -d "$EAW_CONFIG_DIR" ]]; then
			echo "ERROR: workspace config directory missing: $EAW_CONFIG_DIR"
			errors=$((errors + 1))
		fi
		if [[ ! -f "$REPOS_CONF" ]]; then
			echo "ERROR: workspace repos.conf missing: $REPOS_CONF"
			errors=$((errors + 1))
		fi
	fi

	check_config_version_validate warnings

	if [[ -f "$REPOS_CONF" ]]; then
		lineno=0
		while IFS= read -r line; do
			lineno=$((lineno + 1))
			if normalized="$(parse_repos_conf_line "$line" "$lineno")"; then
				IFS='|' read -r key path role <<<"$normalized"
			else
				case "$?" in
				1)
					continue
					;;
				2)
					errors=$((errors + 1))
					continue
					;;
				esac
				continue
			fi
			resolved_path="$(resolve_repo_path "$path")"
			if [[ ! -e "$resolved_path" ]]; then
				echo "WARNING: repos.conf:$lineno path does not exist: $resolved_path"
				warnings=$((warnings + 1))
			fi
		done <"$REPOS_CONF"
		echo "OK: repos.conf parsed"
	else
		echo "WARNING: repos.conf missing: $REPOS_CONF"
		warnings=$((warnings + 1))
	fi

	if [[ -f "$SEARCH_CONF" ]]; then
		echo "OK: search.conf found: $SEARCH_CONF"
	else
		echo "WARNING: search.conf missing: $SEARCH_CONF"
		warnings=$((warnings + 1))
	fi

	if [[ -n "${EAW_WORKDIR:-}" && -d "$EAW_WORKDIR/templates" ]]; then
		for tpl_name in feature.md bug.md spike.md intake_bug.md intake_feature.md intake_spike.md; do
			if [[ ! -r "$EAW_WORKDIR/templates/$tpl_name" ]]; then
				echo "WARNING: missing or unreadable workspace template: $EAW_WORKDIR/templates/$tpl_name"
				warnings=$((warnings + 1))
			fi
		done
	fi

	local intake_bug_tpl="$EAW_TEMPLATES_DIR/intake_bug.md"
	local intake_feature_tpl="$EAW_TEMPLATES_DIR/intake_feature.md"
	local intake_spike_tpl="$EAW_TEMPLATES_DIR/intake_spike.md"

	if [[ ! -r "$intake_bug_tpl" ]]; then
		echo "WARNING: templates/intake_bug.md missing"
		warnings=$((warnings + 1))
	else
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*(Resumo do problema|Resumo)[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Resumo do problema ou Resumo"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Comportamento esperado[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Comportamento esperado"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Comportamento atual[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Comportamento atual"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Passos para reproduzir[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Passos para reproduzir"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Evidências fornecidas[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Evidências fornecidas"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Impacto[[:space:]]*/[[:space:]]*Escopo[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Impacto / Escopo"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Perguntas em aberto[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Perguntas em aberto"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_bug_tpl" '^##[[:space:]]*Hipóteses iniciais[[:space:]]*$'; then
			echo "WARNING: templates/intake_bug.md missing heading: Hipóteses iniciais"
			warnings=$((warnings + 1))
		fi
	fi

	if [[ ! -r "$intake_feature_tpl" ]]; then
		echo "WARNING: templates/intake_feature.md missing"
		warnings=$((warnings + 1))
	else
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Problema[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Problema"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Objetivo[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Objetivo"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Critérios de aceite[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Critérios de aceite"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Escopo[[:space:]]*\(In/Out\)[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Escopo (In/Out)"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Dependências[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Dependências"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Riscos[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Riscos"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_feature_tpl" '^##[[:space:]]*Perguntas em aberto[[:space:]]*$'; then
			echo "WARNING: templates/intake_feature.md missing heading: Perguntas em aberto"
			warnings=$((warnings + 1))
		fi
	fi

	if [[ ! -r "$intake_spike_tpl" ]]; then
		echo "WARNING: templates/intake_spike.md missing"
		warnings=$((warnings + 1))
	else
		if ! grep_heading_match "$intake_spike_tpl" '^##[[:space:]]*Pergunta[[:space:]]*/[[:space:]]*Hipótese[[:space:]]*$'; then
			echo "WARNING: templates/intake_spike.md missing heading: Pergunta / Hipótese"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_spike_tpl" '^##[[:space:]]*Contexto técnico[[:space:]]*$'; then
			echo "WARNING: templates/intake_spike.md missing heading: Contexto técnico"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_spike_tpl" '^##[[:space:]]*Opções consideradas[[:space:]]*$'; then
			echo "WARNING: templates/intake_spike.md missing heading: Opções consideradas"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_spike_tpl" '^##[[:space:]]*Critério de conclusão[[:space:]]*$'; then
			echo "WARNING: templates/intake_spike.md missing heading: Critério de conclusão"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_spike_tpl" '^##[[:space:]]*Riscos[[:space:]]*$'; then
			echo "WARNING: templates/intake_spike.md missing heading: Riscos"
			warnings=$((warnings + 1))
		fi
		if ! grep_heading_match "$intake_spike_tpl" '^##[[:space:]]*Próximos passos[[:space:]]*$'; then
			echo "WARNING: templates/intake_spike.md missing heading: Próximos passos"
			warnings=$((warnings + 1))
		fi
	fi

	for card_dir in "$EAW_OUT_DIR"/*; do
		[[ -d "$card_dir" ]] || continue
		impl_dir="$card_dir/implementation"
		if [[ -d "$impl_dir" ]]; then
			for impl_name in 00_scope.lock.md 10_change_plan.md 20_patch_notes.md; do
				impl_path="$impl_dir/$impl_name"
				if [[ ! -f "$impl_path" ]]; then
					if [[ -e "$impl_path" ]]; then
						echo "ERROR: implement artifact not a regular file: $impl_path" >&2
					else
						echo "ERROR: implement artifact missing: $impl_path" >&2
					fi
					errors=$((errors + 1))
					continue
				fi
				if [[ ! -s "$impl_path" ]]; then
					echo "ERROR: implement artifact empty: $impl_path" >&2
					errors=$((errors + 1))
				fi
			done
		fi
	done

	echo "SUMMARY: errors=$errors warnings=$warnings"
	if [[ "$errors" -gt 0 ]]; then
		return 2
	fi
	return 0
}

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
	if command -v awk >/dev/null 2>&1; then echo "  awk: OK"; else
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
		echo "  eaw.conf: MISSING ($EAW_CONF)"
		warnings=$((warnings + 1))
	fi

	if [[ "$errors" -gt 0 ]]; then
		status="ERROR"
	elif [[ "$warnings" -gt 0 ]]; then
		status="WARN"
	fi
	echo "STATUS: $status (errors=$errors warnings=$warnings)"
	return 0
}


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

cmd_implement() {
	local card="${1:-}"
	local card_dir impl_dir
	local created=0
	local preserved=0

	if [[ -z "$card" ]]; then
		die "missing <CARD> argument"
	fi
	if [[ ! "$card" =~ ^[0-9]+$ ]]; then
		die "invalid <CARD> '$card' (expected digits only)"
	fi

	card_dir="$EAW_OUT_DIR/$card"
	if [[ ! -d "$card_dir" ]]; then
		die "card output directory not found: $card_dir"
	fi

	impl_dir="$card_dir/implementation"
	if [[ -d "$impl_dir" ]]; then
		echo "PRESERVED: $impl_dir"
		preserved=$((preserved + 1))
	else
		ensure_dir "$impl_dir"
		echo "CREATED: $impl_dir"
		created=$((created + 1))
	fi

	for name in 00_scope.lock.md 10_change_plan.md 20_patch_notes.md; do
		local target="$impl_dir/$name"
		if [[ -f "$target" ]]; then
			echo "PRESERVED: $target"
			preserved=$((preserved + 1))
			continue
		fi
		case "$name" in
		00_scope.lock.md)
			cat >"$target" <<EOF
# Scope Lock - Card $card

## In Scope

## Out of Scope
EOF
			;;
		10_change_plan.md)
			cat >"$target" <<EOF
# Change Plan - Card $card

## Steps

## Validation
EOF
			;;
		20_patch_notes.md)
			cat >"$target" <<EOF
# Patch Notes - Card $card

## Changes

## Risks
EOF
			;;
		esac
		echo "CREATED: $target"
		created=$((created + 1))
	done

	echo "SUMMARY: created=$created preserved=$preserved"
}

cmd_analyze() {
	local card="$1"
	local outdir="$EAW_OUT_DIR/$card"
	if [[ ! -d "$outdir" ]]; then
		echo "Card output not found: $outdir" >&2
		exit 1
	fi
	# detect type
	local type=""
	for t in feature spike bug; do
		if [[ -f "$outdir/${t}_${card}.md" ]]; then
			type="$t"
			break
		fi
	done
	if [[ -z "$type" ]]; then
		echo "Could not detect card type for $card. Expected feature/spike/bug file in $outdir" >&2
		exit 1
	fi

	local main_md="$outdir/${type}_${card}.md"
	if [[ ! -f "$main_md" ]]; then
		echo "Main dossier not found: $main_md" >&2
		exit 1
	fi

	ensure_dir "$outdir/inputs"

	# Build AI prompt
	local prompt_file="$outdir/AI_PROMPT_${card}.md"
	local date_now
	date_now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

	# collect repository lists (stable ordering)
	local repo_blocks target_repos excluded_repos
	repo_blocks="$(collect_repos_lists)"
	target_repos="$(printf "%s\n" "$repo_blocks" | sed -n '1,/^$/p' | sed '/^$/d')"
	excluded_repos="$(printf "%s\n" "$repo_blocks" | sed -n '/^$/,$p' | sed '1d;/^$/d')"

	cat >"$prompt_file" <<EOF
# AI_PROMPT for card ${card}

ROLE:
You are a senior engineering analyst assisting with a structured review and mitigation plan for an engineering card. Provide concise, actionable analysis, tests, and a minimal change plan.

GUARDRAILS:
- Do not invent facts. Use only provided inputs and repository context.
- Mark assumptions explicitly.
- Prioritize minimal, safe fixes and clear test plans.

INPUTS:
- Dossier: $main_md
- Context directory: $outdir/context/
- Ingested files: $(ls -1 "$outdir/inputs" 2>/dev/null || echo "(none)")

TARGET_REPOS:
$target_repos

EXCLUDED_REPOS:
$excluded_repos

PROCESS (mandatory 8 phases):
1) Understanding: Summarize card in 2-3 sentences.
2) Scoping: List affected modules and blast radius.
3) Evidence collection: Enumerate relevant files and diff snippets from context/.
4) Risk mapping: Map hotspots, regression risk, and critical paths.
5) Hypothesis & Proposed Fix: Describe minimal fix or experiment.
6) Test Plan: Provide deterministic tests and validation steps; produce TEST_PLAN file in dev/ (see Outputs).
7) Implementation steps: Minimal, atomic changes with rollbacks and feature flags where applicable.
8) Validation & Monitoring: Post-deploy checks, metrics to watch, and rollback criteria.

OUTPUTS (write to dev/ within the dossier output):
- TEST_PLAN_${card}.md - deterministic test plan (unit/integration/smoke)
- PATCH/PR summary (one paragraph)
- RISK_SUMMARY (one paragraph)

ALLOWED QUESTIONS (ask only when missing info):
- Are there existing failing tests related to this area?
- Is there any sensitive data or compliance constraint for changes?
- Any required stakeholders to involve?

Date generated: $date_now

-- Dossier content (begin) --

$(sed -n '1,400p' "$main_md")

-- Dossier content (end) --

EOF

	echo "Wrote $prompt_file"

	# create TEST_PLAN placeholder in outdir
	local test_plan="$outdir/TEST_PLAN_${card}.md"
	if [[ ! -f "$test_plan" ]]; then
		cat >"$test_plan" <<TP
# Test Plan for ${type}_${card}

## Summary

Describe deterministic tests to validate changes.

## Unit Tests

- Add tests for ...

## Integration Tests

- Run ...

TP
		echo "Wrote $test_plan"
	fi
}

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

cmd_prompt() {
	local card="$1"
	local out_root="$EAW_OUT_DIR"
	local card_dir="$out_root/$card"
	local prompt_file="$card_dir/agent_prompt.md"
	local intake_file="$card_dir/investigations/00_intake.md"
	local type=""
	local warnings=()

	detect_card_type_with_warnings "$card" "$card_dir" type warnings

	if [[ ! -f "$intake_file" ]]; then
		append_warn warnings "missing intake file: $intake_file"
	else
		case "$type" in
		bug)
			validate_intake_heading_group "$intake_file" warnings "Resumo do problema ou Resumo" '^##[[:space:]]*(Resumo do problema|Resumo)[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Comportamento esperado" '^##[[:space:]]*Comportamento esperado[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Comportamento atual" '^##[[:space:]]*Comportamento atual[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Passos para reproduzir" '^##[[:space:]]*Passos para reproduzir[[:space:]]*$'
			;;
		feature)
			validate_intake_heading_group "$intake_file" warnings "Problema ou Objetivo" '^##[[:space:]]*(Problema|Objetivo)[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Critérios de aceite" '^##[[:space:]]*Critérios de aceite[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Escopo" '^##[[:space:]]*Escopo([[:space:]]*\(In/Out\))?[[:space:]]*$'
			;;
		spike)
			validate_intake_heading_group "$intake_file" warnings "Pergunta ou Hipótese" '^##[[:space:]]*(Pergunta[[:space:]]*/[[:space:]]*Hipótese|Pergunta|Hipótese)[[:space:]]*$'
			validate_intake_heading_group "$intake_file" warnings "Critério de conclusão" '^##[[:space:]]*Critério de conclusão[[:space:]]*$'
			;;
		esac
		if ! intake_has_section_headings "$intake_file" || intake_is_structurally_incomplete "$type" "$intake_file"; then
			append_warn warnings "intake appears structurally incomplete."
			append_warn warnings "DO NOT START INVESTIGATION BEFORE COMPLETING REQUIRED SECTIONS."
		fi
	fi

	ensure_dir "$card_dir"
	local repo_blocks target_repos excluded_repos
	repo_blocks="$(collect_repos_lists)"
	target_repos="$(printf "%s\n" "$repo_blocks" | sed -n '1,/^$/p' | sed '/^$/d')"
	excluded_repos="$(printf "%s\n" "$repo_blocks" | sed -n '/^$/,$p' | sed '1d;/^$/d')"
	{
		echo "=== EAW AGENT PROMPT (${type}) CARD ${card} ==="
		echo "EAW_WORKDIR=${EAW_WORKDIR:-}"
		echo "RUNTIME_ROOT=$EAW_ROOT_DIR"
		echo "CONFIG_SOURCE=$REPOS_CONF"
		echo "EAW_ROOT_DIR=\"\$RUNTIME_ROOT\""
		echo "OUT_DIR=$out_root"
		echo "CARD_DIR=$card_dir"
		echo "TARGET_REPOS:"
		echo "$target_repos"
		echo "EXCLUDED_REPOS:"
		echo "$excluded_repos"

		for warn in "${warnings[@]}"; do
			if [[ "$warn" == "DO NOT START INVESTIGATION BEFORE COMPLETING REQUIRED SECTIONS." ]]; then
				echo "WARNING: $warn"
			else
				echo "WARN: $warn"
			fi
		done

		cat <<EOF
Você é o agente do VSCode e deve investigar o card ${card} (${type}) com disciplina EAW.

REGRAS OBRIGATÓRIAS:

Não alterar código.

Não commitar.

Toda afirmação deve ter evidência (path real + comando + trecho curto).

Leitura permitida em \$RUNTIME_ROOT e nos TARGET_REPOS listados.

Escrita permitida somente em \$CARD_DIR/.

Qualquer desvio deve ser registrado em \$CARD_DIR/investigations/_warnings.md.

Pré-check obrigatório de root (executar antes de qualquer passo):
cd "\$EAW_ROOT_DIR"
test -f ./scripts/eaw || { echo "ERROR: not in EAW-tool root"; exit 2; }
test -f "\$CONFIG_SOURCE" || { echo "ERROR: missing config source \$CONFIG_SOURCE"; exit 2; }

Whitelist estrita com abort:
Arquivos permitidos para escrita:
- \$CARD_DIR/${type}_${card}.md
- \$CARD_DIR/investigations/00_intake.md
- \$CARD_DIR/investigations/20_findings.md
- \$CARD_DIR/investigations/40_next_steps.md
- \$CARD_DIR/investigations/_warnings.md
Qualquer tentativa de alterar arquivo fora da lista permitida deve abortar imediatamente com erro.

PASSO 1 — BASELINE
export EAW_WORKDIR="${EAW_WORKDIR:-}"
./scripts/eaw doctor
./scripts/eaw validate

PASSO 2 — ARTEFATOS EAW
Confirme existência de:

\$CARD_DIR/execution.log

${type}_${card}.md

\$CARD_DIR/investigations/00_intake.md

PASSO 3 — INVESTIGAÇÃO CONTROLADA

Use apenas contexto de \$CARD_DIR/ e código do repo.

Registre comandos e outputs em:
\$CARD_DIR/investigations/20_findings.md

PASSO 4 — ATUALIZAR TEMPLATE DO CARD
Atualize:
\$CARD_DIR/${type}_${card}.md
com evidências reais coletadas.

PASSO 5 — CONCLUSÃO
Produza:

investigations/40_next_steps.md

diagnóstico fundamentado

riscos

plano mínimo determinístico

PASSO 6 — TESTES DETERMINÍSTICOS ROBUSTOS
Use loop explícito para validar artefatos, sem padrões frágeis de brace expansion.
Exemplo:
for file in \
  "\$CARD_DIR/execution.log" \
  "\$CARD_DIR/investigations/00_intake.md" \
  "\$CARD_DIR/investigations/20_findings.md" \
  "\$CARD_DIR/investigations/40_next_steps.md"; do
  test -f "\$file" || { echo "ERROR: missing \$file"; exit 2; }
done

RETORNO OBRIGATÓRIO (EVIDÊNCIA ESTRUTURADA)
- lista de arquivos alterados
- resumo por arquivo
- saída literal dos testes executados
- Backward compatibility preservada; sem refatorações extras.
EOF
	} | tee "$prompt_file"

	echo "Wrote $prompt_file" >&2
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
