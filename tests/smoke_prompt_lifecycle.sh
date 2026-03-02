#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

export EAW_WORKDIR="$WORK_ROOT/.eaw"

"$ROOT_DIR/scripts/eaw" init --workdir "$EAW_WORKDIR" >/dev/null

PROMPT_DIR="$EAW_WORKDIR/templates/prompts/pt-br/intake"
mkdir -p "$PROMPT_DIR"

cat >"$PROMPT_DIR/prompt_v1.md" <<'EOF'
PROMPT HEADER
MANDATORY CHECK
EOF

cat >"$PROMPT_DIR/prompt_v1.meta" <<'EOF'
version=v1
required_substrings=PROMPT HEADER|MANDATORY CHECK
forbidden_words=BLOCKED TOKEN
EOF

cat >"$PROMPT_DIR/prompt_v2.md" <<'EOF'
PROMPT HEADER
BLOCKED TOKEN
EOF

cat >"$PROMPT_DIR/prompt_v2.meta" <<'EOF'
version=v2
required_substrings=PROMPT HEADER|MANDATORY CHECK
forbidden_words=BLOCKED TOKEN
EOF

printf "v0\n" >"$PROMPT_DIR/ACTIVE"

before_non_active="$(cksum "$PROMPT_DIR/prompt_v1.md" "$PROMPT_DIR/prompt_v1.meta" "$PROMPT_DIR/prompt_v2.md" "$PROMPT_DIR/prompt_v2.meta")"

set +e
"$ROOT_DIR/scripts/eaw" apply-prompt pt-br missing-phase v1 >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
	echo "expected apply-prompt missing-phase to fail" >&2
	exit 1
fi
if [[ -e "$EAW_WORKDIR/templates/prompts/pt-br/missing-phase/ACTIVE" ]]; then
	echo "ACTIVE should not be created for missing prompt phase directory" >&2
	exit 1
fi

"$ROOT_DIR/scripts/eaw" validate-prompt pt-br intake v1 >/dev/null

set +e
"$ROOT_DIR/scripts/eaw" validate-prompt pt-br intake v2 >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 0 ]]; then
	echo "expected validate-prompt v2 to fail" >&2
	exit 1
fi

"$ROOT_DIR/scripts/eaw" apply-prompt pt-br intake v1 >/dev/null

if [[ "$(cat "$PROMPT_DIR/ACTIVE")" != "v1" ]]; then
	echo "ACTIVE was not updated to v1" >&2
	exit 1
fi

after_non_active="$(cksum "$PROMPT_DIR/prompt_v1.md" "$PROMPT_DIR/prompt_v1.meta" "$PROMPT_DIR/prompt_v2.md" "$PROMPT_DIR/prompt_v2.meta")"
if [[ "$before_non_active" != "$after_non_active" ]]; then
	echo "non-ACTIVE prompt artifacts changed" >&2
	exit 1
fi

"$ROOT_DIR/scripts/eaw" feature 500 "Prompt lifecycle smoke" >/dev/null
"$ROOT_DIR/scripts/eaw" doctor >/dev/null
"$ROOT_DIR/scripts/eaw" validate >/dev/null
"$ROOT_DIR/scripts/eaw" intake 500 --round=1 >/dev/null
"$ROOT_DIR/scripts/eaw" analyze 500 >/dev/null

test -f "$EAW_WORKDIR/out/500/investigations/intake_agent_prompt.round_1.md"
test -f "$EAW_WORKDIR/out/500/investigations/findings_agent_prompt.md"
