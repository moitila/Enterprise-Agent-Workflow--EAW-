# SKILL: eaw_card_creation_v1

## Objective
Criar um card no EAW corretamente usando o CLI oficial.

## Pre-flight

Antes de criar o card:

1. Ler `repos.conf` do workspace atual
   - Identificar os repositórios mapeados e seus papéis (target, infra)
   - Anotar quais repos serão tocados por este card
   - Esta informação deve ser capturada no ingest

2. Validar que o track desejado existe:
   ```
   ./scripts/eaw tracks
   ```
   - Se o track não aparecer na lista, não tentar criar o card
   - Verificar se o track precisa de `eaw tracks install` primeiro

3. Verificar se o card já existe em `out/<CARD_ID>/`
   - Se já existir, NÃO sobrescrever
   - Questionar o executor sobre a intenção:
     - retomar o card existente?
     - derivar um card novo? (ex: `12345A`, `12345B`, `12345_v2`)
   - Nunca criar card duplicado silenciosamente

## Rules

- **EAW_WORKDIR deve ser resolvido antes de criar o card.** O runtime usa `EAW_WORKDIR` para decidir onde criar `out/<CARD_ID>/`. Se `EAW_WORKDIR` não estiver exportado, o runtime faz fallback para o diretório do próprio repo tool (`eaw/out/`) — que é o lugar errado quando existe um workspace separado (ex: `.eaw/`).

  Resolução obrigatória:
  1. Verificar se `EAW_WORKDIR` já está exportado no ambiente
  2. Se não estiver, ler do `eaw.conf` do workspace ou perguntar ao executor
  3. Exportar antes de rodar o CLI:
     ```
     export EAW_WORKDIR=/caminho/do/workspace
     ./scripts/eaw card <CARD_ID> --track <TRACK>
     ```
  4. Após criação, verificar que o card apareceu em `$EAW_WORKDIR/out/<CARD_ID>/`, não em `eaw/out/<CARD_ID>/`

  **Se o card for criado no lugar errado, o workspace não o enxerga e fases subsequentes podem falhar ou operar no contexto errado.**

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
- Incluir no ingest os repositórios envolvidos (lidos do `repos.conf` no pre-flight)
- Se o executor fornecer identificadores de trabalho externo (IDs de work items, referências de serviço, URLs), registrar no ingest como contexto — o formato desses identificadores varia por workspace e organização
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
