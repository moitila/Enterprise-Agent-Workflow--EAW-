# EAW - Architecture Principles

Versao documental: 1. Escopo: EAW 1.0.

Normas para saneamento interno segundo **Contract-Driven Workflow Runtime**.
Correspondencia direta: P1 do mantenedor = EAW-ARCH-P001, e assim ate P10.
DEVE/NAO DEVE sao obrigacoes; DEVERIA indica preferencia com excecao justificada.
O [TARGET_ARCHITECTURE](TARGET_ARCHITECTURE.md) define boundaries e ownership.
Estes principios nao autorizam mudar contratos ou comportamento existentes.
Desvios atuais sao divida a avaliar, nao precedentes para novas implementacoes.

## EAW-ARCH-P001 - Runtime independente de tracks concretas

- Regra: o runtime DEVE operar sobre contratos genericos de track, phase, transition, artifact, prompt e context; NAO DEVE escolher regras pela identidade de uma track concreta.
- Racional: uma capacidade generica deve poder servir a qualquer track compativel com seus contratos.
- Conformidade: resolver `track_id` como identificador e avaliar suas transicoes declaradas.
- Violacao: `if track_id == bug` para produzir um artifact ou escolher validacao no core.

## EAW-ARCH-P002 - CLI como adapter

- Regra: a CLI DEVE tratar parsing, dispatch, traducao de parametros, apresentacao e exit codes publicos; regras substantivas DEVEM pertencer aos servicos.
- Racional: apresentacao e protocolo de entrada nao devem definir o workflow.
- Conformidade: converter resultado do caso de uso em mensagem e exit code preservados.
- Violacao: decidir na CLI que uma fase esta completa pela existencia de um arquivo.

## EAW-ARCH-P003 - Command handlers finos

- Regra: handlers DEVEM coordenar servicos; NAO DEVEM concentrar lifecycle, state machine, contexto, rendering, validacao, journal e resolucao de tracks.
- Racional: coordenacao de caso de uso deve reutilizar regras com owners definidos.
- Conformidade: `next` e `run` usam o mesmo mecanismo de progressao.
- Violacao: cada comando implementar sua propria validacao e transicao de fase.

## EAW-ARCH-P004 - Tracks preferencialmente declarativas

- Regra: tracks DEVEM expressar metadata, fases, transicoes, prompts, artifacts, bindings, completion e policies pelo contrato suportado. Nova track com capacidades existentes NAO DEVE exigir alteracao do runtime.
- Racional: conteudo especifico pertence a definicao da track; mecanismo comum pertence ao runtime.
- Conformidade: declarar um requisito de artifact com um validador generico existente.
- Violacao: acrescentar logica especifica no runtime para cada nova track que usa capacidades ja suportadas, ou esconder execucao arbitraria em um campo declarativo.

## EAW-ARCH-P005 - Contratos soberanos

- Regra: mudancas de CLI, track, phase, state, artifact, prompt e journal/audit DEVEM ser explicitas, incluindo impacto em consumidores e dados persistidos.
- Racional: reorganizacao interna nao e autorizacao para quebrar integracoes.
- Conformidade: identificar versao, leitores afetados e migracao de um campo antes de altera-lo.
- Violacao: renomear um artifact ou mudar texto de prompt como efeito incidental de extracao de funcao.

## EAW-ARCH-P006 - Dependencias direcionadas

- Regra: dependencias DEVEM seguir CLI -> application -> runtime services -> contracts/primitives; tracks -> contracts. NAO DEVEM existir ciclos, core dependente de CLI, contracts dependentes da implementacao ou runtime dependente de track concreta.
- Racional: responsabilidades inferiores devem ser utilizaveis sem conhecimento dos consumidores superiores.
- Conformidade: servico devolve um resultado contratual e a CLI o apresenta.
- Violacao: primitiva chamar handler para obter uma regra, ou carregar template concreto como definicao generica.

## EAW-ARCH-P007 - Ownership explicito

- Regra: antes de implementar, o agente DEVE identificar o owner na matriz do TARGET_ARCHITECTURE e reutiliza-lo; lacunas DEVEM ser registradas antes de criar implementacoes concorrentes. O runtime pode usar Git para observacao; a mutacao de fontes em repositorio target pertence somente ao agente executor autorizado pelo escopo, conforme [EAW-ADR-0001](adr/0001-runtime-git-observational-boundary.md).
- Racional: uma regra com varios owners diverge e perde rastreabilidade; separar governanca de workflow da alteracao de fontes preserva essa responsabilidade.
- Conformidade: requisitos especificos ficam na definicao da track, sua validacao no servico de artifacts e a decisao de avancar no lifecycle; o runtime registra o estado do repositorio e o agente executor autorizado realiza uma alteracao de fonte.
- Violacao: copiar resolucao de template para cada consumidor, guardar regra sem owner em utilitarios ou o runtime executar Git com efeito mutante em repositorio target.

## EAW-ARCH-P008 - Compatibilidade explicita

- Regra: legacy, deprecated e fallback DEVEM ter owner, gatilho, comportamento preservado e criterio de retirada/reavaliacao identificados; NAO DEVEM ser o modelo recomendado para novas implementacoes.
- Racional: suporte historico nao deve tornar-se dependencia estrutural permanente por acidente.
- Conformidade: traducao de formato antigo para o mecanismo comum, documentada como compatibilidade.
- Violacao: fallback silencioso para uma track concreta apresentado como regra universal do runtime.

## EAW-ARCH-P009 - Refatoracao preserva comportamento

- Regra: refatoracoes DEVEM preservar CLI, execucao de tracks, prompts, artifacts, state transitions, journal, exit codes e contratos salvo autorizacao explicita. Mudanca estrutural e funcional DEVERIAM ser separadas.
- Racional: permite avaliar arquitetura sem esconder regressao ou mudanca de produto.
- Conformidade: extrair owner mantendo resultados observaveis, com verificacao apropriada em trabalho futuro de codigo.
- Violacao: corrigir um comportamento legacy durante uma extracao sem explicitar a mudanca funcional.

## EAW-ARCH-P010 - Auditabilidade

- Regra: decisoes de workflow DEVEM ser explicaveis por contratos, estado e evidencia; mecanismos DEVEM favorecer determinismo, rastreabilidade e diagnosticos reproduziveis. Quando coletar provenance de repositorio, o runtime DEVE usar apenas meios observacionais, conforme [EAW-ADR-0001](adr/0001-runtime-git-observational-boundary.md).
- Racional: um operador precisa entender por que houve transicao, prompt, artifact ou bloqueio.
- Conformidade: preservar origem e binding efetivo e distinguir materializacao de execucao concluida; explicitar entradas variaveis como tempo e ambiente.
- Violacao: heuristica oculta por nome de track, fallback sem diagnostico ou abstracao que perde a origem da decisao.

## Aplicacao por agentes

Orientacao/Skills dizem como trabalhar; onboarding e fonte atual informam o AS-IS;
principios do mantenedor definem a intencao; esta arquitetura define a evolucao.
O agente DEVE registrar divergencias em material investigativo separado da norma,
sem corrigi-las fora do escopo autorizado.
Questoes sem evidencia suficiente DEVEM ser registradas como
`OPEN ARCHITECTURAL QUESTION`, com contexto, opcoes e informacao necessaria.
Excecoes e mudancas de direcao seguem o [processo de ADR](adr/README.md), com
aprovacao do mantenedor. Uma proposta de ADR nao suspende estas regras.
