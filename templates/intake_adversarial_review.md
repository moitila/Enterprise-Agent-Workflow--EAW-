# Adversarial Review Intake - {{CARD}}

## Card Alvo (Target Card)

- ID do card alvo:
- Track do card alvo (quando conhecida):
- Localizacao esperada: {{OUT_DIR}}/<CARD_ALVO>

## Objetivo da Revisao Adversarial

Registrar a pergunta central verificavel sobre o card alvo (ex.: se as
conclusoes e o status final declarados sao sustentados pela evidencia
produzida).

## Motivacao

Registrar por que o card foi selecionado para revisao adversarial.

## Artefatos Conhecidos do Card Alvo

Listar, quando ja conhecidos, os artefatos existentes do card alvo
(ingest/intake, investigations, scope lock, change plan, patch notes,
state_card_*.yaml, execution_journal.jsonl, prompts, diff, testes), sem
inferir existencia nao comprovada.

## Restricoes Operacionais

- Nao alterar codigo, comitar ou dar push durante a revisao.
- Qualquer execucao real de tecnica adversarial exige allowlist explicita,
  rollback deterministico, baseline validado e evidencia preservavel.
- Nao criar automaticamente o card de remediacao recomendado.

## Lacunas Conhecidas

Registrar duvidas, evidencias ausentes ou contexto ainda nao comprovado
sobre o card alvo no momento da criacao do card.
