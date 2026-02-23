#!/usr/bin/env bash

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
