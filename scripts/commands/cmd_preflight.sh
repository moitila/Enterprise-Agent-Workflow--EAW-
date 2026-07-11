#!/usr/bin/env bash

cmd_preflight() {
    local card="$1"
    local failures=()
    local total=4

    # Check 1: EAW_WORKDIR definido e é diretório
    if [[ -z "${EAW_WORKDIR:-}" || ! -d "${EAW_WORKDIR}" ]]; then
        failures+=("EAW_WORKDIR não definido ou não é um diretório (atual: '${EAW_WORKDIR:-<unset>}')")
    fi

    # Check 2: repos.conf — cada path existe e contém .git
    if [[ -f "$REPOS_CONF" ]]; then
        local lineno=0 line normalized key path role resolved_path
        while IFS= read -r line; do
            lineno=$((lineno + 1))
            if normalized="$(parse_repos_conf_line "$line" "$lineno")"; then
                IFS='|' read -r key path role <<<"$normalized"
                resolved_path="$(resolve_repo_path "$path")"
                if [[ ! -d "$resolved_path" ]]; then
                    failures+=("repos.conf:$lineno repo '$key' path não existe: $resolved_path")
                elif [[ ! -d "$resolved_path/.git" ]]; then
                    failures+=("repos.conf:$lineno repo '$key' não é repositório git: $resolved_path")
                fi
            fi
        done <"$REPOS_CONF"
    else
        failures+=("repos.conf ausente: ${REPOS_CONF:-<REPOS_CONF não definido>}")
    fi

    # Check 3: runtime root acessível
    if [[ ! -f "$SCRIPT_DIR/eaw" ]]; then
        failures+=("Runtime root não encontrado: $SCRIPT_DIR/eaw")
    fi

    # Check 4: out/<CARD>/prompts/ existe com pelo menos 1 arquivo
    local prompts_dir="${EAW_OUT_DIR:-}/$card/prompts"
    if [[ ! -d "$prompts_dir" ]]; then
        failures+=("Diretório de prompts ausente: $prompts_dir")
    else
        local prompt_count
        prompt_count="$(find "$prompts_dir" -maxdepth 1 -type f | wc -l)"
        if [[ "$prompt_count" -lt 1 ]]; then
            failures+=("Nenhum prompt encontrado em: $prompts_dir")
        fi
    fi

    # Resultado
    local fail_count="${#failures[@]}"
    if [[ "$fail_count" -eq 0 ]]; then
        echo "PASS ($total/$total checks)"
        return 0
    else
        local pass_count=$(( total - fail_count ))
        echo "FAIL [$pass_count/$total]:"
        local f
        for f in "${failures[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}
