# SKILL: quick_start_operator

## Objetivo

Complementar a skill `bootstrap_operator` orientando o operador/agente na criação
e execução do primeiro card EAW. Esta skill cobre o ciclo após o workspace já estar
inicializado.

## Relação com bootstrap_operator

| Skill | Quando usar |
|-------|------------|
| `bootstrap_operator` | Setup do workspace (init, EAW_WORKDIR, repos.conf, validate) |
| `quick_start_operator` | Primeiro card, após workspace pronto |

## O modelo operacional (leia antes de operar)

Consulte `docs/GETTING_STARTED.md` para o modelo mental completo. Resumo:

- **Human requester**: formula o pedido e revisa artefatos
- **EAW operator/orchestrator**: roda o CLI, controla avanço, faz handoff do prompt
- **Isolated phase agent**: recebe o prompt renderizado, produz artefatos — NÃO opera o CLI

O EAW não executa o agente isolado automaticamente. O operador entrega o prompt
renderizado a uma sessão separada de agente.

## Jornada do primeiro card

Consulte `docs/QUICKSTART.md` para o guia executável completo. Passos-chave:

1. Escolher track: `eaw tracks`
2. Criar card: `eaw card <CARD_ID> --track <TRACK>`
3. Escrever pedido inicial em `ingest/raw_card_explication.md` (use o template em `templates/ingest/`)
4. Validar: `eaw preflight <CARD_ID>`
5. Avançar: `eaw next <CARD_ID>`
6. Encontrar prompt em `out/<CARD_ID>/prompts/`
7. Abrir sessão separada de agente e entregar o prompt integralmente
8. Receber e revisar artefatos contra o pedido original
9. Repetir com `eaw next` até o card completar

## Erros comuns (evite)

- O agente isolado não opera o CLI — apenas o orquestrador opera
- Conversa não é estado oficial — apenas artefatos revisáveis avançam o card
- O prompt renderizado é derivado — o pedido original está em `ingest/`
- Não edite `tracks/`, `templates/prompts/`, `scripts/` durante execução normal de card

## Limites absolutos

- NÃO operar `./scripts/eaw` como agente isolado de fase
- NÃO editar arquivos de runtime (`scripts/`, `tracks/`, `lib.sh`, `eaw_core.sh`)
- NÃO assumir papel de repo por nome — sempre ler `repos.conf`
- NÃO pular a revisão de artefatos contra o pedido original
