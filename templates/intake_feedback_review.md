# Intake FEEDBACK_REVIEW <CARD>

<!--
Preencha todas as secoes antes de executar a primeira fase.
Este arquivo e a fonte de intencao para toda a execucao da feedback_review.
-->

## Track de Origem

[Nome da track a ser revisada, ex.: bug_onboarding]

## Intervalo de Cards

[Identificadores dos cards incluidos na revisao, ex.: EAW-BG-001 a EAW-BG-010]
[Ou lista explicita de card IDs]

## Criterios de Inclusao

[Quais fases da track de origem serao incluidas no corpus?]
[Existe algum criterio de exclusao? Ex.: cards incompletos, cards de teste?]

## Objetivo da Revisao

[Por que esta revisao esta sendo executada agora?]
[Qual pergunta central deve ser respondida?]

## Restricoes Operacionais

- A analise e horizontal dentro da track escolhida; nao inclui outras tracks.
- O corpus deve ser reconciliado por identidade dos conjuntos, nao por contagem.
- Nenhum sampling silencioso e permitido.
- O append nos feedbacks originais e idempotente: um append por resultado/ciclo.
- Implementacoes das correcoes encontradas ocorrem em cards separados.

## Riscos Conhecidos

[Feedbacks que podem estar ausentes para fases do corpus?]
[Cards com artefatos incompletos?]
[Divergencias conhecidas entre templates atuais e prompts historicos?]

## Questoes em Aberto

[Alguma incerteza sobre o escopo ou criterios de inclusao?]
