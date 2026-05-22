#!/usr/bin/env bash

cmd_ingest_pr() {
	local card="" pr="" repo="" import_file=""

	card="${1:-}"
	shift || true
	[[ -n "$card" ]] || die "usage: eaw ingest-pr <CARD> <PR_NUMBER> [--repo <REPO>] | --file <FILE>"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--repo)   shift; repo="${1:-}" ;;
		--repo=*) repo="${1#--repo=}" ;;
		--file)   shift; import_file="${1:-}" ;;
		--file=*) import_file="${1#--file=}" ;;
		*)        pr="$1" ;;
		esac
		shift || true
	done

	local card_dir="$EAW_WORKDIR/out/$card"
	local raw_file="$card_dir/ingest/raw_card_explication.md"

	[[ -d "$card_dir" ]] || die "card $card not found"
	ensure_dir "$card_dir/ingest"

	local pr_data=""

	if [[ -n "$import_file" ]]; then
		[[ -f "$import_file" ]] || die "file not found: $import_file"
		pr_data="$(cat "$import_file")"
	elif [[ -n "$pr" ]]; then
		command -v gh >/dev/null 2>&1 || die "gh CLI not found — install from https://cli.github.com or use --file"
		local gh_args=("pr" "view" "$pr" "--json" "title,body,comments,reviews")
		[[ -n "$repo" ]] && gh_args+=("--repo" "$repo")
		pr_data="$(gh "${gh_args[@]}" 2>/dev/null)" || die "failed to fetch PR $pr"
	else
		die "usage: eaw ingest-pr <CARD> <PR_NUMBER> [--repo <REPO>] | --file <FILE>"
	fi

	{
		printf "\n\n---\n\n"
		printf "# PR Import\n\n"
		printf "%s\n" "Source: PR ${pr:-file}"
		printf "Imported: %s\n\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

		local pr_title
		pr_title="$(echo "$pr_data" | grep -o '"title":"[^"]*"' | head -1 | sed 's/"title":"//;s/"//')"
		[[ -n "$pr_title" ]] && printf "## PR Title\n\n%s\n\n" "$pr_title"

		local pr_body
		pr_body="$(echo "$pr_data" | grep -o '"body":"[^"]*"' | head -1 | sed 's/"body":"//;s/"//')"
		[[ -n "$pr_body" ]] && printf "## PR Description\n\n%s\n\n" "$pr_body"

		printf "## Comments\n\n"
		echo "$pr_data" | grep -o '"author":{"login":"[^"]*"}' | sed 's/"author":{"login":"//;s/"}//' | while read -r author; do
			local source_type="human"
			if echo "$author" | grep -qiE 'bot|copilot|codescene|github-actions|dependabot'; then
				source_type="bot"
			fi
			printf "%s\n" "- **${author}** [${source_type}]"
		done
	} >> "$raw_file"

	echo "CARD $card: PR data appended to raw_card_explication.md"
}
