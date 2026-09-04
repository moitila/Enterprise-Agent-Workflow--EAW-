# Adversarial Review Track (V1 Experimental)

## Finalidade

`adversarial_review` audita se as conclusoes, criterios de aceite e status
final declarados por um card EAW ja executado (o "card alvo") sao realmente
sustentados pelas evidencias que ele produziu e pelo comportamento
observavel do sistema. Nao e uma track de code review convencional: nao
corrige automaticamente o codigo do card alvo, nao comita, nao da push e nao
cria automaticamente um card de remediacao.

## Pre-requisitos

O `ingest/raw_card_explication.md` deve identificar o card alvo (ID e,
quando conhecida, a track). Ausencia de identificacao do card alvo bloqueia
`case_reconstruction`.

## Fases

1. `case_reconstruction`: inventaria o que o card alvo prometeu, o que foi
   alterado e quais evidencias foram produzidas, sem julgar merito.
2. `evidence_audit`: classifica cada evidencia inventariada e a vincula a um
   claim/criterio de aceite especifico, isolando lacunas.
3. `adversarial_design`: seleciona, com base nas lacunas, quais tecnicas
   adversariais sao pertinentes e se execucao real e autorizada.
4. `adversarial_execution`: aplica exatamente as tecnicas selecionadas,
   preservando a distincao entre execucao real confirmada e suporte
   estrutural.
5. `verdict`: sintetiza um veredito multi-eixo objetivo (CORRECAO
   FUNCIONAL, CAUSA RAIZ, QUALIDADE DA EVIDENCIA, REGRESSAO, CRITERIOS DE
   ACEITE, COERENCIA DO FECHAMENTO EAW).
6. `remediation_handoff`: traduz o veredito em uma recomendacao de proxima
   acao (ENCERRAR, bug, bug_ONBOARD, feature, spike, code review, nova fase
   adversarial, evidencia externa necessaria), sem criar, comitar ou dar
   push em nada.

## Artefatos

Os artefatos ficam em `audit/` dentro do diretorio do card:
`00_case_reconstruction.md`, `10_evidence_matrix.md`, `11_evidence_gaps.md`,
`20_adversarial_plan.md`, `30_adversarial_results.md`, `40_verdict.md` e
`50_remediation_handoff.md`. Nenhuma fase emite
`investigations/20_handoff.json`; a progressao ocorre exclusivamente via
`completion.strategy: required_artifacts_exist`.

## Comportamento Fail-closed

Ausencia de evidencia no card alvo e classificada como "evidencia nao
comprovada", nunca inferida. Status COMPLETE declarado pelo card alvo nao
neutraliza blocker/waiting ou criterio de aceite pendente identificado nas
fases anteriores.

## Operacao Read-only e Cross-card

O card alvo reside sob `OUT_DIR/<CARD_ALVO>/`, fora do diretorio deste card.
`case_reconstruction`, `evidence_audit` e `adversarial_execution` leem
`OUT_DIR` como raiz e se autolimitam ao ID do card alvo resolvido em
`ingest/raw_card_explication.md` - nao ha enforcement estrutural do runtime
alem do prefix-matching em `OUT_DIR`. `adversarial_execution` e a unica fase
autorizada a ler codigo-fonte de `TARGET_REPOS` diretamente, somente
leitura. Nenhuma fase altera `TARGET_REPOS` de forma permanente, comita ou
da push.

## Limitacoes Conhecidas da V1

- Sem `phase.context` (onboarding/dynamic context): decisao explicita de
  `investigations/10_track_design.md`, nao omissao.
- Sem `skip_when`: nenhuma condicao de pulo com semantica inequivoca foi
  identificada na V1.
- Acesso cross-card via `OUT_DIR` como raiz depende do agente se autolimitar
  corretamente ao card alvo; nao ha enforcement estrutural adicional do
  runtime.

## Uso

Crie o card com a track instalada, identificando o card alvo em
`ingest/raw_card_explication.md` apos a criacao:

```bash
./scripts/eaw card REVIEW-ADV-1 --track adversarial_review
```

Preencha `ingest/raw_card_explication.md` com o ID do card alvo e avance
manualmente:

```bash
./scripts/eaw preflight REVIEW-ADV-1
./scripts/eaw next REVIEW-ADV-1
```

Repita o ciclo de preflight e `next` ate `remediation_handoff`. A execucao
das fases cabe a agentes isolados; somente o orquestrador avanca o estado
do card.
