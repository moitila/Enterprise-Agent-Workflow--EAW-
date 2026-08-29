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

# BL-15: lint deve rejeitar HTML comment com exit 1
# shellcheck source=/dev/null
source scripts/commands/eaw_commands.sh
_f="$(mktemp)"; echo '<!-- residual comment -->' >"$_f"
eaw_lint_rendered_prompt "$_f" >/dev/null 2>&1 \
    && fail "lint_should_fail_on_html_comment" \
    || pass "lint_fails_on_html_comment"
rm -f "$_f"

# BL-16: lint deve rejeitar CONTEXT_BLOCK em dollar-brace com exit 1
_f2="$(mktemp)"; printf '${CONTEXT_BLOCK}\n' >"$_f2"
eaw_lint_rendered_prompt "$_f2" >/dev/null 2>&1 \
    && fail "lint_should_fail_on_dollar_CONTEXT_BLOCK" \
    || pass "lint_fails_on_dollar_CONTEXT_BLOCK"
rm -f "$_f2"

# BL-16: lint NAO deve rejeitar ${PATH} (nao e token operacional EAW canonico)
_f3="$(mktemp)"; printf '${PATH}\n' >"$_f3"
eaw_lint_rendered_prompt "$_f3" >/dev/null 2>&1 \
    && pass "lint_no_false_positive_PATH" \
    || fail "lint_false_positive_on_PATH"
rm -f "$_f3"

# BL-18: prompt_v7.md deve existir
[[ -f "templates/prompts/bug_ONBOARD/implementation_planning/prompt_v7.md" ]] \
    && pass "impl_planning_v7_exists" \
    || fail "impl_planning_prompt_v7_not_found"
# BL-18: ACTIVE deve apontar para v7
active_ip="$(cat "templates/prompts/bug_ONBOARD/implementation_planning/ACTIVE")"
[[ "$active_ip" == "v7" ]] \
    && pass "impl_planning_ACTIVE=v7" \
    || fail "impl_planning_ACTIVE expected=v7 got=${active_ip}"
# BL-18: prompt_v7.md nao deve ter instrucao autorreferente na secao VALIDACOES FINAIS
grep -qE 'contenham placeholders literais.*\{\{CARD\}\}' \
    "templates/prompts/bug_ONBOARD/implementation_planning/prompt_v7.md" \
    && fail "prompt_v7_still_has_autorreferential_tokens" \
    || pass "prompt_v7_no_autorreferential_tokens"

# BL-INTAKE: scaffold deve ter secao Sintoma observado
grep -q '## Sintoma observado' scripts/commands/eaw_commands.sh \
    && pass "intake_scaffold_has_sintoma_observado" \
    || fail "intake_scaffold_missing_sintoma_observado"
# BL-INTAKE: scaffold deve ter pelo menos 5 secoes estruturadas
section_count="$(awk '
    /BL-CI-11/{in_block=1; next}
    in_block && /fi/{exit}
    in_block && /^[[:space:]]*printf.*## /{count++}
    END{print count+0}
' scripts/commands/eaw_commands.sh)"
[[ "$section_count" -ge 5 ]] \
    && pass "intake_scaffold_sections>=${section_count}" \
    || fail "intake_scaffold_sections expected>=5 got=${section_count}"

# BL-CI-16-EXT: bloco BL-CI-16 bug_ONBOARD-especifico deve estar ausente apos extensao generica
grep -q 'BL-CI-16: for bug_ONBOARD track' scripts/commands/eaw_commands.sh \
    && fail "BL-CI-16-EXT: comentario BL-CI-16 bug_ONBOARD-especifico ainda presente" \
    || pass "BL-CI-16-EXT_guard_removed"

# BL-CI-16-EXT: fallback para raw_card_explication.md deve estar presente
grep -q 'raw_card_explication' scripts/commands/eaw_commands.sh \
    && pass "BL-CI-16-EXT_fallback_raw_card_explication_present" \
    || fail "BL-CI-16-EXT: fallback raw_card_explication ausente em eaw_commands.sh"

# D3: verificacao de existencia do diretorio de onboarding deve estar presente
grep -qE 'context_sources/onboarding.*resolved_repo_key|resolved_repo_key.*context_sources/onboarding' scripts/commands/eaw_commands.sh \
    && pass "D3_onboarding_dir_check_present" \
    || fail "D3: verificacao de existencia do diretorio de onboarding ausente"

# syntax check for all modified shell files
bash -n scripts/commands/eaw_commands.sh && pass "eaw_commands_syntax_ok" || fail "eaw_commands.sh syntax error"
bash -n scripts/lib/phase_completion.sh  && pass "phase_completion_syntax_ok" || fail "phase_completion.sh syntax error"
bash -n tests/invariants.sh              && pass "invariants_syntax_ok" || fail "invariants.sh syntax error"

if [[ "$errors" -gt 0 ]]; then
    echo "smoke_bug_ONBOARD FAILED: errors=${errors}" >&2
    exit 1
fi
echo "smoke_bug_ONBOARD OK"
