#\!/usr/bin/env bash
# smoke_track_creator_read_sources.sh — 20 test cases for phase.read_sources parser + resolver
# Sections: TC-01..TC-10 (parser), RS-11..RS-19 (resolver + assert_read_scope)

set -uo pipefail

EAW_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$EAW_ROOT_DIR/scripts/commands/eaw_commands.sh" 2>/dev/null || {
  echo "FAIL: could not source eaw_commands.sh" >&2; exit 1
}
source "$EAW_ROOT_DIR/scripts/lib.sh" 2>/dev/null || {
  echo "FAIL: could not source lib.sh" >&2; exit 1
}
resolve_workdirs "$EAW_ROOT_DIR"

PASS=0
FAIL=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }

# Helper: run resolver and capture exit code without triggering pipefail
capture_resolve() {
  local _raw_path="$1"; shift
  eaw_resolve_read_source_item "$_raw_path" 2>&1 && return 0 || return $?
}

capture_assert() {
  local _scope="$1" _path="$2"
  assert_read_scope "test_phase" "test_cmd" "$_path" "$_scope" 2>&1 && return 0 || return $?
}

# ─── TC-01: phase.read_sources nested under phase: is recognized ──────────
cat >"$tmpdir/tc01.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  read_sources:
    - "{{RUNTIME_ROOT}}/docs/foo.md"
EOF
out="$(eaw_yaml_phase_read_sources "$tmpdir/tc01.yaml")"
[[ "$out" == "{{RUNTIME_ROOT}}/docs/foo.md" ]] && pass "TC-01" || fail "TC-01" "got: '$out'"

# ─── TC-02: top-level read_sources ignored ────────────────────────────────
cat >"$tmpdir/tc02.yaml" <<'EOF'
config_version: 1
read_sources:
  - "{{RUNTIME_ROOT}}/docs/foo.md"
phase:
  id: test
EOF
out="$(eaw_yaml_phase_read_sources "$tmpdir/tc02.yaml")"
[[ -z "$out" ]] && pass "TC-02" || fail "TC-02" "should be empty, got: '$out'"

# ─── TC-03: absent phase.read_sources produces empty output ──────────────
cat >"$tmpdir/tc03.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  name: Test Phase
EOF
out="$(eaw_yaml_phase_read_sources "$tmpdir/tc03.yaml")"
[[ -z "$out" ]] && pass "TC-03" || fail "TC-03" "should be empty, got: '$out'"

# ─── TC-04: empty read_sources list produces empty output ─────────────────
cat >"$tmpdir/tc04.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  read_sources: []
EOF
out="$(eaw_yaml_phase_read_sources "$tmpdir/tc04.yaml")"
[[ -z "$out" ]] && pass "TC-04" || fail "TC-04" "should be empty, got: '$out'"

# ─── TC-05: RUNTIME_ROOT placeholder resolved to absolute path ────────────
mkdir -p "$tmpdir/rt5/docs"
touch "$tmpdir/rt5/docs/foo.md"
cat >"$tmpdir/tc05.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  read_sources:
    - "{{RUNTIME_ROOT}}/docs/foo.md"
EOF
raw5="$(eaw_yaml_phase_read_sources "$tmpdir/tc05.yaml" | head -1)"
resolved5="$(RUNTIME_ROOT="$tmpdir/rt5" capture_resolve "$raw5")" && ret5=0 || ret5=$?
[[ $ret5 -eq 0 && "$resolved5" == "$tmpdir/rt5/docs/foo.md" ]] && pass "TC-05" || fail "TC-05" "ret=$ret5 resolved='$resolved5'"

# ─── TC-06: CARD_DIR placeholder resolved to absolute path ───────────────
mkdir -p "$tmpdir/card/investigations"
cat >"$tmpdir/tc06.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  read_sources:
    - "{{CARD_DIR}}/investigations"
EOF
raw6="$(eaw_yaml_phase_read_sources "$tmpdir/tc06.yaml" | head -1)"
resolved6="$(CARD_DIR="$tmpdir/card" capture_resolve "$raw6")" && ret6=0 || ret6=$?
[[ $ret6 -eq 0 && "$resolved6" == "$tmpdir/card/investigations" ]] && pass "TC-06" || fail "TC-06" "ret=$ret6 resolved='$resolved6'"

# ─── TC-07: unknown placeholder blocks with error ─────────────────────────
resolved7="$(capture_resolve "{{UNKNOWN_VAR}}/docs/foo.md")" && ret7=0 || ret7=$?
[[ $ret7 -ne 0 ]] && pass "TC-07" || fail "TC-07" "should have failed, got ret=$ret7 resolved='$resolved7'"

# ─── TC-08: relative path after resolution blocks with error ─────────────
resolved8="$(RUNTIME_ROOT="$tmpdir" capture_resolve "relative/path/file.md")" && ret8=0 || ret8=$?
[[ $ret8 -ne 0 ]] && pass "TC-08" || fail "TC-08" "should have failed, got ret=$ret8"

# ─── TC-09: path with traversal blocks with error ────────────────────────
mkdir -p "$tmpdir/rt9/docs"
touch "$tmpdir/rt9/docs/bar.md"
resolved9="$(RUNTIME_ROOT="$tmpdir/rt9" capture_resolve "{{RUNTIME_ROOT}}/docs/../docs/bar.md")" && ret9=0 || ret9=$?
[[ $ret9 -ne 0 ]] && pass "TC-09" || fail "TC-09" "should have failed, got ret=$ret9"

# ─── TC-10: bundle contains expected absolute paths after resolution ──────
mkdir -p "$tmpdir/rt10/docs" "$tmpdir/rt10/tracks"
touch "$tmpdir/rt10/docs/CONTRACT.md"
cat >"$tmpdir/tc10.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  read_sources:
    - "{{RUNTIME_ROOT}}/docs/CONTRACT.md"
    - "{{RUNTIME_ROOT}}/tracks"
EOF
result10=""
while IFS= read -r item10; do
  [[ -n "$item10" ]] || continue
  ri10="$(RUNTIME_ROOT="$tmpdir/rt10" capture_resolve "$item10")" && r10=0 || r10=$?
  [[ $r10 -eq 0 ]] && result10+="$ri10"$'\n'
done < <(eaw_yaml_phase_read_sources "$tmpdir/tc10.yaml")
[[ "$result10" == *"$tmpdir/rt10/docs/CONTRACT.md"* && "$result10" == *"$tmpdir/rt10/tracks"* ]] && pass "TC-10" || fail "TC-10" "got: $result10"

# ─── RS-11: assert_read_scope accepts declared source (exit 0) ────────────
mkdir -p "$tmpdir/rs11/docs"
touch "$tmpdir/rs11/docs/file.md"
capture_assert "$tmpdir/rs11/docs" "$tmpdir/rs11/docs/file.md" && ret11=0 || ret11=$?
[[ $ret11 -eq 0 ]] && pass "RS-11" || fail "RS-11" "exit=$ret11"

# ─── RS-12: assert_read_scope rejects undeclared source (exit non-zero) ──
mkdir -p "$tmpdir/rs12/docs" "$tmpdir/rs12/other"
touch "$tmpdir/rs12/other/file.md"
capture_assert "$tmpdir/rs12/docs" "$tmpdir/rs12/other/file.md" && ret12=0 || ret12=$?
[[ $ret12 -ne 0 ]] && pass "RS-12" || fail "RS-12" "should have failed, exit=$ret12"

# ─── RS-13: empty env var for placeholder blocks materialization ─────────
resolved13="$(RUNTIME_ROOT="" capture_resolve "{{RUNTIME_ROOT}}/docs/file.md")" && ret13=0 || ret13=$?
[[ $ret13 -ne 0 ]] && pass "RS-13" || fail "RS-13" "should have failed, exit=$ret13"

# ─── RS-14a: path with spaces in quoted string preserved ─────────────────
mkdir -p "$tmpdir/path with spaces"
touch "$tmpdir/path with spaces/file.md"
cat >"$tmpdir/tc14a.yaml" <<EOF
config_version: 1
phase:
  id: test
  read_sources:
    - "{{RUNTIME_ROOT}}/path with spaces/file.md"
EOF
raw14a="$(eaw_yaml_phase_read_sources "$tmpdir/tc14a.yaml" | head -1)"
resolved14a="$(RUNTIME_ROOT="$tmpdir" capture_resolve "$raw14a")" && ret14a=0 || ret14a=$?
[[ $ret14a -eq 0 && "$resolved14a" == "$tmpdir/path with spaces/file.md" ]] && pass "RS-14a" || fail "RS-14a" "ret=$ret14a resolved='$resolved14a'"

# ─── RS-14b: unquoted path with space — contract-undefined, no crash ─────
cat >"$tmpdir/tc14b.yaml" <<EOF
config_version: 1
phase:
  id: test
  read_sources:
    - {{RUNTIME_ROOT}}/path with spaces/file.md
EOF
raw14b="$(eaw_yaml_phase_read_sources "$tmpdir/tc14b.yaml" | head -1)"
RUNTIME_ROOT="$tmpdir" capture_resolve "$raw14b" > /dev/null 2>&1 || true
pass "RS-14b (no crash regardless of outcome)"

# ─── RS-15: multiple items maintain order and separation ─────────────────
mkdir -p "$tmpdir/rt15/a" "$tmpdir/rt15/b"
cat >"$tmpdir/tc15.yaml" <<'EOF'
config_version: 1
phase:
  id: test
  read_sources:
    - "{{RUNTIME_ROOT}}/a"
    - "{{RUNTIME_ROOT}}/b"
EOF
lines15="$(eaw_yaml_phase_read_sources "$tmpdir/tc15.yaml")"
first15="$(echo "$lines15" | head -1)"
second15="$(echo "$lines15" | tail -1)"
[[ "$first15" == "{{RUNTIME_ROOT}}/a" && "$second15" == "{{RUNTIME_ROOT}}/b" ]] && pass "RS-15" || fail "RS-15" "got: '$lines15'"

# ─── RS-16: non-existent path after resolution blocks ────────────────────
resolved16="$(RUNTIME_ROOT="$tmpdir" capture_resolve "{{RUNTIME_ROOT}}/does_not_exist_xyz987.md")" && ret16=0 || ret16=$?
[[ $ret16 -ne 0 ]] && pass "RS-16" || fail "RS-16" "should have failed, ret=$ret16"

# ─── RS-17: malformed outer quote blocks materialization ─────────────────
resolved17="$(RUNTIME_ROOT="$tmpdir" capture_resolve '"path without closing quote')" && ret17=0 || ret17=$?
[[ $ret17 -ne 0 ]] && pass "RS-17" || fail "RS-17" "should have failed, ret=$ret17 resolved='$resolved17'"

# ─── RS-18: descendant of authorized dir accepted by assert_read_scope ───
mkdir -p "$tmpdir/rs18/docs/sub"
touch "$tmpdir/rs18/docs/sub/child.md"
capture_assert "$tmpdir/rs18/docs" "$tmpdir/rs18/docs/sub/child.md" && ret18=0 || ret18=$?
[[ $ret18 -eq 0 ]] && pass "RS-18" || fail "RS-18" "exit=$ret18"

# ─── RS-19: sibling dir outside authorized dir rejected ──────────────────
mkdir -p "$tmpdir/rs19/docs" "$tmpdir/rs19/docs_sibling"
touch "$tmpdir/rs19/docs_sibling/file.md"
capture_assert "$tmpdir/rs19/docs" "$tmpdir/rs19/docs_sibling/file.md" && ret19=0 || ret19=$?
[[ $ret19 -ne 0 ]] && pass "RS-19" || fail "RS-19" "should have failed, exit=$ret19"

# ─── Summary ──────────────────────────────────────────────────────────────
total=$((PASS + FAIL))
echo ""
echo "Results: ${PASS}/${total} PASS"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
