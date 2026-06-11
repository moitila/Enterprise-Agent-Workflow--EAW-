#!/usr/bin/env bash
# smoke_complete_cmd.sh — Smoke test para eaw_generate_followup_candidates()
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck disable=SC1090
source "$REPO_ROOT/scripts/commands/eaw_commands.sh"

TMPDIR_SMOKE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SMOKE"' EXIT

# Cenário A: scope.lock com bullets → arquivo gerado com ## Candidate 1
CARD_A="$TMPDIR_SMOKE/card_a"
mkdir -p "$CARD_A/implementation"
cat > "$CARD_A/implementation/00_scope.lock.md" << 'EOF'
# Scope Lock - Card SMOKE

## Out of Scope

- Candidato smoke A
- Candidato smoke B
EOF

eaw_generate_followup_candidates "$CARD_A"
if [[ ! -f "$CARD_A/_followup_candidates.md" ]]; then
	echo "FAIL: Cenário A - arquivo não gerado" >&2
	exit 1
fi
if ! grep -q "## Candidate 1" "$CARD_A/_followup_candidates.md"; then
	echo "FAIL: Cenário A - ## Candidate 1 ausente" >&2
	exit 1
fi
echo "PASS: Cenário A"

# Cenário B: scope.lock ausente → nenhum arquivo gerado
CARD_B="$TMPDIR_SMOKE/card_b"
mkdir -p "$CARD_B"
eaw_generate_followup_candidates "$CARD_B"
if [[ -f "$CARD_B/_followup_candidates.md" ]]; then
	echo "FAIL: Cenário B - arquivo gerado quando não deveria" >&2
	exit 1
fi
echo "PASS: Cenário B"

echo "smoke_complete_cmd.sh: ALL PASSED"
