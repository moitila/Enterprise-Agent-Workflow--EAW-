Voce e o agente do VSCode atuando na fase Planning do card {{CARD}} ({{TYPE}}).

- Nao alterar codigo.
- Nao commitar.
- Escrita permitida somente em:
  - $CARD_DIR/investigations/40_next_steps.md
  - $CARD_DIR/investigations/_warnings.md (se necessario)
Qualquer tentativa de escrita fora da whitelist -> abortar imediatamente.

cd "$EAW_ROOT_DIR"
test -f ./scripts/eaw || { echo "ERROR: not in EAW runtime root (missing ./scripts/eaw)"; exit 2; }
test -f "$CONFIG_SOURCE" || { echo "ERROR: missing config source $CONFIG_SOURCE"; exit 2; }

────────────────────────────────────
PRÉ-CONDIÇÕES HARD
────────────────────────────────────

Confirmar existência de:

- 00_intake.md
- 20_findings.md
- 30_hypotheses.md

Se qualquer um estiver ausente -> BLOQUEAR.

────────────────────────────────────
OBJETIVO
────────────────────────────────────

Gerar 40_next_steps.md transformando hipóteses formais em plano executável mínimo.

NÃO criar hipótese nova.
NÃO alterar findings.
NÃO propor arquitetura nova.

────────────────────────────────────
ESTRUTURA OBRIGATÓRIA DE 40_next_steps.md
────────────────────────────────────

# 40_next_steps

## Hipótese(s) Selecionada(s)
(Listar explicitamente H# extraídas de 30_hypotheses.md)

Exemplo:
- H2
- H5

Seção obrigatória.  
Se não houver H# explícita → FAIL.

## Objetivo da Iteração
Resumo técnico claro.

## Estratégia
Escopo e fora de escopo.

## Plano Atômico
1.
2.
3.

Cada passo deve ser:
- Determinístico
- Executável
- Reversível quando aplicável

## Critérios de Aceite
- Comandos verificáveis
- Exit codes esperados
- Artefatos esperados
- Prefixos textuais se aplicável

## Riscos e Mitigação
Risco residual por H# selecionada.

## Rollback
Procedimento mínimo de reversão.

────────────────────────────────────
VALIDAÇÃO FINAL
────────────────────────────────────

- Confirmar presença de seção "Hipótese(s) Selecionada(s)"
- Confirmar presença de pelo menos uma H#
- Confirmar plano numerado
- Confirmar critérios verificáveis

test -f "$CARD_DIR/investigations/40_next_steps.md" || { echo "ERROR: missing next_steps"; exit 2; }

RETORNO OBRIGATÓRIO:

- Lista de H# selecionadas
- Confirmacao de escrita unica
- Saida literal dos testes
