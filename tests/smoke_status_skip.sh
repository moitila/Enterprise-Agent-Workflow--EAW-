#!/usr/bin/env bash
# smoke_status_skip.sh — Testa o comportamento de eaw status para fases puladas via skip_when.
# Cobre: CA-01 (skip válido), CA-02 (non-regressão sem skip), CA-03 (envelope ausente), CA-04 (phase_id errada).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() { printf "smoke_status_skip FAIL: %s\n" "$1" >&2; exit 1; }
pass() { printf "PASS: %s\n" "$1"; }

TMPDIR_SMOKE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_SMOKE"' EXIT

EAW_WORKDIR="$TMPDIR_SMOKE"
export EAW_WORKDIR

# Inicializar workdir mínimo
"$REPO_ROOT/scripts/eaw" init --workdir "$TMPDIR_SMOKE" --force >/dev/null 2>&1

OUTDIR="$TMPDIR_SMOKE/out"

# ─── Helpers ────────────────────────────────────────────────────────────────

make_card() {
	local card="$1"
	local track="$2"
	local phase="$3"
	local phase_status="${4:-COMPLETE}"
	local phase_completed="${5:-true}"
	local out="$OUTDIR/$card"
	mkdir -p "$out/investigations"

	# State file (formato canônico)
	# previous_phase e completed_phases usam detect_drift — única fase prévia válida
	# na track repo_onboarding_refresh quando current_phase é patch_onboarding
	cat >"$out/state_card_${track}.yaml" <<EOF
config_version: 1

card_state:
  card_id: CARD_${card}
  track_id: ${track}
  current_phase: ${phase}
  phase_started_at: 2026-01-01T00:00:00Z
  phase_completed: ${phase_completed}
  phase_completed_at: 2026-01-01T00:01:00Z
  previous_phase: detect_drift
  phase_status: ${phase_status}
  completed_phases:
    - detect_drift
  created_at: "2026-01-01"
  updated_at: "2026-01-01"
EOF

	# Journal mínimo
	printf '{"card_id":"%s","track":"%s","phase":"%s","timestamp":"2026-01-01T00:01:00Z","agent":"runtime","mode":"phase_driven","status":"OK","duration_ms":0,"event_type":"track_completed"}\n' \
		"$card" "$track" "$phase" >"$out/execution_journal.jsonl"
}

make_phase_yaml() {
	local card="$1"
	local phase="$2"
	local artifact="${3:-investigations/report.md}"
	local track_dir="$TMPDIR_SMOKE/tracks/${card}_track"
	mkdir -p "$track_dir/phases"
	local phase_file="$track_dir/phases/${phase}.yaml"
	cat >"$phase_file" <<EOF
config_version: 1

phase:
  id: ${phase}
  name: Test Phase

  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - path: ${artifact}
        min_bytes: 1
        validation_mode: blocking
EOF
	echo "$phase_file"
}

link_track() {
	local card="$1"
	local phase="$2"
	local phase_file="$3"
	# Copy phase yaml into the track location that eaw_load_card_workflow_context expects
	local intake_dir="$OUTDIR/$card/intake"
	mkdir -p "$intake_dir"
	# eaw uses EAW_WORKDIR/tracks/<track_id>/phases/<phase>.yaml
	# We already set it up in make_phase_yaml under tmp tracks dir; copy there properly
	local track_id
	track_id="$(basename "$(dirname "$(dirname "$phase_file")")")"
	local dest_dir="$TMPDIR_SMOKE/tracks/$track_id/phases"
	mkdir -p "$dest_dir"
	cp "$phase_file" "$dest_dir/${phase}.yaml" 2>/dev/null || true
}

run_status() {
	local card="$1"
	EAW_WORKDIR="$TMPDIR_SMOKE" bash "$REPO_ROOT/scripts/eaw" status "$card" 2>&1
}

# ─── Cenário 1 — Fase pulada com envelope válido (CA-01) ────────────────────
# Dado: 10_phase_output.json com status=skipped e phase_id correspondente
# Esperado: pending_required_artifacts: - none  |  skipped_phase_artifacts: lista o artefato

C1_CARD="C1_SKIP_VALID"
C1_TRACK="repo_onboarding_refresh"
C1_PHASE="patch_onboarding"

# Usar a track real do repo que já tem a phase YAML
make_card "$C1_CARD" "$C1_TRACK" "$C1_PHASE"

# Envelope oficial de skip
cat >"$OUTDIR/$C1_CARD/investigations/10_phase_output.json" <<'EOF'
{"phase_id":"patch_onboarding","status":"skipped","summary":"Phase skipped by skip_when rule","skip_reason_code":"NO_DRIFT_DETECTED"}
EOF

output1="$(run_status "$C1_CARD")"

echo "$output1" | grep -q '^pending_required_artifacts:' \
	|| fail "C1: cabeçalho pending_required_artifacts ausente"

echo "$output1" | grep -A1 '^pending_required_artifacts:' | grep -q '^\s*-\s*none$' \
	|| fail "C1: pending_required_artifacts não é 'none' — artefato de skip relatado como bloqueante"

echo "$output1" | grep -q '^skipped_phase_artifacts:' \
	|| fail "C1: seção skipped_phase_artifacts ausente"

echo "$output1" | grep -A2 '^skipped_phase_artifacts:' | grep -q 'patch_notes.md' \
	|| fail "C1: investigations/patch_notes.md não aparece em skipped_phase_artifacts"

pass "C1 — Skip válido: pending_required_artifacts=none, skipped_phase_artifacts lista artefato"

# ─── Cenário 2 — Card sem skip_when, artefato genuinamente faltante (CA-02) ─
# Dado: sem 10_phase_output.json, artefato ausente
# Esperado: pending_required_artifacts lista o artefato  |  sem skipped_phase_artifacts

C2_CARD="C2_NO_SKIP"
C2_TRACK="repo_onboarding_refresh"
C2_PHASE="patch_onboarding"

make_card "$C2_CARD" "$C2_TRACK" "$C2_PHASE" "IN_PROGRESS" "false"
# sem 10_phase_output.json

output2="$(run_status "$C2_CARD")"

echo "$output2" | grep -q '^pending_required_artifacts:' \
	|| fail "C2: cabeçalho pending_required_artifacts ausente"

echo "$output2" | grep -A2 '^pending_required_artifacts:' | grep -q 'patch_notes.md' \
	|| fail "C2: artefato genuinamente faltante não aparece em pending_required_artifacts"

if echo "$output2" | grep -q '^skipped_phase_artifacts:'; then
	fail "C2: skipped_phase_artifacts presente quando não deveria existir"
fi

pass "C2 — Sem skip: pending_required_artifacts lista artefato bloqueante (non-regressão)"

# ─── Cenário 3 — Envelope ausente: fallback para comportamento atual (CA-03) ─
# Dado: 10_phase_output.json ausente (arquivo não existe)
# Esperado: comportamento conservador — artefato relatado como pending

C3_CARD="C3_NO_ENVELOPE"
C3_TRACK="repo_onboarding_refresh"
C3_PHASE="patch_onboarding"

make_card "$C3_CARD" "$C3_TRACK" "$C3_PHASE"
# Sem 10_phase_output.json

output3="$(run_status "$C3_CARD")"

echo "$output3" | grep -A2 '^pending_required_artifacts:' | grep -q 'patch_notes.md' \
	|| fail "C3: artefato não relatado como pending quando envelope está ausente"

if echo "$output3" | grep -q '^skipped_phase_artifacts:'; then
	fail "C3: skipped_phase_artifacts gerado com envelope ausente"
fi

pass "C3 — Envelope ausente: fallback conservador, artefato em pending_required_artifacts"

# ─── Cenário 4 — Envelope com phase_id errado: fallback (CA-03 variante) ────
# Dado: 10_phase_output.json com status=skipped mas phase_id diferente da fase atual
# Esperado: comportamento conservador — artefato como pending (envelope pertence a outra fase)

C4_CARD="C4_WRONG_PHASE_ID"
C4_TRACK="repo_onboarding_refresh"
C4_PHASE="patch_onboarding"

make_card "$C4_CARD" "$C4_TRACK" "$C4_PHASE"

# Envelope com phase_id divergente
cat >"$OUTDIR/$C4_CARD/investigations/10_phase_output.json" <<'EOF'
{"phase_id":"detect_drift","status":"skipped","summary":"Phase skipped by skip_when rule","skip_reason_code":"NO_DRIFT_DETECTED"}
EOF

output4="$(run_status "$C4_CARD")"

echo "$output4" | grep -A2 '^pending_required_artifacts:' | grep -q 'patch_notes.md' \
	|| fail "C4: artefato não relatado como pending com phase_id divergente"

if echo "$output4" | grep -q '^skipped_phase_artifacts:'; then
	fail "C4: skipped_phase_artifacts gerado com phase_id errado no envelope"
fi

pass "C4 — Envelope com phase_id errado: fallback conservador"

# ─── Cenário 5 — Envelope inválido (JSON malformado): fallback (CA-03 variante) ─
C5_CARD="C5_INVALID_ENVELOPE"
C5_TRACK="repo_onboarding_refresh"
C5_PHASE="patch_onboarding"

make_card "$C5_CARD" "$C5_TRACK" "$C5_PHASE"

# JSON malformado
printf 'NOT_VALID_JSON' >"$OUTDIR/$C5_CARD/investigations/10_phase_output.json"

output5="$(run_status "$C5_CARD")"

echo "$output5" | grep -A2 '^pending_required_artifacts:' | grep -q 'patch_notes.md' \
	|| fail "C5: artefato não relatado como pending com envelope malformado"

if echo "$output5" | grep -q '^skipped_phase_artifacts:'; then
	fail "C5: skipped_phase_artifacts gerado com envelope malformado"
fi

pass "C5 — Envelope malformado: fallback conservador"

# ─── Cenário 6 — Card COMPLETE com todos os artefatos presentes (CA-02 variante) ─
# Dado: card com phase_status COMPLETE, artefatos presentes, sem skip
# Esperado: pending_required_artifacts: - none  |  sem skipped_phase_artifacts

C6_CARD="C6_COMPLETE_NORMAL"
C6_TRACK="repo_onboarding_refresh"
C6_PHASE="patch_onboarding"

make_card "$C6_CARD" "$C6_TRACK" "$C6_PHASE"

# Criar o artefato obrigatório
mkdir -p "$OUTDIR/$C6_CARD/investigations"
printf 'patch notes conteudo real com mais de um byte\n' >"$OUTDIR/$C6_CARD/investigations/patch_notes.md"

output6="$(run_status "$C6_CARD")"

echo "$output6" | grep -A1 '^pending_required_artifacts:' | grep -q '^\s*-\s*none$' \
	|| fail "C6: pending_required_artifacts não é 'none' com artefatos presentes"

if echo "$output6" | grep -q '^skipped_phase_artifacts:'; then
	fail "C6: skipped_phase_artifacts presente em card normal completo"
fi

pass "C6 — Card normal completo: pending=none, sem skipped_phase_artifacts"

printf "\nsmoke_status_skip.sh: ALL PASSED\n"
