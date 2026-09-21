#!/usr/bin/env bash
set -euo pipefail

fail() {
	printf 'regression_adversarial_review_classification failed: %s\n' "$1" >&2
	exit 1
}

pass() {
	printf 'PASS: %s\n' "$1"
}

# Fixed raw-evidence fixture representing a known defect class already
# analyzed manually for the adversarial_review track (see
# investigations/00_intake.md of EAW-ADV-REVIEW-V1-HARDENING): oraculo
# invalido, teste na camada errada, lifecycle/state, causalidade, criterio
# funcional incompleto. This fixture exercises real classification of raw
# evidence by structural/keyword markers, distinct from
# smoke_adversarial_review.sh, which only pre-writes the already-correct
# verdict text and never classifies evidence.
FIXTURE_LAYER_MISMATCH="$(
	cat <<'EOF'
Claim: calcular_desconto_pedido foi corrigido e a suite de testes passou.
Evidencia: o unico teste automatizado que referencia esta mudanca chama
diretamente uma funcao auxiliar de formatacao de string e verifica apenas o
texto formatado exibido na tela; a funcao de negocio que decide o valor do
desconto nunca e chamada nem mockada no teste.
Camada exercida: apresentacao/formatacao.
Camada alvo da correcao declarada: regra de negocio de desconto.
EOF
)"

# Negative control: a generic completion note with no structural evidence
# must not be misclassified into any of the five known defect classes.
FIXTURE_NEUTRAL="$(
	cat <<'EOF'
Claim: card concluido sem pendencias.
Evidencia: nenhuma evidencia bruta fornecida para analise.
EOF
)"

# Structural/keyword classifier: assigns one of five known defect classes to
# a raw-evidence text block without depending on exact wording (checagem
# estrutural/palavra-chave, nao diff textual exato). Order matters: more
# specific structural markers are checked first so a fixture is not matched
# by more than one class.
classify_defect_class() {
	local evidence="$1"

	if grep -qiE 'camada exercida|camada alvo' <<<"$evidence" &&
		grep -qiE 'nunca e chamada|nunca e chamado|nao e chamada|nao e chamado' <<<"$evidence"; then
		printf 'teste na camada errada\n'
		return 0
	fi

	if grep -qiE 'completed_phases|current_phase|state_card' <<<"$evidence" &&
		grep -qiE 'nao inclui|ausente|inconsistente' <<<"$evidence"; then
		printf 'lifecycle/state\n'
		return 0
	fi

	if grep -qiE 'oraculo|valor esperado' <<<"$evidence" &&
		grep -qiE 'mesma (implementacao|funcao)' <<<"$evidence"; then
		printf 'oraculo invalido\n'
		return 0
	fi

	if grep -qiE 'causa raiz|causal' <<<"$evidence" &&
		grep -qiE 'sem relacao demonstrada|nao demonstra' <<<"$evidence"; then
		printf 'causalidade\n'
		return 0
	fi

	if grep -qiE 'criterio de aceite|criterios de aceite' <<<"$evidence" &&
		grep -qiE 'nao cobre|incompleto|parcial' <<<"$evidence"; then
		printf 'criterio funcional incompleto\n'
		return 0
	fi

	printf 'indeterminado\n'
	return 1
}

result_layer_mismatch="$(classify_defect_class "$FIXTURE_LAYER_MISMATCH")" ||
	fail 'classifier returned no class for FIXTURE_LAYER_MISMATCH'
[[ "$result_layer_mismatch" == 'teste na camada errada' ]] ||
	fail "expected 'teste na camada errada', got '$result_layer_mismatch'"
pass "fixture classified as: $result_layer_mismatch"

if result_neutral="$(classify_defect_class "$FIXTURE_NEUTRAL")"; then
	fail "expected no classification for FIXTURE_NEUTRAL, got '$result_neutral'"
fi
pass 'neutral fixture correctly yields no classification (indeterminado)'

printf '[regression] adversarial_review_classification OK\n'
