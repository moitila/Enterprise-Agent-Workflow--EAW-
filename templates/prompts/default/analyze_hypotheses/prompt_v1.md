Voce e Engenheiro do EAW responsavel por produzir hipoteses formais e testaveis para o card {{CARD}} ({{TYPE}}).

Esta fase e OBRIGATORIA antes do Planning.

────────────────────────────────────
REGRAS OBRIGATÓRIAS
────────────────────────────────────

- Não alterar código.
- Não criar arquivos adicionais.
- Não remover headings do template.
- Cada hipótese deve ser testável.


────────────────────────────────────
PRÉ-CHECK OBRIGATÓRIO
────────────────────────────────────

cd "$EAW_ROOT_DIR"
test -f ./scripts/eaw || { echo "ERROR: not in EAW-tool root"; exit 2; }
test -f "$CONFIG_SOURCE" || { echo "ERROR: missing config source"; exit 2; }

────────────────────────────────────
PRÉ-CONDIÇÕES HARD
────────────────────────────────────

Confirmar existência de:

- $CARD_DIR/investigations/00_intake.md
- $CARD_DIR/investigations/20_findings.md

Se faltar qualquer um -> abortar.

────────────────────────────────────
OBJETIVO ESTRUTURAL
────────────────────────────────────

Gerar 30_hypotheses.md contendo:

- Coverage Map explícito
- 5 a 10 hipóteses
- Classificação de risco
- Teste determinístico por hipótese
- Ranking formal
- Provenance

────────────────────────────────────
PASSO 1 — EXTRAÇÃO FORMAL
────────────────────────────────────

Extrair dos artefatos:

- Critérios de aceite
- Regras determinísticas
- Comportamentos esperados
- Comportamentos observados divergentes
- Contratos de erro

Criar seção obrigatória:

## Coverage Map

Listar cada critério identificado.

────────────────────────────────────
PASSO 2 — GERAÇÃO DE HIPÓTESES
────────────────────────────────────

Criar entre 5 e 10 hipóteses.

Estrutura obrigatória para cada H#:

### H#

Tipo de risco:
- funcional
- estrutural
- contrato
- testabilidade

Descrição objetiva

Causa raiz provável

Critério(s) coberto(s) (referência explícita ao Coverage Map)

Impacto:
(alto/médio/baixo + justificativa objetiva)

Sinais observáveis

────────────────────────────────────
PASSO 3 — TESTE DETERMINÍSTICO
────────────────────────────────────

Para cada H# definir:

- Comando ou cenário controlado
- Resultado esperado:
  - exit code
  - prefixo textual
  - presença/ausência de arquivo
  - comportamento verificável

Sem testes subjetivos.

────────────────────────────────────
PASSO 4 — RANKING FORMAL
────────────────────────────────────

Criar ranking ordenado:

H# — probabilidade × impacto — justificativa objetiva

────────────────────────────────────
PASSO 5 — RISCO RESIDUAL
────────────────────────────────────

Adicionar seção:

## Risco Residual Após Mitigação

Analisar:

- O que pode permanecer mesmo após correção?
- Existe risco estrutural não eliminável?

────────────────────────────────────
PASSO 6 — PROVENANCE
────────────────────────────────────

Adicionar:

Arquivos lidos  
Arquivos ignorados + motivo  
Limitações  

────────────────────────────────────
DEFINITION OF DONE
────────────────────────────────────

Arquivo válido se:

- Coverage Map presente
- Todos critérios cobertos
- 5–10 hipóteses
- Todas com teste determinístico
- Ranking presente
- Provenance presente
- Nenhum arquivo além de 30_hypotheses.md alterado

────────────────────────────────────
TESTE FINAL
────────────────────────────────────

test -f "$CARD_DIR/investigations/30_hypotheses.md" || { echo "ERROR: missing hypotheses"; exit 2; }

RETORNO OBRIGATÓRIO:

- Lista de arquivos lidos
- Confirmação de que apenas 30_hypotheses.md foi alterado
- Saída literal dos testes executados
- Confirmação de que nenhuma decisão de implementação foi tomada

Backward compatibility preservada.
Sem decisoes de solucao nesta fase.
