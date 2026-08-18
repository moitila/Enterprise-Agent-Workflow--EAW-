#!/usr/bin/env bash
# smoke_bug_ONBOARD.sh — Smoke de regressão para correções do card EAW-BUG-ONBOARD-SCAFFOLDS-GATES
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
errors=0

fail() { echo "FAIL: $*" >&2; (( errors++ )) || true; }
pass() { echo "OK: $*"; }

# BL-01: active: sincronizado para as 5 fases
for f in intake findings planning implementation_planning implementation_executor; do
    yaml_active="$(awk '/^[[:space:]]+active:/{print $2; exit}' "tracks/bug_ONBOARD/phases/${f}.yaml")"
    active_val="$(tr -d '[:space:]' <"templates/prompts/bug_ONBOARD/${f}/ACTIVE" | sed 's/^v//')"
    [[ "$yaml_active" == "$active_val" ]] \
        && pass "active:_sync $f (active=${yaml_active})" \
        || fail "active:_sync $f yaml=${yaml_active} ACTIVE=${active_val}"
done

# BL-02: scaffold inline de 00_scope.lock.md tem pelo menos 7 seções ##
# Contar ## headings dentro do heredoc do caso implementation/00_scope.lock.md em eaw_commands.sh
heading_count="$(awk '
    /implementation\/00_scope\.lock\.md\)/{in_case=1; next}
    in_case && /^[[:space:]]*;;/{exit}
    in_case && /^## /{count++}
    END{print count+0}
' scripts/commands/eaw_commands.sh)"
[[ "$heading_count" -ge 7 ]] \
    && pass "scaffold_00_scope_sections count=${heading_count}" \
    || fail "scaffold_00_scope_sections expected>=7 got=${heading_count}"

# BL-02: scaffold inline tem ## Allowlist de Escrita
has_allowlist="$(awk '
    /implementation\/00_scope\.lock\.md\)/{in_case=1; next}
    in_case && /^[[:space:]]*;;/{exit}
    in_case && /^## Allowlist de Escrita/{found=1; exit}
    END{print found+0}
' scripts/commands/eaw_commands.sh)"
[[ "$has_allowlist" -ge 1 ]] \
    && pass "scaffold_00_scope_has_allowlist" \
    || fail "scaffold_00_scope missing ## Allowlist de Escrita"

# BL-02: template intake usa <CARD> e não {{CARD}}
grep -q '<CARD>' templates/intake_bug_ONBOARD.md \
    && pass "intake_template_placeholder_CARD" \
    || fail "intake_bug_ONBOARD.md nao tem <CARD>"
grep -qE '\{\{CARD\}\}' templates/intake_bug_ONBOARD.md \
    && fail "intake_bug_ONBOARD.md ainda tem placeholder {{CARD}}" \
    || pass "intake_placeholder_no_double_brace"

# BL-02: template 20_findings.md tem exatamente 6 headings ##
hcount="$(grep -c '^## ' templates/20_findings.md 2>/dev/null || echo 0)"
[[ "$hcount" -eq 6 ]] \
    && pass "20_findings_headings=6" \
    || fail "20_findings_headings expected=6 got=${hcount}"

# BL-07: template change_plan tem Read-only e Pos-PR mas não Tecnica Obrigatoria
grep -q '## Validacao Read-only' templates/implementation_10_change_plan.md \
    && pass "change_plan_has_read-only" \
    || fail "change_plan missing ## Validacao Read-only"
grep -q '## Validacao Pos-PR' templates/implementation_10_change_plan.md \
    && pass "change_plan_has_pos-pr" \
    || fail "change_plan missing ## Validacao Pos-PR"
grep -q '## Validacao Tecnica Obrigatoria' templates/implementation_10_change_plan.md \
    && fail "change_plan still has ## Validacao Tecnica Obrigatoria" \
    || pass "change_plan_no_tecnica_obrigatoria"

# BL-07: ACTIVE do executor aponta para v6
active_executor="$(cat templates/prompts/bug_ONBOARD/implementation_executor/ACTIVE)"
[[ "$active_executor" == "v6" ]] \
    && pass "executor_ACTIVE=v6" \
    || fail "executor_ACTIVE expected=v6 got=${active_executor}"

# BL-07: prompt_v6.md existe e contém Validacao Read-only sem Validacao Tecnica Obrigatoria
[[ -f "templates/prompts/bug_ONBOARD/implementation_executor/prompt_v6.md" ]] \
    && pass "prompt_v6_exists" \
    || fail "prompt_v6.md not found"
grep -q 'Validacao Read-only' "templates/prompts/bug_ONBOARD/implementation_executor/prompt_v6.md" \
    && pass "prompt_v6_has_read-only" \
    || fail "prompt_v6.md missing Validacao Read-only"
grep -q 'Validacao Tecnica Obrigatoria' "templates/prompts/bug_ONBOARD/implementation_executor/prompt_v6.md" \
    && fail "prompt_v6.md still has Validacao Tecnica Obrigatoria" \
    || pass "prompt_v6_no_tecnica_obrigatoria"

# syntax check for all modified shell files
bash -n scripts/commands/eaw_commands.sh && pass "eaw_commands_syntax_ok" || fail "eaw_commands.sh syntax error"
bash -n scripts/lib/phase_completion.sh  && pass "phase_completion_syntax_ok" || fail "phase_completion.sh syntax error"
bash -n tests/invariants.sh              && pass "invariants_syntax_ok" || fail "invariants.sh syntax error"

if [[ "$errors" -gt 0 ]]; then
    echo "smoke_bug_ONBOARD FAILED: errors=${errors}" >&2
    exit 1
fi
echo "smoke_bug_ONBOARD OK"
