# BUG Handoff Codes Catalog - v1

**Versao**: v1  
**Track**: bug_ONBOARD  
**Origem**: card BO-02  
**Data**: 2026-04-15  
**Status**: fechado para uso documental nesta iteracao

---

## Proposito

Este catalogo define os codes estaveis de handoff do dominio bug para leitura posterior no fluxo do EAW. O objetivo e registrar contratos documentais claros para BO-03, preservando rastreabilidade, sem introduzir qualquer consumo runtime nesta iteracao.

O arquivo existe para padronizar o significado de dois estados de conclusao observados em findings:
- quando a causa raiz foi confirmada com precisao suficiente para orientar a proxima etapa;
- quando a regressao foi esclarecida e o quadro ficou apto para leitura posterior.

Esta revisao e estritamente contratual/documental. Ela nao implementa consumo automatico, nao altera workflow e nao introduz comportamento novo fora deste catalogo.

---

## Catalogo de Codes

### `ROOT_CAUSE_CONFIRMED`

**Descricao**: A investigacao de `findings` confirmou a causa raiz com evidencia suficiente para sustentar a leitura posterior do card. O estado indica que o problema foi identificado de modo deterministico e nao depende de suposicao aberta para a proxima etapa.

**Condicao de emissao**: emitir apenas quando a analise factual do card convergir para uma causa raiz unica, sustentada por evidencias observaveis e sem ambiguidades relevantes pendentes.

**Semantica para uso posterior**: este code registra que o proximo card pode tratar a causa como estabelecida e consumir essa conclusao como base documental. O significado e propositalmente conservador: ele confirma a causa raiz, mas nao expande o escopo para alem do necessario.

**Traceabilidade**: BO-02 define o contrato; BO-03 e o consumidor documental previsto para ler este estado e decidir a proxima acao contratual.

---

### `REGRESSION_CLEAR`

**Descricao**: A investigacao identificou um quadro de regressao compreensivel e bem delimitado, suficiente para orientar leitura posterior, mas sem exigir que a narrativa do card vire uma tese mais ampla do que o necessario.

**Condicao de emissao**: emitir quando a regressao observada puder ser descrita com estabilidade, incluindo o que mudou, o que ficou preservado e por que o quadro e confiavel para referencia posterior.

**Semantica para uso posterior**: este code registra que a regressao foi esclarecida em termos documentais e pode ser usada como base de continuidade em BO-03. Ele nao substitui a confirmacao de causa raiz; ele complementa a leitura do estado do card.

**Traceabilidade**: BO-02 define o contrato; BO-03 e o ponto de leitura posterior que deve interpretar este estado em conjunto com o restante do catalogo.

---

## Provenance e Limitacoes

- Nesta iteracao, o onboarding foi consumido segundo o contrato canonico do EAW: fonte estavel mantida fora do repositorio alvo, sob `EAW_WORKDIR/context_sources/onboarding/<repo_key>/`, e lida por referencia no workspace ativo.
- O `repo_key` efetivo foi resolvido pelo workspace ativo para o repositorio alvo deste card, e a execucao usou essa fonte de onboarding para manter forma, disciplina e limites do catalogo.
- O arquivo foi publicado no repositorio alvo resolvido pelo workspace ativo, conforme o scope lock do BO-02.
- Este catalogo e apenas documental nesta versao. O consumo posterior e responsabilidade de fases futuras do fluxo.

## Rastreabilidade

- **Card de origem**: BO-02
- **Track de execucao**: bug_ONBOARD
- **Consumo documental previsto**: BO-03
- **Base de forma**: catalogo `ARCH_REFACTOR_handoff_codes_v1.md`
- **Fonte de onboarding usada**: onboarding do repositorio alvo, resolvido pelo workspace ativo segundo o contrato `EAW_WORKDIR/context_sources/onboarding/<repo_key>/`
