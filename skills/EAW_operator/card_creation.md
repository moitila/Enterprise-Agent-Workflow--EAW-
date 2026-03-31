# SKILL: eaw_card_creation_v1

## Objective
Criar um card no EAW corretamente usando o CLI oficial.

## Rules

- Sempre criar card usando o CLI:
  ./scripts/eaw card <CARD_ID> --track <TRACK>

- Nunca criar arquivos ou diretórios manualmente para simular card

- Não assumir execução automática de fases (intake, analyze, implement)

- Não implementar nada ao criar o card

- Agente isolado NÃO é exigido na criação do card; esse requisito se aplica exclusivamente à execução de fases via `next` (skill eaw_next_execution)

## Validation

Após executar:

- Verificar exit code do comando
- Verificar existência do card em:
  out/<CARD_ID> ou EAW_WORKDIR equivalente
- Verificar existência do state do card
- Confirmar track e fase inicial no state
- Card já começa na primeira fase
- Após criar o card:
  salvar a explicação do problema/objetivo em:
  out/<CARD_ID>/ingest/
- Nome do arquivo é livre, mas preferir:
  raw_card_explication.md
- O conteúdo deve registrar tudo que o usuário forneceu sobre o problema/objetivo: descrição direta, diálogo, ideias, contexto — sem omissões e sem reescrever como spec técnica
- Não assumir execução automática de fases
- Não implementar nada

## Output obrigatório

Informar:

- CARD_ID
- TRACK
- comando executado
- sucesso ou falha
- evidência do diretório do card
- fase inicial detectada

## Fail-fast

Se:
- ./scripts/eaw não existir
- ambiente inválido

→ parar e reportar erro
