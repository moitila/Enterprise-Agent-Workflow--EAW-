#!/usr/bin/env bash
# backfill_ci_feedback_prompt.sh
# Re-renderiza ci_feedback_prompt.md para cards stale (card_init ou init hardcoded).
# Uso: EAW_WORKDIR=/home/user/dev/.eaw EAW_ROOT_DIR=/home/user/dev/eaw ./scripts/tools/backfill_ci_feedback_prompt.sh
set -euo pipefail
EAW_ROOT_DIR="${EAW_ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
EAW_WORKDIR="${EAW_WORKDIR:?EAW_WORKDIR nao definido}"
TMPL="${EAW_ROOT_DIR}/templates/ci_feedback/feedback_prompt_v1.md"
[[ -f "$TMPL" ]] || { echo "ERROR: template nao encontrado: $TMPL" >&2; exit 1; }

processed=0
skipped=0
for card_dir in "${EAW_WORKDIR}/out/"/*/; do
    ci_prompt="${card_dir}prompts/ci_feedback_prompt.md"
    [[ -f "$ci_prompt" ]] || continue
    grep -qE "/ card_init\b|/ init\b" "$ci_prompt" || continue
    state_file=$(ls "${card_dir}"state_card_*.yaml 2>/dev/null | head -1)
    if [[ -z "$state_file" || ! -f "$state_file" ]]; then
        echo "SKIP (no state file): $card_dir" >&2
        (( skipped++ )) || true; continue
    fi
    current_phase=$(grep "current_phase:" "$state_file" | awk '{print $2}' || true)
    track_id=$(grep "track_id:" "$state_file" | awk '{print $2}' || true)
    card=$(grep "card_id:" "$state_file" | awk '{print $2}' | sed 's/^CARD_//' || true)
    if [[ -z "$current_phase" || -z "$track_id" || -z "$card" ]]; then
        echo "SKIP (missing fields): $card_dir" >&2
        (( skipped++ )) || true; continue
    fi
    sed \
        -e "s|{{CARD}}|${card}|g" \
        -e "s|{{TRACK}}|${track_id}|g" \
        -e "s|{{PHASE}}|${current_phase}|g" \
        -e "s|{{EAW_WORKDIR}}|${EAW_WORKDIR}|g" \
        "$TMPL" > "$ci_prompt"
    echo "BACKFILL OK: card=${card} phase=${current_phase}"
    (( processed++ )) || true
done
echo "SUMMARY: processed=${processed} skipped=${skipped}"
