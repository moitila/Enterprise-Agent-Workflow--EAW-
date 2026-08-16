#!/usr/bin/env bash
# tests/validate_envelope.sh — Non-regression tests for eaw_validate_envelope_schema.
# Covers TC-1 to TC-7 per backlog_spike_02 / H6.
# Exit 0 if all TCs pass; exit 1 if any TC fails.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1090
source "${REPO_ROOT}/scripts/commands/eaw_commands.sh"

pass=0
fail=0

run_tc() {
	local tc="$1" desc="$2" expect_pass="$3" expect_msg="${4:-}" json="${5:-}"
	local tmpdir output exit_code
	tmpdir="$(mktemp -d)"
	mkdir -p "${tmpdir}/investigations"
	printf '%s' "$json" >"${tmpdir}/investigations/20_handoff.json"
	eaw_validate_envelope_schema "" "test_phase" "$tmpdir" >"$tmpdir/_out" 2>&1
	exit_code=$?
	output="$(cat "$tmpdir/_out")"
	rm -rf "$tmpdir"
	if [[ "$expect_pass" == "pass" ]]; then
		if [[ $exit_code -eq 0 ]]; then
			printf "PASS: %s — %s\n" "$tc" "$desc"
			pass=$((pass + 1))
		else
			printf "FAIL: %s — %s (expected exit 0, got %d) stderr: %s\n" "$tc" "$desc" "$exit_code" "$output"
			fail=$((fail + 1))
		fi
	else
		if [[ $exit_code -ne 0 ]]; then
			if [[ -n "$expect_msg" ]] && ! echo "$output" | grep -q "$expect_msg"; then
				printf "FAIL: %s — %s (non-zero exit but stderr missing '%s'; got: %s)\n" "$tc" "$desc" "$expect_msg" "$output"
				fail=$((fail + 1))
			else
				printf "PASS: %s — %s\n" "$tc" "$desc"
				pass=$((pass + 1))
			fi
		else
			printf "FAIL: %s — %s (expected non-zero exit, got 0)\n" "$tc" "$desc"
			fail=$((fail + 1))
		fi
	fi
}

# TC-1: completed — accepted
run_tc "TC-1" "status=completed accepted" "pass" "" \
	'{"from_phase":"test_phase","status":"completed","messages":[],"codes":[]}'

# TC-2: skipped — accepted
run_tc "TC-2" "status=skipped accepted" "pass" "" \
	'{"from_phase":"test_phase","status":"skipped","messages":[],"codes":[]}'

# TC-3: failed — accepted
run_tc "TC-3" "status=failed accepted" "pass" "" \
	'{"from_phase":"test_phase","status":"failed","messages":[],"codes":[]}'

# TC-4: waiting with non-empty blocker — accepted (CA-1)
run_tc "TC-4" "status=waiting blocker non-empty accepted" "pass" "" \
	'{"from_phase":"test_phase","status":"waiting","blocker":"blocked by dependency X","messages":[],"codes":[]}'

# TC-5: waiting with empty blocker — rejected (CA-3)
run_tc "TC-5" "status=waiting blocker empty rejected" "fail" "blocker" \
	'{"from_phase":"test_phase","status":"waiting","blocker":"","messages":[],"codes":[]}'

# TC-6: waiting without blocker field — rejected (CA-3)
run_tc "TC-6" "status=waiting no blocker field rejected" "fail" "blocker" \
	'{"from_phase":"test_phase","status":"waiting","messages":[],"codes":[]}'

# TC-7: invalid status unknown — rejected
run_tc "TC-7" "status=unknown rejected" "fail" "status missing or invalid" \
	'{"from_phase":"test_phase","status":"unknown","messages":[],"codes":[]}'

# TC-8: messages with plain string (no type/code) — rejected (INV-B/CA-1)
run_tc "TC-8" "messages plain string rejected (no type/code)" "fail" "type in entries" \
	'{"from_phase":"test_phase","status":"completed","messages":["plain_string"],"codes":[]}'

# TC-9: messages with structured entry (type+code) — accepted (INV-B/CA-2)
# Authority: eaw_commands.sh L604-625 (runtime accepts messages with type+code)
run_tc "TC-9" "messages structured entry accepted (type+code present)" "pass" "" \
	'{"from_phase":"test_phase","status":"completed","messages":[{"type":"info","code":"PHASE_SKIPPED_BY_RULE","text":"skipped"}],"codes":[]}'

printf "\nResults: %d passed, %d failed\n" "$pass" "$fail"
exit "$(( fail > 0 ? 1 : 0 ))"
