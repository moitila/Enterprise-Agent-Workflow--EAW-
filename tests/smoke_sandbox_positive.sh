#!/usr/bin/env bash
# Testes CA-1, CA-2 e CA-5 para assert_write_scope com sandbox (execution.local_sandbox)
# TC-1 = CA-1: sandbox do card corrente e permitido quando declarado como allowed path
# TC-2 = CA-5: sem sandbox na allowlist, caminho fora do card e bloqueado
# TC-3 = CA-2: sandbox de outro card e bloqueado (isolamento por CARD_ID)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/lib.sh
source "$SCRIPT_DIR/../scripts/lib.sh"

CARD_DIR="/home/user/dev/.eaw/out/backlog_spike_03"
SANDBOX="${TMPDIR:-/tmp}/EAW-backlog_spike_03"
CROSS="${TMPDIR:-/tmp}/EAW-outro_card"

# TC-1 / CA-1: sandbox path do card corrente e aceito quando passado como allowed path
assert_write_scope "findings" "ca1" "$SANDBOX/exp.sql" "$CARD_DIR" "$SANDBOX"
echo "PASS: TC-1 (CA-1) — sandbox legitimo aceito"

# TC-2 / CA-5: sem sandbox path na allowlist, caminho absoluto fora do card e bloqueado
_ret=0
assert_write_scope "findings" "ca5" "$SANDBOX/no_sandbox.sql" "$CARD_DIR" 2>/dev/null || _ret=$?
[[ "$_ret" -eq 97 ]] || { echo "FAIL: TC-2 (CA-5) sandbox sem declaracao nao foi bloqueado (esperado 97, got $_ret)"; exit 1; }
echo "PASS: TC-2 (CA-5) — sandbox sem declaracao bloqueado"

# TC-3 / CA-2: sandbox de outro card nao e aceito; isolamento por CARD_ID funciona
_ret=0
assert_write_scope "findings" "ca2" "$CROSS/exp.sql" "$CARD_DIR" "$SANDBOX" 2>/dev/null || _ret=$?
[[ "$_ret" -eq 97 ]] || { echo "FAIL: TC-3 (CA-2) sandbox de outro card nao foi bloqueado (esperado 97, got $_ret)"; exit 1; }
echo "PASS: TC-3 (CA-2) — sandbox de outro card bloqueado"

echo "PASS: smoke_sandbox_positive — TC-1, TC-2, TC-3 OK"
