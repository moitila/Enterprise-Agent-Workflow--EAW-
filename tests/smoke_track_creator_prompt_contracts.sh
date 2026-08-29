#!/usr/bin/env bash
# smoke_track_creator_prompt_contracts.sh -- valida contracts dos prompts v2 de track_creator

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1 -- $2"; FAIL=$((FAIL + 1)); }

phases=(prompt_design implementation_executor validation)

for phase in "${phases[@]}"; do
  base="$REPO_ROOT/templates/prompts/track_creator/$phase"

  active_val="$(tr -d '[:space:]' <"$base/ACTIVE" 2>/dev/null || echo MISSING)"
  if [[ "$active_val" == "2" ]]; then
    pass "$phase: ACTIVE=2"
  else
    fail "$phase: ACTIVE=2" "got '$active_val'"
  fi

  if [[ -s "$base/prompt_v2.md" ]]; then
    pass "$phase: prompt_v2.md existe e nao esta vazio"
  else
    fail "$phase: prompt_v2.md existe e nao esta vazio" "arquivo ausente ou vazio"
  fi

  first_line="$(head -1 "$base/prompt_v2.md" 2>/dev/null || echo "")"
  if echo "$first_line" | grep -q 'RUNTIME_ENVIRONMENT'; then
    pass "$phase: primeira linha contem RUNTIME_ENVIRONMENT"
  else
    fail "$phase: primeira linha contem RUNTIME_ENVIRONMENT" "primeira linha: $first_line"
  fi

  if [[ -f "$base/prompt_v2.meta" ]]; then
    pass "$phase: prompt_v2.meta existe"
  else
    fail "$phase: prompt_v2.meta existe" "arquivo ausente"
  fi
done

if grep -q 'shell-style' \
    "$REPO_ROOT/templates/prompts/track_creator/prompt_design/prompt_v2.md" 2>/dev/null; then
  pass "prompt_design/v2: FAIL_CONDITIONS contem proibicao de shell-style"
else
  fail "prompt_design/v2: FAIL_CONDITIONS contem proibicao de shell-style" \
    "keyword 'shell-style' nao encontrada"
fi

if grep -q 'Gate WRITE_SCOPE' \
    "$REPO_ROOT/templates/prompts/track_creator/prompt_design/prompt_v2.md" 2>/dev/null; then
  pass "prompt_design/v2: contem gate WRITE_SCOPE-handoff"
else
  fail "prompt_design/v2: contem gate WRITE_SCOPE-handoff" \
    "keyword 'Gate WRITE_SCOPE' nao encontrada"
fi

if grep -q 'Gate OBJECTIVE' \
    "$REPO_ROOT/templates/prompts/track_creator/prompt_design/prompt_v2.md" 2>/dev/null; then
  pass "prompt_design/v2: contem gate OBJECTIVE-OUTPUT_STRUCTURE"
else
  fail "prompt_design/v2: contem gate OBJECTIVE-OUTPUT_STRUCTURE" \
    "keyword 'Gate OBJECTIVE' nao encontrada"
fi

if grep -q 'shell-style' \
    "$REPO_ROOT/templates/prompts/track_creator/implementation_executor/prompt_v2.md" 2>/dev/null; then
  pass "implementation_executor/v2: FAIL_CONDITIONS contem proibicao de shell-style"
else
  fail "implementation_executor/v2: FAIL_CONDITIONS contem proibicao de shell-style" \
    "keyword 'shell-style' nao encontrada"
fi

if grep -q 'TEMP-VAL' \
    "$REPO_ROOT/templates/prompts/track_creator/validation/prompt_v2.md" 2>/dev/null; then
  pass "validation/v2: contem gate de renderizacao real (TEMP-VAL)"
else
  fail "validation/v2: contem gate de renderizacao real (TEMP-VAL)" \
    "keyword 'TEMP-VAL' nao encontrada"
fi

if grep -q 'Gate WRITE_SCOPE' \
    "$REPO_ROOT/templates/prompts/track_creator/validation/prompt_v2.md" 2>/dev/null; then
  pass "validation/v2: contem gate WRITE_SCOPE vs FAIL_CONDITIONS"
else
  fail "validation/v2: contem gate WRITE_SCOPE vs FAIL_CONDITIONS" \
    "keyword 'Gate WRITE_SCOPE' nao encontrada"
fi

if grep -q 'shell-style' \
    "$REPO_ROOT/skills/EAW_prompt_creator/SKILL.md" 2>/dev/null; then
  pass "EAW_prompt_creator/SKILL.md: contem invariante de placeholder shell-style"
else
  fail "EAW_prompt_creator/SKILL.md: contem invariante de placeholder shell-style" \
    "keyword 'shell-style' nao encontrada"
fi

if grep -q 'shell-style' \
    "$REPO_ROOT/skills/EAW_track_creator/SKILL.md" 2>/dev/null; then
  pass "EAW_track_creator/SKILL.md: contem invariante de placeholder shell-style"
else
  fail "EAW_track_creator/SKILL.md: contem invariante de placeholder shell-style" \
    "keyword 'shell-style' nao encontrada"
fi

echo ""
echo "Results: PASS=$PASS FAIL=$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
