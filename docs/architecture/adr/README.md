# EAW - Architecture Decision Records

## Proposito e relacao com a arquitetura

ADRs registram decisoes duraveis, suas alternativas e consequencias. O
[TARGET_ARCHITECTURE](../TARGET_ARCHITECTURE.md) descreve a arquitetura-alvo vigente;
[ARCHITECTURE_PRINCIPLES](../ARCHITECTURE_PRINCIPLES.md) fornece regras estaveis.
Um ADR explica uma decisao especifica, sem substituir a visao integrada.

Este README estabelece o processo de registro e manutencao de decisoes.
Perguntas abertas nao sao decisoes.

## Quando exigir ADR

Uma decisao DEVE ter ADR quando altera boundaries, ownership entre camadas,
direcao de dependencias ou um principio; introduz excecao arquitetural; define
um mecanismo novo com impacto arquitetural; ou decide garantias
de persistencia, concorrencia, reproducibilidade e compatibilidade com impacto
arquitetural. Mudancas publicas/persistidas com tradeoffs duraveis tambem exigem
ADR, alem da atualizacao explicita do contrato afetado.

Decisoes futuras sobre distribuicao, separacao de repositorios, packages, plugins
ou compatibilidade entre runtime e distribuicoes de tracks exigirao avaliacao
arquitetural e ADR quando forem analisadas. Esses assuntos pertencem a arquitetura
2.0; este processo nao os decide nem os inclui no saneamento interno da 1.0.

Correcoes locais de redacao, conteudo de track usando capacidades existentes e
refatoracoes internas conformes sem novo tradeoff duravel nao exigem ADR apenas
por serem mudancas. Continuam sujeitas ao escopo e contratos aplicaveis.

## Estrutura minima

Cada ADR DEVE conter:

1. ID, titulo, data, estado, autor/proponente e aprovador quando aceito.
2. Contexto e problema, separando evidencia AS-IS de intencao TO-BE.
3. Decisao e escopo, incluindo o que nao esta sendo decidido.
4. Alternativas consideradas e motivos para rejeicao.
5. Consequencias, riscos e tradeoffs.
6. Owners, principios e contratos afetados, com links.
7. Compatibilidade e migracao: consumidores, comportamento preservado, alteracoes explicitas e criterio de verificacao.
8. Evidencias e relacoes com ADRs anteriores; campos `Supersedes` e `Superseded by` quando aplicaveis.

Se faltar evidencia para escolher, registrar a questao pertinente ao escopo da
arquitetura vigente no TARGET_ARCHITECTURE como `OPEN ARCHITECTURAL QUESTION` ou
manter o ADR como Proposed no trabalho arquitetural correspondente, indicando
contexto conhecido, opcoes e informacao necessaria. Nao apresentar hipotese como
decisao aceita.

## Estados e aprovacao

| Estado | Significado |
|---|---|
| Proposed | Em avaliacao; nao autoriza excecao nem implementacao. |
| Accepted | Aprovado explicitamente pelo mantenedor, com aprovador e data registrados. |
| Rejected | Avaliado e recusado; permanece como historico. |
| Superseded | Substituido por outro ADR Accepted, com referencia reciproca. |
| Deprecated | Nao recomendado para novas mudancas, sem substituto aceito; suporte existente continua sujeito a compatibilidade. |

Transicoes normais: Proposed -> Accepted ou Rejected; Accepted -> Superseded ou
Deprecated; Deprecated -> Superseded quando houver substituto. Reconsiderar uma
decisao rejeitada exige nova proposta referenciando a anterior.

Aceitacao arquitetural nao equivale a execucao, deploy ou autorizacao automatica
para alterar runtime. O trabalho de implementacao precisa de escopo proprio.

## Naming e supersession

Arquivos futuros: `NNNN-short-kebab-case-title.md`, neste diretorio, com quatro
digitos sequenciais; primeiro numero disponivel `0001`. ID interno:
`EAW-ADR-NNNN`. Numeros e IDs NAO DEVEM ser reutilizados nem renumerados; links
historicos devem permanecer validos.

Decisoes aceitas NAO DEVEM ter seu conteudo substantivo reescrito para ocultar
mudanca de direcao. Um novo ADR descreve e justifica a substituicao. Ao aceita-lo,
atualizar o estado e `Superseded by` do anterior e `Supersedes` do novo. Correcoes
editoriais podem ocorrer sem alterar o significado historico.

Uma decisao aceita que altera a arquitetura DEVE atualizar, no mesmo trabalho
documental, TARGET_ARCHITECTURE e os principios afetados, preservando IDs e
referenciando o ADR. Nao pode existir excecao silenciosa: se houver conflito
ainda nao reconciliado, registrar a pendencia e obter resolucao do mantenedor
antes de implementar. ADR Proposed nao tem precedencia sobre norma vigente.
Contratos existentes nao mudam apenas pela aceitacao do ADR; suas alteracoes e
migracoes devem ser explicitadas no escopo correspondente.
