#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export TZ=UTC

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRACK_ID="ARCH_REFACTOR_ONBOARD"
STARTED_AT="2026-03-29T00:00:00Z"

fail() {
	printf "smoke_arch_refactor_onboard failed: %s\n" "$1" >&2
	exit 1
}

init_workdir() {
	local workdir="$1"
	env -u EAW_WORKDIR bash "$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
}

create_repo() {
	local repo_dir="$1"
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "smoke@ar07.test"
	git -C "$repo_dir" config user.name "smoke"
	printf "seed\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add README.md
	git -C "$repo_dir" commit -q -m "seed"
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
	EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" card "$card" --track "$TRACK_ID" "AR-07 smoke" >/dev/null
}

state_file() {
	local workdir="$1"
	local card="$2"
	printf "%s/out/%s/state_card_%s.yaml" "$workdir" "$card" "$TRACK_ID"
}

write_state() {
	local workdir="$1"
	local card="$2"
	local previous_phase="$3"
	local current_phase="$4"
	local completed_phases="$5"
	cat >"$(state_file "$workdir" "$card")" <<EOF
card_state:
  track_id: ${TRACK_ID}
  previous_phase: ${previous_phase}
  current_phase: ${current_phase}
  completed_phases:
${completed_phases}
  phase_status: RUN
  phase_started_at: ${STARTED_AT}
  phase_completed: false
  phase_completed_at: null
EOF
}

write_markdown_artifact() {
	local path="$1"
	local title="$2"
	local scenario="$3"
	mkdir -p "$(dirname "$path")"
	cat >"$path" <<EOF
# ${title}

Scenario: ${scenario}

This artifact is intentionally non-scaffold content for the AR-07 smoke harness.
EOF
}

write_handoff() {
	local workdir="$1"
	local card="$2"
	local phase="$3"
	local code="$4"
	mkdir -p "$(dirname "$(state_file "$workdir" "$card")")/investigations"
	cat >"$(dirname "$(state_file "$workdir" "$card")")/investigations/20_handoff.json" <<EOF
{"from_phase":"${phase}","status":"completed","messages":[],"codes":["${code}"]}
EOF
}

write_empty_handoff() {
	local workdir="$1"
	local card="$2"
	local phase="$3"
	mkdir -p "$(dirname "$(state_file "$workdir" "$card")")/investigations"
	cat >"$(dirname "$(state_file "$workdir" "$card")")/investigations/20_handoff.json" <<EOF
{"from_phase":"${phase}","status":"completed","messages":[],"codes":[]}
EOF
}

prime_phase() {
	local workdir="$1"
	local card="$2"
	local previous_phase="$3"
	local current_phase="$4"
	local completed_yaml="$5"
	write_state "$workdir" "$card" "$previous_phase" "$current_phase" "$completed_yaml"
}

assert_phase() {
	local workdir="$1"
	local card="$2"
	local expected="$3"
	local state
	state="$(state_file "$workdir" "$card")"
	grep -Fq "current_phase: ${expected}" "$state" || fail "expected current_phase=${expected} in ${state}"
}

run_next() {
	local workdir="$1"
	local card="$2"
	EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" next "$card" 2>&1
}

seed_onboarding_present() {
	local workdir="$1"
	local repo_key="$2"
	local onboarding_root="$workdir/context_sources/onboarding/$repo_key"
	mkdir -p "$onboarding_root/docs"
	printf 'alpha\n' >"$onboarding_root/README.md"
	printf 'beta\n' >"$onboarding_root/docs/info.txt"
	printf 'ignored\n' >"$onboarding_root/image.bin"
}

fill_ingest_artifacts() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/ingest/sources.md" "Ingest Sources" "full-flow"
	write_markdown_artifact "$workdir/out/$card/ingest/review_evidence.raw.md" "Raw Review Evidence" "full-flow"
	write_markdown_artifact "$workdir/out/$card/ingest/review_evidence.normalized.md" "Normalized Review Evidence" "full-flow"
}

fill_intake_artifacts() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/investigations/00_intake.md" "Intake Notes" "full-flow"
	write_markdown_artifact "$workdir/out/$card/investigations/_intake_provenance.md" "Intake Provenance" "full-flow"
}

fill_findings_artifact() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/investigations/20_findings.md" "Findings Notes" "full-flow"
}

fill_hypotheses_artifact() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/investigations/30_hypotheses.md" "Hypotheses Notes" "full-flow"
}

fill_planning_artifact() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/investigations/40_next_steps.md" "Planning Notes" "full-flow"
}

fill_implementation_planning_artifacts() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/implementation/00_scope.lock.md" "Scope Lock" "full-flow"
	write_markdown_artifact "$workdir/out/$card/implementation/10_change_plan.md" "Change Plan" "full-flow"
}

fill_patch_notes() {
	local workdir="$1"
	local card="$2"
	write_markdown_artifact "$workdir/out/$card/implementation/20_patch_notes.md" "Patch Notes" "full-flow"
}

run_full_flow_no_skip_scenario() {
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="AR07FLOW"
	repo_key="ar07-flow"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	seed_onboarding_present "$workdir" "$repo_key"
	create_card "$workdir" "$card"

	fill_ingest_artifacts "$workdir" "$card"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: ingest -> intake" <<<"$output" || fail "full flow missing ingest -> intake transition"
	assert_phase "$workdir" "$card" "intake"

	fill_intake_artifacts "$workdir" "$card"
	write_empty_handoff "$workdir" "$card" "intake"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: intake -> findings" <<<"$output" || fail "full flow missing intake -> findings transition"
	assert_phase "$workdir" "$card" "findings"

	fill_findings_artifact "$workdir" "$card"
	write_empty_handoff "$workdir" "$card" "findings"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> hypotheses" <<<"$output" || fail "full flow missing findings -> hypotheses transition"
	assert_phase "$workdir" "$card" "hypotheses"

	fill_hypotheses_artifact "$workdir" "$card"
	write_empty_handoff "$workdir" "$card" "hypotheses"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: hypotheses -> planning" <<<"$output" || fail "full flow missing hypotheses -> planning transition"
	assert_phase "$workdir" "$card" "planning"

	fill_planning_artifact "$workdir" "$card"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: planning -> implementation_planning" <<<"$output" || fail "full flow missing planning -> implementation_planning transition"
	assert_phase "$workdir" "$card" "implementation_planning"

	fill_implementation_planning_artifacts "$workdir" "$card"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: implementation_planning -> implementation_executor" <<<"$output" || fail "full flow missing implementation_planning -> implementation_executor transition"
	assert_phase "$workdir" "$card" "implementation_executor"
	test -f "$workdir/out/$card/prompts/implementation_executor.md" || fail "full flow missing implementation_executor prompt"

	fill_patch_notes "$workdir" "$card"
	output="$(EAW_WORKDIR="$workdir" bash "$REPO_ROOT/scripts/eaw" complete "$card" 2>&1)"
	grep -Fq "marked COMPLETE" <<<"$output" || fail "full flow missing completion message on final phase"
	grep -Fq "phase_completed: true" "$(state_file "$workdir" "$card")" || fail "full flow did not mark final phase complete"
}

run_skip_findings_scenario() {
	local tmpdir workdir repo_dir card output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="AR07SKIP1"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "ar07-skip1" "$repo_dir"
	create_card "$workdir" "$card"

	prime_phase "$workdir" "$card" "ingest" "intake" $'    - ingest\n'
	fill_intake_artifacts "$workdir" "$card"
	write_handoff "$workdir" "$card" "intake" "SIMPLE_ALIGNMENT"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: intake -> hypotheses" <<<"$output" || fail "skip findings scenario did not skip to hypotheses"
	assert_phase "$workdir" "$card" "hypotheses"
}

run_skip_hypotheses_scenario() {
	local tmpdir workdir repo_dir card output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="AR07SKIP2"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "ar07-skip2" "$repo_dir"
	create_card "$workdir" "$card"

	prime_phase "$workdir" "$card" "intake" "findings" $'    - ingest\n    - intake\n'
	fill_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "findings" "NO_CODE_DEVIATION"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "skip hypotheses scenario did not skip to planning"
	assert_phase "$workdir" "$card" "planning"
}

run_skip_planning_scenario() {
	local tmpdir workdir repo_dir card output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="AR07SKIP3"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "ar07-skip3" "$repo_dir"
	create_card "$workdir" "$card"

	prime_phase "$workdir" "$card" "hypotheses" "planning" $'    - ingest\n    - intake\n    - findings\n    - hypotheses\n'
	fill_planning_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "planning" "TRIVIAL_SCOPE"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: planning -> implementation_executor" <<<"$output" || fail "skip planning scenario did not skip to implementation_executor"
	assert_phase "$workdir" "$card" "implementation_executor"
}

run_sequential_skip_scenario() {
	local tmpdir workdir repo_dir card output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="AR07CASCADE"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "ar07-cascade" "$repo_dir"
	create_card "$workdir" "$card"

	prime_phase "$workdir" "$card" "ingest" "intake" $'    - ingest\n'
	fill_intake_artifacts "$workdir" "$card"
	write_handoff "$workdir" "$card" "intake" "SIMPLE_ALIGNMENT"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: intake -> hypotheses" <<<"$output" || fail "cascade first skip did not advance to hypotheses"
	assert_phase "$workdir" "$card" "hypotheses"

	prime_phase "$workdir" "$card" "intake" "findings" $'    - ingest\n    - intake\n'
	fill_findings_artifact "$workdir" "$card"
	write_handoff "$workdir" "$card" "findings" "NO_CODE_DEVIATION"
	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: findings -> planning" <<<"$output" || fail "cascade second skip did not advance to planning"
	assert_phase "$workdir" "$card" "planning"
}

run_onboarding_variant_scenario() {
	local onboarding_mode="$1"
	local tmpdir workdir repo_dir card repo_key output
	tmpdir="$(mktemp -d)"
	trap 'rm -rf "$tmpdir"' RETURN

	workdir="$tmpdir/workdir"
	repo_dir="$tmpdir/repo"
	card="AR07ONB-${onboarding_mode}"
	repo_key="ar07-onboarding-${onboarding_mode}"

	init_workdir "$workdir"
	create_repo "$repo_dir"
	write_repos_conf "$workdir" "$repo_key" "$repo_dir"
	create_card "$workdir" "$card"

	prime_phase "$workdir" "$card" "planning" "implementation_planning" $'    - ingest\n    - intake\n    - findings\n    - hypotheses\n    - planning\n'
	fill_implementation_planning_artifacts "$workdir" "$card"

	if [[ "$onboarding_mode" == "present" ]]; then
		seed_onboarding_present "$workdir" "$repo_key"
		test -d "$workdir/context_sources/onboarding/$repo_key" || fail "onboarding present: source tree missing"
	fi
	if [[ "$onboarding_mode" == "absent" ]]; then
		test ! -e "$workdir/context_sources/onboarding/$repo_key" || fail "onboarding absent: source tree should not exist"
	fi

	output="$(run_next "$workdir" "$card")"
	grep -Fq "CARD ${card}: implementation_planning -> implementation_executor" <<<"$output" || fail "onboarding ${onboarding_mode}: missing implementation_planning -> implementation_executor transition"
	assert_phase "$workdir" "$card" "implementation_executor"
	test -f "$workdir/out/$card/prompts/implementation_executor.md" || fail "onboarding ${onboarding_mode}: missing executor prompt"

	if [[ "$onboarding_mode" == "present" ]]; then
		test -f "$workdir/context_sources/onboarding/$repo_key/docs/info.txt" || fail "onboarding present: nested source file missing"
	fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	printf "[smoke] ARCH_REFACTOR_ONBOARD full flow without skip\n"
	run_full_flow_no_skip_scenario
	printf "[smoke] ARCH_REFACTOR_ONBOARD skip findings\n"
	run_skip_findings_scenario
	printf "[smoke] ARCH_REFACTOR_ONBOARD skip hypotheses\n"
	run_skip_hypotheses_scenario
	printf "[smoke] ARCH_REFACTOR_ONBOARD skip planning\n"
	run_skip_planning_scenario
	printf "[smoke] ARCH_REFACTOR_ONBOARD sequential skips\n"
	run_sequential_skip_scenario
	printf "[smoke] ARCH_REFACTOR_ONBOARD onboarding present\n"
	run_onboarding_variant_scenario present
	printf "[smoke] ARCH_REFACTOR_ONBOARD onboarding absent\n"
	run_onboarding_variant_scenario absent
	printf "[smoke] ARCH_REFACTOR_ONBOARD OK\n"
fi
