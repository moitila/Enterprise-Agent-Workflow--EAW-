# SKILL: eaw_workdir_context_v1

## Objective
Fazer o agente operar corretamente no ambiente do EAW, entendendo a separação entre Tool, TargetRepos e EAW_WORKDIR.

## Core concepts

### Runtime root
- É o repositório/diretório de onde os comandos do EAW devem ser executados
- Contém:
  - ./scripts/eaw
  - runtime
  - comandos CLI
- NÃO deve ser modificado durante execução de cards
- É o ponto de execução dos comandos
- NÃO deve ser inferido por nome de diretório ou apelido local
- Deve ser identificado a partir do ambiente ativo e validado pela existência de `./scripts/eaw`

### Target repositories
- São os repositórios de código alvo
- Definidos em:
  EAW_WORKDIR/config/repos.conf
- Formato:
  <name>|<path>|<role>

- role:
  - target → pode ler (e eventualmente modificar via fluxo controlado)
  - infra → não entra no contexto de implementacao do card

### repos.conf como fonte de verdade
- O agente deve descobrir o ambiente sempre a partir de `repos.conf`
- O agente NAO deve assumir papel de repositorio por nome, apelido, path conhecido ou memoria de outra maquina
- O mapeamento valido e sempre o que estiver no `repos.conf` do workspace atual
- Se o workspace de outra maquina usar nomes diferentes, a skill continua valida porque depende do mapeamento e nao do nome

### EAW_WORKDIR
- Diretório de trabalho isolado do EAW
- Exemplo:
  /home/user/dev/.eaw

Contém:
- config/
  - repos.conf
  - eaw.conf
  - search.conf
- out/
  - artefatos dos cards
- templates/ (quando aplicável)

### OUT_DIR vs EAW_WORKDIR

- Se EAW_WORKDIR estiver definido:
  usar:
  $EAW_WORKDIR/out/<CARD>

- Se NÃO estiver definido:
  usar:
  <repo_tool>/out/<CARD>

## Runtime variables (usadas nos prompts)

- EAW_WORKDIR → raiz do workspace
- OUT_DIR → diretório de saída efetivo
- CARD_DIR → diretório do card
- CONFIG_SOURCE → caminho do repos.conf
- RUNTIME_ROOT → root operacional do EAW para este workspace

## Descoberta obrigatoria do ambiente

Antes de qualquer execucao:

1. Ler `repos.conf`
2. Identificar os repositorios mapeados e seus papeis
3. Determinar, no workspace atual, de onde `./scripts/eaw` deve ser executado
4. Validar esse local com `test -f ./scripts/eaw`

Regras da descoberta:

- Nunca escolher o local de execucao pelo nome do repositorio
- Nunca assumir que o mesmo nome usado em outra maquina representa o mesmo papel
- Nunca assumir que um repositorio `infra` ou `target` e o runtime root sem validacao operacional
- Se houver variavel/runtime prompt apontando `RUNTIME_ROOT`, ela deve ser tratada como autoridade operacional da execucao corrente
- Se o ambiente local e o prompt divergem, parar e reportar ambiguidade em vez de inferir

## Operational mapping

- `repos.conf` define os repositorios disponiveis e seus papeis
- O prompt/runtime define `RUNTIME_ROOT`, `OUT_DIR`, `CARD_DIR` e limites de escrita da execucao corrente
- O agente deve combinar essas duas fontes sem inventar associacoes adicionais
- O agente pode ler `target` apenas dentro do escopo permitido pela fase
- O agente nao deve incluir `infra` no contexto da fase, salvo quando o proprio runtime exigir validacao operacional

## Rules

- Sempre executar comandos a partir do runtime root validado para o workspace atual

- Nunca escrever fora de:
  $OUT_DIR/<CARD>

- Nunca escrever diretamente em TargetRepo fora do fluxo de implementação

- Nunca modificar o runtime root

- Sempre usar repos.conf como fonte de verdade dos TargetRepos
- Sempre usar o prompt/runtime atual como fonte de verdade para `RUNTIME_ROOT`, `OUT_DIR` e `CARD_DIR`
- Nunca derivar decisao operacional a partir do nome de repo

## Validation

Antes de executar qualquer ação:

- ler `repos.conf`
- identificar os repositorios mapeados e seus papeis
- verificar existência de:
  ./scripts/eaw

- verificar:
  $CONFIG_SOURCE

- validar que o diretorio escolhido para execucao corresponde ao runtime root da execucao atual

- identificar:
  $OUT_DIR
  $CARD_DIR

## Fail-fast

Se:
- EAW_WORKDIR inválido
- repos.conf ausente
- runtime não encontrado
- houver ambiguidade sobre qual diretorio e o runtime root
- houver tentativa de inferir papel de repositorio por nome e nao por mapeamento/validacao

→ parar imediatamente
