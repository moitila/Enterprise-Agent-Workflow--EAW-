# Corpus Manifest Fragment — Fixture 07

Demonstra falha de reconciliacao por contagem apenas.

EXPECTED_EXECUTION_IDS: [EXEC-A, EXEC-B, EXEC-C]  -> total: 3
DISCOVERED_FEEDBACK_IDS: [EXEC-A, EXEC-B, EXEC-D] -> total: 3

Contagens iguais (3 == 3), mas EXEC-C esta ausente e EXEC-D e inesperado.
O agente deve detectar a divergencia de identidade, nao aceitar a igualdade de total.

MISSING_FEEDBACK_EXECUTION_IDS: [EXEC-C]
IDs descobertos fora do esperado: [EXEC-D] (registrar como divergencia)
