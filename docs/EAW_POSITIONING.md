# EAW Positioning

## TL;DR

O EAW e um sistema que transforma execucao com agentes em um processo controlado, auditavel e reproduzivel.

Ele nao executa o trabalho diretamente. Ele governa como o trabalho deve ser executado.

## Problema que o EAW resolve

Sistemas baseados em agentes apresentam problemas recorrentes:

- falta de rastreabilidade
- ausencia de controle sobre o que foi executado
- prompts nao versionados
- outputs nao reproduziveis
- dificuldade de auditoria
- escrita fora de escopo
- mistura entre contexto estavel e contexto operacional

O EAW existe para resolver esses problemas de forma deterministica, por meio de cards, fases, contratos, prompts governados, artefatos auditaveis e validacao operacional.

## 1. Definicao objetiva do EAW

O Enterprise Agent Workflow (EAW) e um sistema de governanca deterministica para trabalho de engenharia orientado por card.

Ele organiza a execucao em `track -> phase -> prompt -> artifacts`, controla o contexto injetado em cada fase, limita a superficie de escrita, valida contratos de execucao e produz trilha auditavel em `out/<CARD>/`.

O EAW nao e definido pelo agente que executa a fase. Ele e definido pelo runtime, pelo modelo de card, pelos contratos de fase, pelos prompts versionados e pelos artefatos observaveis gerados durante a execucao.

Em termos praticos, o EAW existe para transformar trabalho com agentes em um fluxo governado, reproduzivel e auditavel.

## 2. O que o EAW e

O EAW e:

- um sistema de execucao governada por card
- um runtime CLI que avanca trabalho fase a fase por comandos como `next`, `run`, `validate` e `complete`
- um mecanismo de orquestracao deterministica baseado em `track.yaml`, `phase.yaml`, estado do card e prompts ativos
- um sistema de contratos explicitos de fase, incluindo artefatos obrigatorios, estrategia de completion, limites de leitura, limites de escrita, fail-fast e validacoes
- um sistema de governanca de prompts, em que prompts sao versionados, ativados por `ACTIVE` e resolvidos pelo runtime
- um sistema de engenharia de contexto, com separacao formal entre `onboarding` e `dynamic_context`
- um sistema de trilha auditavel por meio de `state_card`, prompts materializados, artifacts da fase, provenance e `execution_journal.jsonl`
- um mecanismo de contencao operacional por allowlist de escrita e fronteiras explicitas entre runtime root, workspace e target repos

Capacidades reais do EAW:

- governar o que cada fase pode ler e escrever
- materializar o prompt efetivo de cada fase
- controlar transicoes entre fases com base no workflow instalado
- validar se a fase produziu os artefatos exigidos
- registrar a execucao em trilha auditavel
- separar contexto estavel de repositorio de contexto operacional derivado do card
- permitir execucao isolada por fase com limites explicitos

## 3. O que o EAW NAO e

O EAW nao e:

- um framework de agentes
- um runtime de raciocinio multiagente
- um sistema de coordenacao cognitiva entre agentes
- um orchestrator generico de tools para LLM
- uma engine de workflow distribuido no estilo scheduler de jobs
- uma plataforma visual de construcao de apps de IA
- um produto de chat, copiloto ou IDE agent
- um substituto do runtime real onde a logica de negocio roda
- um sistema que opera fora de contratos, prompts e artefatos explicitos

Negacoes importantes:

- O EAW nao e LangGraph, AutoGen ou equivalente. Ele nao existe para modelar grafos de agentes, protocolos de conversacao entre agentes ou loops cognitivos autonomos.
- O EAW nao e Temporal, Airflow ou equivalente. Ele nao existe para orquestrar jobs distribuidos, retries sistêmicos, scheduling temporal ou dependencias operacionais de infraestrutura.
- O EAW nao e Dify, Flowise ou equivalente. Ele nao existe para compor pipelines visuais de IA, publicar apps conversacionais ou servir como camada de produto para usuarios finais.
- O EAW nao e o agente. O agente e apenas um executor possivel dentro de uma fase governada.
- O EAW nao e o target repo. Ele governa o trabalho sobre o target repo, mas nao se confunde com o codigo-alvo.
- O EAW nao e governanca abstrata. Sua governanca e operacional, materializada e verificavel no runtime e nos artefatos.

## 4. Papel arquitetural

O papel arquitetural correto do EAW e de control plane de trabalho de engenharia orientado por agentes.

Ele define:

- qual card esta em execucao
- em que fase o card esta
- qual prompt efetivo deve ser usado
- qual contexto pode ser consumido
- quais artefatos devem ser produzidos
- quais caminhos podem ser escritos
- quando a fase pode ser considerada valida
- como a execucao fica auditavel

Ele nao e o execution plane do sistema de negocio.

O execution plane inclui:

- o agente que executa a fase
- os comandos concretos rodados
- o codigo do target repo
- os testes, scripts e binarios reais
- a infraestrutura externa, quando existir

Formula curta:

- EAW = control plane governado do trabalho por card
- agente, shell, testes e codigo-alvo = execution plane

Consequencia arquitetural:

o EAW governa como o trabalho e conduzido, nao substitui o ambiente onde o trabalho efetivamente acontece.

## 5. Principios fundamentais

Determinismo operacional.
A execucao deve depender de contratos observaveis, nao de interpretacao livre do agente.

Card como unidade de governanca.
O trabalho e organizado, auditado e encerrado por card, nao por sessao de chat.

Fase como fronteira real.
Cada fase tem objetivo, prompt, leitura, escrita e artefatos proprios.

Prompt governado.
O prompt efetivo e resolvido pelo runtime a partir de templates versionados e `ACTIVE`, nao por composicao informal no momento da execucao.

Contexto com contrato.
`onboarding` e `dynamic_context` nao sao a mesma coisa e nao devem ser tratados como intercambiaveis.

Escrita minima e explicita.
Nenhuma fase deve escrever fora da allowlist soberana da execucao.

Fail-fast.
Ambiguidade de workspace, ausencia de artefato obrigatorio, divergencia de contrato ou fronteira violada devem interromper a execucao.

Auditabilidade por artefato.
Se uma decisao, contexto ou saida nao puder ser inspecionada em artefato materializado, ela nao esta adequadamente governada.

Separacao entre governanca e implementacao.
O EAW governa a execucao; ele nao deve ser confundido com a implementacao entregue no repo alvo.

## 6. Anti-padroes

Chamar o EAW de framework de IA.
Isso apaga sua funcao real de governanca operacional.

Tratar o EAW como runtime de agentes.
O agente executa dentro do EAW; o EAW nao e o agente.

Usar prompt como se fosse contrato suficiente.
No EAW, prompt sem `phase contract`, `artifact contract`, `write scope` e `state` nao basta.

Escrever contexto dinamico como se fosse onboarding estavel.
`dynamic_context` e operacional e de fase; `onboarding` e contexto estavel de repositorio.

Confundir artefato do card com entrega do repo.
`out/<CARD>/` e trilha governada da execucao; a entrega real pode estar no target repo.

Usar o runtime root como se fosse repo alvo.
O runtime root e ponto operacional do EAW, nao destino normal de implementacao de card.

Aceitar inferencia onde o contrato exige resolucao explicita.
Exemplos: inferir repo por nome, inferir workspace por memoria, inferir sucesso de fase sem validar artifacts.

Tratar governanca como detalhe opcional.
No EAW, governanca nao e documentacao lateral; ela e parte do comportamento do sistema.

Misturar control plane com product plane.
O EAW nao e a aplicacao final do usuario nem a plataforma de serving da solucao.

## 7. Quando usar o EAW

O EAW deve ser utilizado quando:

- e necessario garantir rastreabilidade de execucao com agentes
- o trabalho precisa ser reproduzivel
- ha necessidade de governanca sobre prompts e contexto
- o impacto de erro exige controle de escrita e validacao de artifacts
- multiplas fases, multiplos agentes ou multiplas execucoes precisam operar sob contrato
- a equipe precisa distinguir claramente governanca de execucao e implementacao

O EAW nao e indicado quando:

- o objetivo e prototipagem rapida sem governanca
- o fluxo e simples e nao exige rastreabilidade
- a execucao depende de iteracao livre e exploratoria sem necessidade de trilha auditavel
- o custo operacional de contratos, artifacts e validacoes e maior do que o risco do trabalho
