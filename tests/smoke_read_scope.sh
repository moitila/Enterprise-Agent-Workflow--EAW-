#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_read_scope failed: %s\n" "$1" >&2
	exit 1
}

# shellcheck source=scripts/lib.sh
source "$REPO_ROOT/scripts/lib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

allowed="$tmpdir/allowed"
mkdir -p "$allowed"

assert_read_violation() {
	local phase="$1" label="$2" source="$3"; shift 3
	local rc=0
	local err
	err="$(assert_read_scope "$phase" "$label" "$source" "$@" 2>&1)" || rc=$?
	[[ $rc -eq 97 ]] || fail "expected rc=97 for $label, got $rc"
	[[ "$err" == *"READ_SCOPE_VIOLATION: phase=$phase command=$label blocked_path="* ]] \
		|| fail "expected READ_SCOPE_VIOLATION message for $label, got: $err"
}

assert_read_pass() {
	local phase="$1" label="$2" source="$3"; shift 3
	assert_read_scope "$phase" "$label" "$source" "$@" \
		|| fail "expected rc=0 for $label"
}

# NEG-01: path absoluto fora do allowlist
touch /tmp/eaw_abs_read_violation
assert_read_violation "test_phase" "NEG-01" "/tmp/eaw_abs_read_violation" "$allowed"

# NEG-02: arquivo existente em tmpdir mas nao declarado no allowlist
touch "$tmpdir/not_declared.txt"
assert_read_violation "test_phase" "NEG-02" "$tmpdir/not_declared.txt" "$allowed"

# NEG-03: traversal relativa — ../outside.txt resolvido a partir de dentro de $allowed
touch "$tmpdir/outside.txt"
assert_read_violation "test_phase" "NEG-03" "$allowed/../outside.txt" "$allowed"

# NEG-04: path canonicalizado resulta fora do allowlist
outside_dir="$tmpdir/outside_dir"
mkdir -p "$outside_dir"
touch "$outside_dir/secret.txt"
assert_read_violation "test_phase" "NEG-04" "$outside_dir/secret.txt" "$allowed"

# NEG-05: symlink apontando para fora do allowlist
# GAP: canonicalize_scope_path fallback manual (lib.sh L95-124) nao resolve symlinks
# quando realpath esta indisponivel — source_abs aponta para o caminho do symlink,
# nao para o target real. assert_read_scope pode permitir leitura via symlink que
# aponta para fora do allowlist em ambientes sem realpath (comportamento diferente de
# quando realpath esta disponivel). Verificar: command -v realpath.
outside_link_target="$tmpdir/outside/link_target.txt"
mkdir -p "$(dirname "$outside_link_target")"
touch "$outside_link_target"
ln -s "$outside_link_target" "$allowed/evil_symlink.txt"
assert_read_violation "test_phase" "NEG-05" "$allowed/evil_symlink.txt" "$allowed"

# POS-01: arquivo existente dentro de $allowed — deve retornar 0
touch "$allowed/legit.txt"
assert_read_pass "test_phase" "POS-01" "$allowed/legit.txt" "$allowed"

printf "smoke_read_scope OK\n"
