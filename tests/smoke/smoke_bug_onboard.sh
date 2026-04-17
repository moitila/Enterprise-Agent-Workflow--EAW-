#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export TZ=UTC

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRACK_ID="bug_ONBOARD"
STARTED_AT="2026-04-17T00:00:00Z"

fail() {
	printf "smoke_bug_onboard failed: %s\n" "$1" >&2
	exit 1
}

init_workdir() {
	local workdir="$1"
	env -u EAW_WORKDIR -u EAW_OUT_DIR bash "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
}

create_repo() {
	local repo_dir="$1"
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@bug-onboard.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "fixture\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add README.md
	git -C "$repo_dir" commit -q -m "fixture"
}

write_repos_conf() {
	local workdir="$1"
	local repo_key="$2"
	local repo_dir="$3"
	cat >"$workdir/config/repos.conf" <<EOF
${repo_key}|${repo_dir}|target
EOF
}

create_card() {
	local workdir="$1"
	local card="$2"
	EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" card "$card" --track "$TRACK_ID" "bug onboard smoke" >/dev/null
}

state_file() {
	local workdir="$1"
	local card="$2"
	printf "%s/out/%s/state_card_%s.yaml" "$workdir" "$card" "$TRACK_ID"
}

prime_findings_state() {
	local workdir="$1"
	local card="$2"
	cat >"$(state_file "$workdir" "$card")" <<EOF
card_state:
  track_id: ${TRACK_ID}
  previous_phase: intake
  current_phase: findings
  completed_phases:
    - intake
  phase_status: RUN
  phase_started_at: ${STARTED_AT}
  phase_completed: false
  phase_completed_at: null
EOF
}

write_intake_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/00_intake.md" <<EOF
# 00_intake

Smoke intake for ${card}.
EOF
}

write_ingest_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/ingest"
	cat >"$workdir/out/$card/ingest/sources.md" <<EOF
Smoke sources for ${card}.
EOF
}

write_findings_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/20_findings.md" <<EOF
# 20_findings

Smoke findings for ${card}.
EOF
}

write_hypotheses_artifact() {
	local workdir="$1"
	local card="$2"
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/30_hypotheses.md" <<EOF
# 30_hypotheses

Smoke hypotheses for ${card}.
EOF
}

write_handoff() {
	local workdir="$1"
	local card="$2"
	shift 2
	local codes_json=""
	local code
	local first=1
	for code in "$@"; do
		if [[ $first -eq 1 ]]; then
			codes_json="\"${code}\""
			first=0
		else
			codes_json="${codes_json},\"${code}\""
		fi
	done
	mkdir -p "$workdir/out/$card/investigations"
	cat >"$workdir/out/$card/investigations/20_handoff.json" <<EOF
{"from_phase":"findings","status":"completed","messages":[],"codes":[${codes_json}]}
EOF
}

seed_onboarding_source() {
	local workdir="$1"
	local repo_key="$2"
	mkdir -p "$workdir/context_sources/onboarding/$repo_key/docs"
	cat >"$workdir/context_sources/onboarding/$repo_key/README.md" <<'EOF'
debug_first onboarding
EOF
	cat >"$workdir/context_sources/onboarding/$repo_key/docs/debug.md" <<'EOF'
set -x
doctor
validate
EOF
}

seed_onboarding_context() {
	local workdir="$1"
	local card="$2"
	local source_key="$3"
	local provenance_status="$4"
	local target_dir="$workdir/out/$card/context/onboarding"

	mkdir -p "$target_dir/docs"
	cp "$workdir/context_sources/onboarding/$source_key/README.md" "$target_dir/README.md"
	cp "$workdir/context_sources/onboarding/$source_key/docs/debug.md" "$target_dir/docs/debug.md"
	cat >"$target_dir/provenance.md" <<EOF
# Onboarding Provenance

source_status: ${provenance_status}
source_root: $workdir/context_sources/onboarding/$source_key
EOF
}

write_absent_onboarding_provenance() {
	local workdir="$1"
	local card="$2"
	local target_dir="$workdir/out/$card/context/onboarding"
	mkdir -p "$target_dir"
	cat >"$target_dir/provenance.md" <<'EOF'
# Onboarding Provenance

source_status: absent
EOF
}

assert_state_phase() {
	local workdir="$1"
	local card="$2"
	local expected="$3"
	local file
	file="$(state_file "$workdir" "$card")"
	grep -Fq "current_phase: ${expected}" "$file" || fail "expected current_phase=${expected} in ${file}"
}

run_next() {
	local workdir="$1"
	local card="$2"
	EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" next "$card" 2>&1
}

run_full_flow_scenario() {
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="BO06FLOW"
	repo_key="bo06-flow"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "REGRESSION_CLEAR"

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> hypotheses" <<<"$output" || fail "full flow did not advance findings -> hypotheses"
	assert_state_phase "$workdir" "$card" "hypotheses"

	write_hypotheses_artifact "$workdir" "$card"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: hypotheses -> planning" <<<"$output" || fail "full flow did not advance hypotheses -> planning"
	assert_state_phase "$workdir" "$card" "planning"
}

run_skip_root_cause_scenario() {
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="BO06SKIP"
	repo_key="bo06-skip"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "ROOT_CAUSE_CONFIRMED"

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "ROOT_CAUSE_CONFIRMED did not skip findings -> planning"
	assert_state_phase "$workdir" "$card" "planning"
}

run_regression_clear_matrix_scenario() {
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="BO06REG1"
	repo_key="bo06-reg1"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "REGRESSION_CLEAR"

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> hypotheses" <<<"$output" || fail "REGRESSION_CLEAR-only case should not skip findings"
	assert_state_phase "$workdir" "$card" "hypotheses"

	rm -rf "$tmpdir"
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="BO06REG2"
	repo_key="bo06-reg2"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "ROOT_CAUSE_CONFIRMED"

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "ROOT_CAUSE_CONFIRMED case should skip findings"
	assert_state_phase "$workdir" "$card" "planning"
}

run_debug_first_scenario() {
	local tmpdir workdir repo_dir card repo_key output prompt_file
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="BO06DBG"
	repo_key="bo06-debug-first"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_ingest_artifact "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"
	seed_onboarding_source "$workdir" "$repo_key"
	seed_onboarding_context "$workdir" "$card" "$repo_key" "present"

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> hypotheses" <<<"$output" || fail "debug_first scenario did not advance to hypotheses"

	prompt_file="$workdir/out/$card/prompts/hypotheses.md"
	test -f "$prompt_file" || fail "debug_first scenario missing hypotheses prompt"
	grep -Fq "CONTEXT - ONBOARDING" "$prompt_file" || fail "debug_first scenario prompt missing onboarding context"
	grep -Fq "debug_first onboarding" "$prompt_file" || fail "debug_first scenario prompt missing seeded onboarding content"
}

run_source_absent_scenario() {
	local tmpdir workdir repo_dir card repo_key output prompt_file
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="BO06ABS"
	repo_key="bo06-absent"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"
	prime_findings_state "$workdir" "$card"
	write_intake_artifact "$workdir" "$card"
	write_ingest_artifact "$workdir" "$card"
	write_findings_artifact "$workdir" "$card"

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> hypotheses" <<<"$output" || fail "source absent scenario did not advance to hypotheses"

	prompt_file="$workdir/out/$card/prompts/hypotheses.md"
	test -f "$prompt_file" || fail "source absent scenario missing hypotheses prompt"
	grep -Fvq "CONTEXT - ONBOARDING" "$prompt_file" || fail "source absent scenario unexpectedly injected onboarding context"
}

printf "[smoke] full flow findings -> hypotheses -> planning\n"
run_full_flow_scenario
printf "[smoke] ROOT_CAUSE_CONFIRMED skip\n"
run_skip_root_cause_scenario
printf "[smoke] REGRESSION_CLEAR matrix\n"
run_regression_clear_matrix_scenario
printf "[smoke] debug_first onboarding\n"
run_debug_first_scenario
printf "[smoke] source_status absent\n"
run_source_absent_scenario
printf "[smoke] bug_ONBOARD OK\n"
