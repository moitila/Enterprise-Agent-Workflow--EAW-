#!/usr/bin/env bash
# test_followup_candidates.sh — Unit tests for eaw_generate_followup_candidates()
# TC1–TC5: scope.lock variants
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1090
source "$REPO_ROOT/scripts/commands/eaw_commands.sh"

PASS=0
FAIL=0

pass() { printf "PASS: %s\n" "$1"; PASS=$(( PASS + 1 )); }
fail_tc() { printf "FAIL: %s\n" "$1" >&2; FAIL=$(( FAIL + 1 )); }

TMPDIR_TESTS="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TESTS"' EXIT

# TC1: scope.lock absent → _followup_candidates.md NOT created; exit 0
test_tc1_scope_lock_absent() {
	local card_dir="$TMPDIR_TESTS/tc1"
	mkdir -p "$card_dir"
	eaw_generate_followup_candidates "$card_dir"
	if [[ -f "$card_dir/_followup_candidates.md" ]]; then
		fail_tc "TC1: _followup_candidates.md created when scope.lock absent"
	else
		pass "TC1: scope.lock absent → no file generated"
	fi
}

# TC2: ## Out of Scope present but empty → _followup_candidates.md NOT created; exit 0
test_tc2_out_of_scope_empty() {
	local card_dir="$TMPDIR_TESTS/tc2"
	mkdir -p "$card_dir/implementation"
	cat > "$card_dir/implementation/00_scope.lock.md" << 'EOF'
# Scope Lock

## Out of Scope

## Allowlist de Escrita
EOF
	eaw_generate_followup_candidates "$card_dir"
	if [[ -f "$card_dir/_followup_candidates.md" ]]; then
		fail_tc "TC2: _followup_candidates.md created for empty Out of Scope"
	else
		pass "TC2: empty Out of Scope → no file generated"
	fi
}

# TC3: bullets present → file created with ## Candidate 1 and Suggested track: TBD
test_tc3_bullets_present() {
	local card_dir="$TMPDIR_TESTS/tc3"
	mkdir -p "$card_dir/implementation"
	cat > "$card_dir/implementation/00_scope.lock.md" << 'EOF'
# Scope Lock

## Out of Scope

- Feature candidata alpha
- Feature candidata beta

## Allowlist de Escrita
EOF
	eaw_generate_followup_candidates "$card_dir"
	if [[ ! -f "$card_dir/_followup_candidates.md" ]]; then
		fail_tc "TC3: _followup_candidates.md not created for bullets"
		return
	fi
	if ! grep -q "## Candidate 1" "$card_dir/_followup_candidates.md"; then
		fail_tc "TC3: ## Candidate 1 missing from output"
		return
	fi
	if ! grep -q "Suggested track: TBD" "$card_dir/_followup_candidates.md"; then
		fail_tc "TC3: Suggested track: TBD missing from output"
		return
	fi
	pass "TC3: bullets → file with Candidate 1 and TBD generated"
}

# TC4: table format (|) → file created with ## Unsupported Out of Scope content
test_tc4_table_unsupported() {
	local card_dir="$TMPDIR_TESTS/tc4"
	mkdir -p "$card_dir/implementation"
	cat > "$card_dir/implementation/00_scope.lock.md" << 'EOF'
# Scope Lock

## Out of Scope

| Feature | Priority |
|---------|----------|
| Alpha   | High     |

## Allowlist de Escrita
EOF
	eaw_generate_followup_candidates "$card_dir"
	if [[ ! -f "$card_dir/_followup_candidates.md" ]]; then
		fail_tc "TC4: _followup_candidates.md not created for table format"
		return
	fi
	if ! grep -q "## Unsupported Out of Scope content" "$card_dir/_followup_candidates.md"; then
		fail_tc "TC4: ## Unsupported Out of Scope content missing"
		return
	fi
	pass "TC4: table → unsupported file generated"
}

# TC5: subsection (###) + bullets → file created with ## Unsupported Out of Scope content
test_tc5_subsection_unsupported() {
	local card_dir="$TMPDIR_TESTS/tc5"
	mkdir -p "$card_dir/implementation"
	cat > "$card_dir/implementation/00_scope.lock.md" << 'EOF'
# Scope Lock

## Out of Scope

### Subsection A

- Item under subsection

## Allowlist de Escrita
EOF
	eaw_generate_followup_candidates "$card_dir"
	if [[ ! -f "$card_dir/_followup_candidates.md" ]]; then
		fail_tc "TC5: _followup_candidates.md not created for subsection format"
		return
	fi
	if ! grep -q "## Unsupported Out of Scope content" "$card_dir/_followup_candidates.md"; then
		fail_tc "TC5: ## Unsupported Out of Scope content missing"
		return
	fi
	pass "TC5: subsection → unsupported file generated"
}

test_tc1_scope_lock_absent
test_tc2_out_of_scope_empty
test_tc3_bullets_present
test_tc4_table_unsupported
test_tc5_subsection_unsupported

printf "\nResults: %d passed, %d failed\n" "$PASS" "$FAIL"
if [[ "$FAIL" -gt 0 ]]; then
	exit 1
fi
exit 0
