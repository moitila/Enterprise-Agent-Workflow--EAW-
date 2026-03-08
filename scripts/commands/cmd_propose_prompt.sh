#!/usr/bin/env bash

cmd_propose_prompt() {
	if [[ "$#" -ne 5 ]]; then
		echo "usage: eaw propose-prompt <CARD> <TRACK> <PHASE> <BASE_CANDIDATE> <NEW_CANDIDATE>" >&2
		return 2
	fi

	local card="$1"
	local track="$2"
	local phase="$3"
	local base_candidate="$4"
	local new_candidate="$5"
	local base_version new_version base_name dir
	local base_md base_meta card_dir proposal_dir
	local proposal_md proposal_diff candidate_meta candidate_md proposal_result
	local diff_rc md_diff_rc timestamp

	if ! base_version="$(normalize_prompt_candidate "$base_candidate")"; then
		echo "FAIL: invalid base candidate '$base_candidate' (expected vN or N)" >&2
		return 1
	fi
	if ! new_version="$(normalize_prompt_candidate "$new_candidate")"; then
		echo "FAIL: invalid new candidate '$new_candidate' (expected vN or N)" >&2
		return 1
	fi
	if ! base_name="$(prompt_candidate_base "$base_candidate")"; then
		echo "FAIL: invalid base candidate '$base_candidate'" >&2
		return 1
	fi

	dir="$(prompt_phase_dir "$track" "$phase")"
	base_md="$dir/${base_name}.md"
	base_meta="$dir/${base_name}.meta"

	if [[ ! -f "$base_md" ]]; then
		echo "FAIL: missing markdown candidate: $base_md" >&2
		return 1
	fi
	if [[ ! -f "$base_meta" ]]; then
		echo "FAIL: missing metadata candidate: $base_meta" >&2
		return 1
	fi

	if ! cmd_validate_prompt "$track" "$phase" "$base_candidate" >/dev/null; then
		return $?
	fi

	card_dir="$EAW_OUT_DIR/$card"
	proposal_dir="$card_dir/proposals"
	proposal_md="$proposal_dir/10_prompt_proposal.md"
	proposal_diff="$proposal_dir/20_prompt_diff.txt"
	candidate_meta="$proposal_dir/30_prompt_candidate.meta"
	candidate_md="$proposal_dir/31_prompt_candidate.md"
	proposal_result="$proposal_dir/40_proposal_result.md"

	ensure_dir "$proposal_dir"

	cp "$base_md" "$candidate_md"
	if ! awk -F'=' -v version="$new_version" '
		BEGIN { updated=0 }
		/^[[:space:]]*version[[:space:]]*=/ && updated == 0 {
			print "version=" version
			updated=1
			next
		}
		{ print }
		END {
			if (updated == 0) {
				exit 1
			}
		}
	' "$base_meta" >"$candidate_meta"; then
		rm -f "$candidate_meta"
		echo "FAIL: missing version in metadata: $base_meta" >&2
		return 1
	fi

	{
		printf "# Prompt Proposal - Card %s\n\n" "$card"
		printf "## Problema\n"
		printf "Gerar artefatos de proposal para \`%s/%s\` sem alterar \`templates/prompts/\` nem \`ACTIVE\`.\n\n" "$track" "$phase"
		printf "## Evidencias\n"
		printf -- "- Base markdown: \`%s\`\n" "$base_md"
		printf -- "- Base metadata: \`%s\`\n" "$base_meta"
		printf -- "- Base candidate: \`%s\`\n" "$base_version"
		printf -- "- New candidate: \`%s\`\n\n" "$new_version"
		printf "## Mudanca proposta\n"
		printf "Gerar \`31_prompt_candidate.md\` a partir do markdown base e \`30_prompt_candidate.meta\` a partir do metadata base com \`version=%s\`.\n\n" "$new_version"
		printf "## Riscos\n"
		printf -- "- Alteracao indevida em \`templates/prompts/\`.\n"
		printf -- "- Alteracao indevida em \`ACTIVE\`.\n"
		printf -- "- Divergencia entre o metadata gerado e o contrato de \`validate-prompt\`.\n\n"
		printf "## Test plan\n"
		printf -- "- Executar \`eaw validate-prompt %s %s %s\`.\n" "$track" "$phase" "$base_version"
		printf -- "- Verificar os cinco artefatos em \`out/%s/proposals/\`.\n" "$card"
		printf -- "- Confirmar que \`ACTIVE\` e os arquivos em \`templates/prompts/%s/%s/\` nao mudaram.\n\n" "$track" "$phase"
		printf "## Rollback\n"
		printf "Remover os artefatos gerados em \`out/%s/proposals/\`.\n" "$card"
	} >"$proposal_md"

	diff -u --label "$base_meta" --label "$candidate_meta" "$base_meta" "$candidate_meta" >"$proposal_diff" || diff_rc=$?
	diff_rc="${diff_rc:-0}"
	if [[ "$diff_rc" -gt 1 ]]; then
		echo "FAIL: diff command failed for metadata" >&2
		return 1
	fi

	diff -u --label "$base_md" --label "$candidate_md" "$base_md" "$candidate_md" >>"$proposal_diff" || md_diff_rc=$?
	md_diff_rc="${md_diff_rc:-0}"
	if [[ "$md_diff_rc" -gt 1 ]]; then
		echo "FAIL: diff command failed for markdown" >&2
		return 1
	fi

		timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	{
		printf "# Proposal Result - Card %s\n\n" "$card"
		printf "input_paths:\n"
		printf -- "- %s\n" "$base_md"
		printf -- "- %s\n\n" "$base_meta"
		printf "output_paths:\n"
		printf -- "- %s\n" "$proposal_md"
		printf -- "- %s\n" "$proposal_diff"
		printf -- "- %s\n" "$candidate_meta"
		printf -- "- %s\n" "$candidate_md"
		printf -- "- %s\n\n" "$proposal_result"
		printf "timestamp: %s\n" "$timestamp"
		printf "exit_code: 0\n"
		printf "observations: candidate generated; not applied\n"
	} >"$proposal_result"

	echo "PASS: propose-prompt $card $track/$phase $base_version->$new_version"
	return 0
}
