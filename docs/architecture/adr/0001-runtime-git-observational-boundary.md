# EAW-ADR-0001 - Fronteira Git Observacional do Runtime

- Data: 2026-09-11
- Estado: Accepted
- Autor / proponente: Mantenedor do EAW
- Aprovado por: Mantenedor do EAW
- Supersedes: nenhum
- Superseded by: nenhum

## Contexto e problema

O runtime precisa de fatos sobre repositorios para estabelecer provenance,
diagnosticos e comparacoes de um card. Operacoes Git observacionais fornecem
esses fatos sem alterar um repositorio target.

## Decisao e escopo

O runtime PODE usar Git somente para operacoes de efeito observacional, como ler
identidade do repositorio, branch, revisao, estado do worktree, diff, log ou
historico de arquivo para provenance, diagnostico e comparacao.

O runtime NAO DEVE executar operacoes Git que alterem fontes, indice, branch,
historico ou remotos de um repositorio target. Isso inclui, por exemplo,
`checkout`, `restore`, `reset`, `revert`, `clean`, `add`, `commit`, `merge`,
`rebase` e `push` quando tiverem efeito mutante.

A fronteira e definida pelo efeito, nao por uma lista fechada de nomes de
comandos. O agente executor autorizado pelo escopo do card possui alteracoes de
fontes em repositorios target. O runtime prepara contexto, aplica gates de
workflow, registra provenance e valida limites declarados; ele nao realiza
essas alteracoes de fonte.

## Alternativas consideradas

### Manter Git mutante no runtime como excecao legada

Rejeitada. Uma excecao nao documentada conflita com ownership explicito e faria
o runtime governar e executar alteracoes de fontes do produto.

### Proibir todo uso de Git pelo runtime

Rejeitada. Provenance e diagnostico de repositorios requerem observacao factual;
o modelo arquitetural depende de auditabilidade e diagnosticos reproduziveis.

### Separar Git observacional do runtime de mutacao pelo executor

Aceita. Preserva o papel do runtime na provenance e atribui alteracoes de fontes
ao ator autorizado pelo escopo do card.

## Consequencias, riscos e tradeoffs

O runtime continua apto a coletar evidencia de auditoria, mas nao pode usar Git
para reparar ou modificar repositorio target. Uma necessidade futura de mutacao
de fontes deve ser executada por agente executor autorizado e governada por
escopo proprio de card.

## Owners, principios e contratos afetados

- Servicos de runtime possuem contexto observacional, provenance, diagnosticos
  e governanca de workflow.
- O agente executor autorizado possui alteracoes de fontes de repositorios
  target.
- `EAW-ARCH-P007` governa a fronteira explicita de ownership.
- `EAW-ARCH-P010` governa provenance, rastreabilidade e diagnosticos
  reproduziveis.
- `EAW-ARCH-P008` governa o tratamento explicito exigido para comportamento
  legado.

Esta decisao nao altera os contratos de CLI, track, phase, state, artifact,
prompt ou journal/audit.

## Evidencias e relacoes

- Decisao do mantenedor registrada em `EAW-ARCH-RUNTIME-GIT-BOUNDARY`.
- Nao existe ADR anterior; nenhuma relacao de supersession se aplica.
