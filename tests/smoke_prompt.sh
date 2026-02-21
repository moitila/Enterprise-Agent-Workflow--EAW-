#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_prompt failed: %s\n" "$1" >&2
	exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export EAW_WORKDIR="$tmpdir/.eaw"

./scripts/eaw init --workdir "$EAW_WORKDIR" --upgrade
./scripts/eaw bug 999001 "prompt smoke"

intake="$EAW_WORKDIR/out/999001/investigations/00_intake.md"
prompt_file="$EAW_WORKDIR/out/999001/agent_prompt.md"
grep -Fq "Comportamento esperado" "$intake" || fail "intake was not created from template content"

# Happy path: template intake should not trigger structural warning
happy_stderr="$tmpdir/prompt_happy.stderr"
output_happy="$(./scripts/eaw prompt 999001 2>"$happy_stderr")"
rc=$?
[[ "$rc" -eq 0 ]] || fail "expected exit code 0 in happy path, got $rc"

printf "%s\n" "$output_happy"

grep -Fq "=== EAW AGENT PROMPT (bug) CARD 999001 ===" <<<"$output_happy" || fail "missing header in happy path"
grep -Fq "out/999001/investigations/00_intake.md" <<<"$output_happy" || fail "missing intake path reference in happy path"
grep -Fq "investigations/20_findings.md" <<<"$output_happy" || fail "missing findings path in happy path"
grep -Fq "execution.log" <<<"$output_happy" || fail "missing execution.log reference in happy path"
grep -Fq "bug_999001.md" <<<"$output_happy" || fail "missing card artifact reference in happy path"
! grep -Fq "Wrote $prompt_file" <<<"$output_happy" || fail "write confirmation should not be in stdout (happy path)"
grep -Fq "Wrote $prompt_file" "$happy_stderr" || fail "missing write confirmation in stderr (happy path)"
! grep -Fq "WARN: intake appears structurally incomplete." <<<"$output_happy" || fail "unexpected structural warning in happy path"
! grep -Fq "DO NOT START INVESTIGATION BEFORE COMPLETING REQUIRED SECTIONS." <<<"$output_happy" || fail "unexpected do-not-start warning in happy path"
[[ -f "$prompt_file" ]] || fail "prompt artifact was not created in happy path"
grep -Fq "=== EAW AGENT PROMPT (bug) CARD 999001 ===" "$prompt_file" || fail "prompt artifact missing header in happy path"

# Broken path: overwrite intake to force structural warning
cat >"$intake" <<'EOF'
# Intake BUG 999001
EOF

broken_stderr="$tmpdir/prompt_broken.stderr"
output="$(./scripts/eaw prompt 999001 2>"$broken_stderr")"
rc=$?
[[ "$rc" -eq 0 ]] || fail "expected exit code 0 in broken path, got $rc"

printf "%s\n" "$output"

grep -Fq "=== EAW AGENT PROMPT (bug) CARD 999001 ===" <<<"$output" || fail "missing header in broken path"
grep -Fq "WARN: intake appears structurally incomplete." <<<"$output" || fail "missing structural warning"
grep -Fq "WARNING: DO NOT START INVESTIGATION BEFORE COMPLETING REQUIRED SECTIONS." <<<"$output" || fail "missing do-not-start warning"
! grep -Fq "Wrote $prompt_file" <<<"$output" || fail "write confirmation should not be in stdout (broken path)"
grep -Fq "Wrote $prompt_file" "$broken_stderr" || fail "missing write confirmation in stderr (broken path)"
[[ -f "$prompt_file" ]] || fail "prompt artifact missing in broken path"
grep -Fq "WARN: intake appears structurally incomplete." "$prompt_file" || fail "prompt artifact not overwritten in broken path"

printf "OK\n"
