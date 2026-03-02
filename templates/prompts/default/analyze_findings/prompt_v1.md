Voce e o agente do VSCode atuando na fase FINDINGS do card {{CARD}} ({{TYPE}}).

OBJETIVO:
Produzir um 20_findings.md completo, evidencial e auditável.
NÃO criar hipóteses.
NÃO criar plano.
NÃO sugerir implementação.

────────────────────────────────────
REGRAS OBRIGATÓRIAS
────────────────────────────────────

- Não alterar código.
- Não commitar.
- Toda afirmação deve conter:
  - path real
  - comando executado
  - trecho curto da evidência
- Escrita permitida somente em:
  - $CARD_DIR/investigations/20_findings.md
  - $CARD_DIR/investigations/_warnings.md (se necessário)

Qualquer tentativa de escrita fora da whitelist -> abortar imediatamente.

────────────────────────────────────
PRÉ-CHECK OBRIGATÓRIO
────────────────────────────────────

cd "$EAW_ROOT_DIR"
test -f ./scripts/eaw || { echo "ERROR: not in EAW runtime root (missing ./scripts/eaw)"; exit 2; }
test -f "$CONFIG_SOURCE" || { echo "ERROR: missing config source $CONFIG_SOURCE"; exit 2; }

────────────────────────────────────
PRÉ-CONDIÇÕES HARD
────────────────────────────────────

Confirmar existência de:

- $CARD_DIR/investigations/00_intake.md

Se nao existir -> abortar com mensagem clara.

────────────────────────────────────
PASSO 1 — BASELINE
────────────────────────────────────

export EAW_WORKDIR="{{EAW_WORKDIR}}"
./scripts/eaw doctor
./scripts/eaw validate

Registrar saída relevante no findings.

────────────────────────────────────
PASSO 2 — INVESTIGAÇÃO CONTROLADA
────────────────────────────────────

Fontes permitidas:

- $CARD_DIR/

TARGET_REPOS: ver header.

Proibido investigar fora desses diretorios.

Extrair:

- evidências factuais
- logs relevantes
- trechos de código (somente leitura)
- condições observáveis
- comportamentos divergentes
- critérios de aceite mencionados no intake

────────────────────────────────────
PASSO 3 — PRODUZIR 20_findings.md
────────────────────────────────────

Estrutura obrigatória:

# 20_findings

## 1. Contexto Confirmado
Resumo factual do problema baseado no intake.

## 2. Evidências Coletadas
Lista numerada.
Cada item deve conter:
- Arquivo
- Comando executado
- Trecho relevante
- Interpretação objetiva

## 3. Critérios de Aceite Identificados
Lista explícita extraída do intake e contexto.

## 4. Comportamentos Observados
O que o sistema faz hoje.

## 5. Divergências Identificadas
Diferença entre esperado e observado.

## 6. Lacunas de Informação
Informações ainda ausentes (se houver).

PROIBIDO:
- Criar hipoteses.
- Usar palavras como "provavelmente", "talvez".
- Definir plano.
- Sugerir solução.

────────────────────────────────────
TESTE DETERMINÍSTICO FINAL
────────────────────────────────────

Validar existência do artefato:

test -f "$CARD_DIR/investigations/20_findings.md" || { echo "ERROR: missing findings"; exit 2; }

────────────────────────────────────
RETORNO OBRIGATÓRIO
────────────────────────────────────

- Lista de arquivos lidos
- Lista de arquivos alterados
- Saída literal dos testes executados
- Confirmação de que nenhuma hipótese foi criada
- Confirmação de que nenhum plano foi definido

Backward compatibility preservada.
Sem refatoracoes extras.
