# Fixture 13 — Interrupcao antes do append

Este cenario representa uma execucao da feedback_review interrompida antes
da fase backlog_finalization completar.

O arquivo de feedback original (EAW-BG-SAMPLE-13) NAO deve conter nenhum append,
pois o resultado consolidado nao foi determinado.

Verificacao: ausencia de linha com chave card=EAW-FBR-INTERRUPTED|fase=backlog_finalization
no rodape do feedback original confirma comportamento correto.
