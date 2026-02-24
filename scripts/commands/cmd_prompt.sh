#!/usr/bin/env bash

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
