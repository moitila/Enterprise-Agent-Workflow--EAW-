#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_EXPECTED="$REPO_ROOT/tests/baseline/expected/bug_intake.capture"
CARD_ID="BASELINE01"
TRACK_ID="bug"
TITLE="content baseline fixture"

fail() {
	printf "run_content_baseline failed: %s\n" "$1" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage: bash tests/baseline/run_content_baseline.sh [--update-expected] [--expected PATH]

Default: compare a fresh, normalized capture against the versioned expected baseline.
--update-expected: deliberately replace the expected baseline after the
                   two-fixture determinism check passes.
--expected PATH: compare against an alternate expected file without modifying it.
EOF
}

create_repo() {
	local repo_dir="$1"
	mkdir -p "$repo_dir"
	git -C "$repo_dir" init -q
	git -C "$repo_dir" config user.email "baseline@example.com"
	git -C "$repo_dir" config user.name "baseline"
	printf "plain readme\n" >"$repo_dir/README.md"
	git -C "$repo_dir" add README.md
	git -C "$repo_dir" commit -q -m "baseline fixture repo"
}

write_repos_conf() {
	local workdir="$1"
	local repo_dir="$2"
	cat >"$workdir/config/repos.conf" <<EOF
baseline-target|$repo_dir|target
EOF
}

normalize_paths() {
	local repo_dir="$1"
	local workdir="$2"
	sed "s|$REPO_ROOT|<RUNTIME_ROOT>|g; s|$repo_dir|<REPO_DIR>|g; s|$workdir|<WORKDIR>|g"
}

normalize_state() {
	sed -E \
		-e 's/^([[:space:]]*(phase_started_at|phase_completed_at): )[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z/\1<TIMESTAMP>/' \
		-e 's/^([[:space:]]*(created_at|updated_at): )"?[0-9]{4}-[0-9]{2}-[0-9]{2}"?/\1<TIMESTAMP>/'
}

normalize_journal() {
	sed -E \
		-e 's/"timestamp":"[^"]+"/"timestamp":"<TIMESTAMP>"/g' \
		-e 's/"duration_ms":[0-9]+/"duration_ms":<DURATION_MS>/g'
}

normalize_cli() {
	sed -E \
		-e 's/\([0-9]+ms\)/(<DURATION_MS>)/g' \
		-e 's/^([[:alnum:]_]+\|[A-Z_]+\|)[0-9]+\|/\1<DURATION_MS>|/' \
		-e 's/"timestamp":"[^"]+"/"timestamp":"<TIMESTAMP>"/g' \
		-e 's/"duration_ms":[0-9]+/"duration_ms":<DURATION_MS>/g'
}

normalize_provenance() {
	sed -E 's/\b[0-9a-f]{40}\b/<GIT_COMMIT>/g'
}

normalize_prompt() {
	sed -E 's/^CANONICAL_PATH: .*/CANONICAL_PATH: <EXECUTION_PATH>/'
}

capture_command() {
	local run_root="$1"
	local capture_file="$2"
	local label="$3"
	shift 3
	local stdout_file="$run_root/$label.stdout"
	local stderr_file="$run_root/$label.stderr"
	local rc

	set +e
	EAW_WORKDIR="$run_root/workdir" "$REPO_ROOT/scripts/eaw" "$@" >"$stdout_file" 2>"$stderr_file"
	rc=$?
	set -e

	{
		printf '## CLI: %s\n' "$label"
		printf '### stdout\n'
		normalize_paths "$run_root/repo" "$run_root/workdir" <"$stdout_file" | normalize_cli
		printf '### stderr\n'
		normalize_paths "$run_root/repo" "$run_root/workdir" <"$stderr_file" | normalize_cli
		printf '### exit_code\n%s\n' "$rc"
	} >>"$capture_file"
}

capture_file() {
	local capture_file="$1"
	local heading="$2"
	local path="$3"
	local normalizer="$4"
	local repo_dir="$5"
	local workdir="$6"

	printf -- '--- %s ---\n' "$heading" >>"$capture_file"
	normalize_paths "$repo_dir" "$workdir" <"$path" | "$normalizer" >>"$capture_file"
}

capture_flow() {
	local run_root="$1"
	local capture_file="$2"
	local repo_dir="$run_root/repo"
	local workdir="$run_root/workdir"
	local card_dir="$workdir/out/$CARD_ID"
	local artifact_path relative

	create_repo "$repo_dir"
	"$REPO_ROOT/scripts/eaw" init --workdir "$workdir" --force >/dev/null
	write_repos_conf "$workdir" "$repo_dir"
	: >"$capture_file"

	capture_command "$run_root" "$capture_file" card card "$CARD_ID" --track "$TRACK_ID" "$TITLE"
	capture_command "$run_root" "$capture_file" doctor doctor
	capture_command "$run_root" "$capture_file" validate validate
	capture_command "$run_root" "$capture_file" preflight preflight "$CARD_ID"
	capture_command "$run_root" "$capture_file" status status "$CARD_ID"
	capture_command "$run_root" "$capture_file" next next "$CARD_ID"

	printf '## PROMPTS\n' >>"$capture_file"
	if [[ -d "$card_dir/prompts" ]]; then
		while IFS= read -r artifact_path; do
			relative="${artifact_path#"$card_dir/"}"
			capture_file "$capture_file" "$relative" "$artifact_path" normalize_prompt "$repo_dir" "$workdir"
		done < <(find "$card_dir/prompts" -maxdepth 1 -type f | LC_ALL=C sort)
	else
		printf 'MISSING: prompts\n' >>"$capture_file"
	fi

	printf '## STATE\n' >>"$capture_file"
	while IFS= read -r artifact_path; do
		relative="${artifact_path#"$card_dir/"}"
		capture_file "$capture_file" "$relative" "$artifact_path" normalize_state "$repo_dir" "$workdir"
	done < <(find "$card_dir" -maxdepth 1 -type f -name 'state_card_*.yaml' | LC_ALL=C sort)

	printf '## JOURNAL\n' >>"$capture_file"
	if [[ -f "$card_dir/execution_journal.jsonl" ]]; then
		capture_file "$capture_file" "execution_journal.jsonl" "$card_dir/execution_journal.jsonl" normalize_journal "$repo_dir" "$workdir"
	else
		printf 'MISSING: execution_journal.jsonl\n' >>"$capture_file"
	fi

	printf '## ARTIFACTS\n' >>"$capture_file"
	if [[ -d "$card_dir/investigations" ]]; then
		while IFS= read -r artifact_path; do
			relative="${artifact_path#"$card_dir/"}"
			capture_file "$capture_file" "$relative" "$artifact_path" cat "$repo_dir" "$workdir"
		done < <(find "$card_dir/investigations" -type f | LC_ALL=C sort)
	else
		printf 'MISSING: investigations\n' >>"$capture_file"
	fi

	if [[ -f "$card_dir/provenance/git_snapshot.md" ]]; then
		capture_file "$capture_file" "provenance/git_snapshot.md" "$card_dir/provenance/git_snapshot.md" normalize_provenance "$repo_dir" "$workdir"
	fi
}

run_one() {
	local run_root="$1"
	local capture_file="$2"
	mkdir -p "$run_root"
	capture_flow "$run_root" "$capture_file"
}

compare_captures() {
	local left="$1"
	local right="$2"
	local label="$3"
	local diff_output

	if diff_output="$(diff -u "$left" "$right")"; then
		return 0
	fi
	printf '%s\n' "$diff_output" >&2
	fail "$label"
}

main() {
	local mode="check"
	local expected="$DEFAULT_EXPECTED"
	local expected_overridden="false"
	local tmp_root run1 run2 capture1 capture2

	while (($#)); do
		case "$1" in
			--update-expected)
				mode="update"
				;;
			--expected)
				shift
				(($#)) || fail "--expected requires a path"
				expected="$1"
				expected_overridden="true"
				;;
			-h|--help)
				usage
				exit 0
				;;
			*)
				fail "unknown argument: $1"
				;;
		esac
		shift
		done

	if [[ "$mode" == "update" && "$expected_overridden" == "true" ]]; then
		fail "--update-expected cannot be combined with --expected; it updates only $DEFAULT_EXPECTED"
	fi

	command -v git >/dev/null 2>&1 || fail "git not available"
	command -v sed >/dev/null 2>&1 || fail "sed not available"
	test -f "$REPO_ROOT/scripts/eaw" || fail "scripts/eaw not found under $REPO_ROOT"

	tmp_root="$(mktemp -d)"
	trap "rm -rf -- '$tmp_root'" EXIT
	run1="$tmp_root/run1"
	run2="$tmp_root/run2"
	capture1="$tmp_root/capture1.normalized"
	capture2="$tmp_root/capture2.normalized"

	run_one "$run1" "$capture1"
	run_one "$run2" "$capture2"
	compare_captures "$capture1" "$capture2" "determinism check failed: independent fixtures diverged"

	if [[ "$mode" == "update" ]]; then
		mkdir -p "$(dirname "$expected")"
		cp "$capture1" "$expected"
		printf 'run_content_baseline: UPDATED expected baseline: %s\n' "$expected"
		exit 0
	fi

	test -f "$expected" || fail "expected baseline missing: $expected; run with --update-expected deliberately"
	compare_captures "$expected" "$capture1" "regression check failed: actual capture differs from expected baseline"
	printf 'run_content_baseline: PASS (determinism and regression checks passed)\n'
}

main "$@"
