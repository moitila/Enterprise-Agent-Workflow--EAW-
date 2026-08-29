#!/usr/bin/env bash
# Smoke test: feedback_review track structure integrity
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TRACK_DIR="${ROOT_DIR}/tracks/feedback_review"
TEMPLATES_DIR="${ROOT_DIR}/templates/prompts/feedback_review"
FIXTURES_DIR="${ROOT_DIR}/tests/fixtures/feedback_review"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "PASS: $1"; }

# 1. Track YAML exists and has required fields
test -f "${TRACK_DIR}/track.yaml" || fail "track.yaml missing"
grep -q "id: feedback_review" "${TRACK_DIR}/track.yaml" || fail "track id missing"
grep -q "initial_phase: corpus_freeze" "${TRACK_DIR}/track.yaml" || fail "initial_phase wrong"
grep -q "final_phase: backlog_finalization" "${TRACK_DIR}/track.yaml" || fail "final_phase wrong"
pass "track.yaml structure"

# 2. All 6 phase YAMLs exist
for phase in corpus_freeze case_reconstruction findings phase_alignment diagnosis backlog_finalization; do
  test -f "${TRACK_DIR}/phases/${phase}.yaml" || fail "phase YAML missing: ${phase}"
done
pass "all 6 phase YAMLs exist"

# 3. findings and diagnosis declare eaw_reviewer
grep -q "eaw_reviewer" "${TRACK_DIR}/phases/findings.yaml" || fail "findings missing eaw_reviewer"
grep -q "eaw_reviewer" "${TRACK_DIR}/phases/diagnosis.yaml" || fail "diagnosis missing eaw_reviewer"
pass "eaw_reviewer declared in findings and diagnosis"

# 4. corpus_freeze, case_reconstruction, phase_alignment, backlog_finalization have no skills block
# (or empty skills block — absence is acceptable)
! grep -q "eaw_reviewer" "${TRACK_DIR}/phases/corpus_freeze.yaml" || fail "corpus_freeze should not declare eaw_reviewer"
! grep -q "eaw_reviewer" "${TRACK_DIR}/phases/phase_alignment.yaml" || fail "phase_alignment should not declare eaw_reviewer"
pass "correct phases do not declare eaw_reviewer"

# 5. All prompt templates exist and contain required substrings
for phase in corpus_freeze case_reconstruction findings phase_alignment diagnosis backlog_finalization; do
  test -f "${TEMPLATES_DIR}/${phase}/ACTIVE" || fail "ACTIVE missing: ${phase}"
  test -f "${TEMPLATES_DIR}/${phase}/prompt_v1.md" || fail "prompt_v1.md missing: ${phase}"
  test -f "${TEMPLATES_DIR}/${phase}/prompt_v1.meta" || fail "prompt_v1.meta missing: ${phase}"
  grep -q "ROLE" "${TEMPLATES_DIR}/${phase}/prompt_v1.md" || fail "prompt_v1.md missing ROLE: ${phase}"
  grep -q "OBJECTIVE" "${TEMPLATES_DIR}/${phase}/prompt_v1.md" || fail "prompt_v1.md missing OBJECTIVE: ${phase}"
done
pass "all prompt templates present with required sections"

# 6. Track registered in tracks.yaml
grep -q "feedback_review" "${ROOT_DIR}/tracks/tracks.yaml" || fail "feedback_review not in tracks.yaml"
pass "feedback_review registered"

# 7. Intake template exists
test -f "${ROOT_DIR}/templates/intake_feedback_review.md" || fail "intake template missing"
pass "intake template exists"

# 8. All 16 fixture directories present
for i in 01_valid_confirmed 02_contradicted 03_partial_confirmed 04_missing_feedback \
          05_feedback_disabled 06_incomplete_corpus 07_same_count_diff_ids \
          08_two_feedbacks_same_phase 09_misaligned_handoff 10_divergent_prompt \
          11_valid_append 12_idempotent_append 13_interrupted 14_backlog_by_class \
          15_agent_bundle 16_simple_case; do
  test -d "${FIXTURES_DIR}/${i}" || fail "fixture dir missing: ${i}"
done
pass "all 16 fixture directories exist"

# 9. Canonical {{CARD_DIR}} placeholders in read_sources are expected; verify they are present
# and that no unresolved {{PLACEHOLDER}} appears in id/name/description/path fields
for phase in corpus_freeze case_reconstruction findings phase_alignment diagnosis backlog_finalization; do
  yaml="${TRACK_DIR}/phases/${phase}.yaml"
  # id and name must not contain double-curly placeholders
  if grep -E '^\s+(id|name|description):\s.*\{\{' "${yaml}" 2>/dev/null; then
    fail "unexpected double-curly placeholder in id/name/description field: ${phase}.yaml"
  fi
done
pass "phase YAML id/name/description fields free of unresolved placeholders"

# 10. Documentation exists
test -f "${ROOT_DIR}/docs/feedback_review.md" || fail "docs/feedback_review.md missing"
pass "documentation exists"

echo ""
echo "ALL SMOKE TESTS PASSED — feedback_review track structure OK"
