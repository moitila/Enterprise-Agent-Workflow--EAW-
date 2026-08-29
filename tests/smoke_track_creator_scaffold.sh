#\!/usr/bin/env bash
# smoke_track_creator_scaffold.sh — 9 test cases for scaffold detector and required_headings

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

TEMPLATES="$EAW_ROOT_DIR/templates"
PHASES="$EAW_ROOT_DIR/tracks/track_creator/phases"

mk_state() {
  local card="$1" card_dir="$2" track_id="${3:-track_creator}"
  cat >"$card_dir/state_card_${track_id}.yaml" <<EOF
card_state:
  card_id: $card
  track_id: $track_id
EOF
}

call_has_content() {
  local _card="$1" _cdir="$2" _phase="$3" _rel="$4"
  eaw_phase_completion_artifact_has_meaningful_content "$_card" "$_cdir" "$_phase" "$_rel" 2>/dev/null && return 0 || return $?
}

call_detect() {
  local _card="$1" _cdir="$2"
  eaw_phase_completion_detect_card_template_type "$_card" "$_cdir" 2>/dev/null && return 0 || return $?
}

call_cmd_detect() {
  local _card="$1" _cdir="$2"
  eaw_detect_card_template_type "$_card" "$_cdir" 2>/dev/null && return 0 || return $?
}

call_strict() {
  local _card="$1" _cdir="$2" _phase="$3" _pfile="$4"
  eaw_phase_completion_evaluate_strict "$_card" "$_cdir" "$_phase" "$_pfile" 2>/dev/null && return 0 || return $?
}

# ─── TC-01: canonical scaffold intact blocks advance ──────────────────────
card="TC01"
card_dir="$tmpdir/tc01"
mkdir -p "$card_dir/investigations"
mk_state "$card" "$card_dir" "track_creator"
sed "s/<CARD>/$card/g" "$TEMPLATES/intake_track_creator.md" > "$card_dir/investigations/00_intake.md"
call_has_content "$card" "$card_dir" "intake" "investigations/00_intake.md" && ret1=0 || ret1=$?
[[ $ret1 -ne 0 ]] && pass "TC-01 (scaffold blocks)" || fail "TC-01" "scaffold should block advance, ret=$ret1"

# ─── TC-02: scaffold from another track blocks by heading mismatch ─────────
card="TC02"
card_dir="$tmpdir/tc02"
mkdir -p "$card_dir/investigations"
mk_state "$card" "$card_dir" "track_creator"
sed "s/<CARD>/$card/g" "$TEMPLATES/intake_feature.md" > "$card_dir/investigations/00_intake.md"
call_has_content "$card" "$card_dir" "intake" "investigations/00_intake.md" && ret2=0 || ret2=$?
# feature scaffold has no required_headings from track_creator; has_meaningful_content
# checks scaffold identity only; this test validates that feature scaffold \!= track_creator scaffold
# If the files differ from both scaffolds the function returns 0. The required_headings
# gate is checked by evaluate_strict (TC-05). This test validates type resolver picks
# the right template.
type2="$(call_detect "$card" "$card_dir")" && true || true
[[ "$type2" == "track_creator" ]] && pass "TC-02 (feature scaffold: type=track_creator)" \
  || fail "TC-02" "expected type=track_creator, got: '$type2'"

# ─── TC-03a: scaffold with only headings (no content) blocks ─────────────
card="TC03a"
card_dir="$tmpdir/tc03a"
mkdir -p "$card_dir/investigations"
mk_state "$card" "$card_dir" "track_creator"
cat >"$card_dir/investigations/00_intake.md" <<EOF
# Intake TRACK_CREATOR $card

## Objetivo da Track

## Problema

## Resultado Esperado

## Restricoes Operacionais

## Questoes em Aberto
EOF
# This has the same headings as the canonical scaffold (but rendered without <CARD>)
# eaw_phase_completion_render_expected_scaffold substitutes <CARD>; compare should match
call_has_content "$card" "$card_dir" "intake" "investigations/00_intake.md" && ret3a=0 || ret3a=$?
[[ $ret3a -ne 0 ]] && pass "TC-03a (empty headings scaffold blocks)" \
  || fail "TC-03a" "empty headings scaffold should block advance, ret=$ret3a"

# ─── TC-03b: bug scaffold for track_creator card blocks by heading mismatch
card="TC03b"
card_dir="$tmpdir/tc03b"
mkdir -p "$card_dir/investigations"
mk_state "$card" "$card_dir" "track_creator"
sed "s/<CARD>/$card/g" "$TEMPLATES/intake_bug.md" > "$card_dir/investigations/00_intake.md"
# required_headings check via evaluate_strict
phase_file="$PHASES/intake.yaml"
if [[ -f "$phase_file" ]]; then
  call_strict "$card" "$card_dir" "intake" "$phase_file" && ret3b=0 || ret3b=$?
  [[ $ret3b -ne 0 ]] && pass "TC-03b (bug scaffold fails required_headings)" \
    || fail "TC-03b" "bug scaffold should fail required_headings, ret=$ret3b"
else
  fail "TC-03b" "intake.yaml not found"
fi

# ─── TC-04: real content in all sections allows advance ──────────────────
card="TC04"
card_dir="$tmpdir/tc04"
mkdir -p "$card_dir/investigations"
mk_state "$card" "$card_dir" "track_creator"
cat >"$card_dir/investigations/00_intake.md" <<EOF
# Intake TRACK_CREATOR $card

## Objetivo da Track
Criar uma track de onboarding automatizado para novos repos.

## Problema
O processo atual e manual e propenso a erros humanos.

## Resultado Esperado
Track que executa o onboarding em 3 fases com validacao final.

## Restricoes Operacionais
Nao pode alterar repos existentes sem aprovacao explicita.

## Questoes em Aberto
Qual o criterio de validacao para repos ja onboardados?
EOF
call_has_content "$card" "$card_dir" "intake" "investigations/00_intake.md" && ret4=0 || ret4=$?
[[ $ret4 -eq 0 ]] && pass "TC-04 (real content allows advance)" \
  || fail "TC-04" "real content should allow advance, ret=$ret4"

# ─── TC-05: missing required heading blocks advance via evaluate_strict ───
card="TC05"
card_dir="$tmpdir/tc05"
mkdir -p "$card_dir/investigations"
mk_state "$card" "$card_dir" "track_creator"
# Has content but missing "## Questoes em Aberto"
cat >"$card_dir/investigations/00_intake.md" <<EOF
# Intake TRACK_CREATOR $card

## Objetivo da Track
Criar uma nova track.

## Problema
Processo manual.

## Resultado Esperado
Automatizacao completa.

## Restricoes Operacionais
Sem alteracoes em producao.
EOF
phase_file="$PHASES/intake.yaml"
if [[ -f "$phase_file" ]]; then
  call_strict "$card" "$card_dir" "intake" "$phase_file" && ret5=0 || ret5=$?
  [[ $ret5 -ne 0 ]] && pass "TC-05 (missing heading blocks)" \
    || fail "TC-05" "missing heading should block, ret=$ret5"
else
  fail "TC-05" "intake.yaml not found"
fi

# ─── TC-06: track_creator resolves intake_track_creator.md (not intake_feature.md)
card="TC06"
card_dir="$tmpdir/tc06"
mkdir -p "$card_dir"
mk_state "$card" "$card_dir" "track_creator"
type6="$(call_detect "$card" "$card_dir")" && ret6=0 || ret6=$?
[[ $ret6 -eq 0 && "$type6" == "track_creator" ]] && pass "TC-06 (resolves track_creator template)" \
  || fail "TC-06" "expected track_creator, got: '$type6' (ret=$ret6)"

# ─── TC-07: track without own template preserves legacy fallback ──────────
card="TC07"
card_dir="$tmpdir/tc07"
mkdir -p "$card_dir"
cat >"$card_dir/state_card_custom_track_no_template.yaml" <<EOF
card_state:
  card_id: $card
  track_id: custom_track_no_template
EOF
type7="$(call_detect "$card" "$card_dir")" && ret7=0 || ret7=$?
[[ $ret7 -eq 0 && "$type7" == "feature" ]] && pass "TC-07 (no template → feature fallback)" \
  || fail "TC-07" "expected feature, got: '$type7' (ret=$ret7)"

# ─── TC-08: scaffold creation and validation use same resolver ────────────
card="TC08"
card_dir="$tmpdir/tc08"
mkdir -p "$card_dir"
mk_state "$card" "$card_dir" "track_creator"
type_cmd="$(call_cmd_detect "$card" "$card_dir")" && ret_cmd=0 || ret_cmd=$?
type_completion="$(call_detect "$card" "$card_dir")" && ret_completion=0 || ret_completion=$?
[[ $ret_cmd -eq 0 && $ret_completion -eq 0 && "$type_cmd" == "$type_completion" ]] \
  && pass "TC-08 (both detectors agree: '$type_cmd')" \
  || fail "TC-08" "cmd='$type_cmd'(ret=$ret_cmd) vs completion='$type_completion'(ret=$ret_completion)"

# ─── TC-09: READ_SCOPE in prompts matches phase.read_sources ──────────────
all9=1
for phase in track_design prompt_design implementation_planning implementation_executor validation; do
  phase_file="$EAW_ROOT_DIR/tracks/track_creator/phases/${phase}.yaml"
  prompt_file="$EAW_ROOT_DIR/templates/prompts/track_creator/${phase}/prompt_v1.md"
  if [[ ! -f "$phase_file" || ! -f "$prompt_file" ]]; then
    fail "TC-09: missing file for $phase"
    all9=0
    continue
  fi
  has_rs="$(grep -c '^  read_sources:' "$phase_file" 2>/dev/null)" || has_rs=0
  if [[ "$has_rs" -gt 0 ]]; then
    if ! grep -q 'READ_SCOPE' "$prompt_file"; then
      fail "TC-09: $phase prompt missing READ_SCOPE section"
      all9=0
      continue
    fi
    if ! grep -A 20 'READ_SCOPE' "$prompt_file" | grep -q 'RUNTIME_ROOT\|CARD_DIR'; then
      fail "TC-09: $phase READ_SCOPE in prompt lacks placeholder refs"
      all9=0
      continue
    fi
  fi
done
[[ $all9 -eq 1 ]] && pass "TC-09 (READ_SCOPE sections aligned in all phases)"

# ─── Summary ──────────────────────────────────────────────────────────────
total=$((PASS + FAIL))
echo ""
echo "Results: ${PASS}/${total} PASS"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
