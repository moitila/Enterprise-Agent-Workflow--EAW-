#!/usr/bin/env bash

cmd_validate() {
	local errors=0
	local warnings=0
	local line lineno normalized key path role resolved_path card_dir impl_dir impl_name impl_path
	local prompt_phase

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

	for prompt_phase in \
		intake \
		analyze_findings \
		analyze_hypotheses \
		analyze_planning \
		implementation_planning \
		implementation_executor; do
		if ! prompt_resolve_active_metadata "default" "$prompt_phase" >/dev/null; then
			errors=$((errors + 1))
		fi
	done

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
