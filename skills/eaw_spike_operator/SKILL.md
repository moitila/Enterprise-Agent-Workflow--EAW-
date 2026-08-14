# Skill: eaw_spike_operator

## Conceito de Spike no EAW

Uma spike é uma investigação time-boxed com um único objetivo: responder UMA pergunta
bloqueante para permitir uma decisão técnica ou de produto.

- A spike NAO implementa solucoes.
- A spike NAO altera codigo, NAO cria branches, NAO faz commits em TARGET_REPOS.
- A spike termina com uma decisao documentada em `30_technical_decision.md`.

## Tres modos de spike (spike_mode)

| Modo | Quando usar | Acesso a repos |
|------|-------------|----------------|
| `repo` | A resposta exige leitura de codigo nos repositorios | Sim — selecao justificada (primary/related) |
| `no_repo` | Investigacao de contratos, prompts ou configuracoes sem leitura de repos | Nao |
| `research` | Investigacao puramente teorica ou documental | Nao |

`spike_mode` e declarado na fase `intake` e determina o comportamento de todas as fases
subsequentes. Fases que nao acessam repos (no_repo/research) sao puladas pelo runtime
via `skip_when` quando aplicavel.

## Hierarquia de artefatos

```
ingest/raw_card_explication.md       <- material bruto do solicitante
investigations/00_spike_intake.md    <- pergunta estruturada + spike_mode
investigations/10_hypotheses.md      <- hipoteses testaveis
investigations/20_findings.md        <- evidencias coletadas
investigations/20_handoff.json       <- codigo de roteamento (SPIKE_NO_REPO, SPIKE_RESEARCH)
investigations/30_technical_decision.md <- recomendacao fundamentada
investigations/40_backlog_or_handoff.md <- backlog e rastreamento do intake
```

## Politica de pesquisa externa

- Consultar somente referencias tecnicas verificaveis: documentacao oficial, RFCs, issues publicas, changelogs.
- Registrar cada fonte consultada em "Fontes externas consultadas" no artefato da fase.
- Time-box sugerido para pesquisa inicial: ~10 minutos antes de formular hipoteses.
- NAO usar fontes nao verificaveis (blogs sem autoria, wikis editaveis, StackOverflow sem referencia oficial).

## Restricoes operacionais do agente spike

- NAO criar hipoteses na fase intake.
- NAO investigar codigo na fase intake.
- NAO propor solucoes na fase findings.
- NAO implementar na fase technical_decision.
- Cada fase produz apenas seus artefatos declarados — nada alem.
- `eaw next` e a unica autoridade para validar avanco de fase.

## Campo capabilities nas fases spike

As fases `findings` e `technical_decision` da track `spike` carregam o campo:

```yaml
capabilities:
  - knowledge.read
  - execution.local_sandbox
```

### knowledge.read

Declara intenção de acesso a TARGET_REPOS em modo leitura. Para o agente executor:

- O bloco `RUNTIME_ENVIRONMENT` do prompt renderizado incluirá `CAPABILITIES_DECLARED: knowledge.read`.
- A declaração é auditável: o runtime emite `capability_warning` no journal para fases que
  acessam TARGET_REPOS sem declarar capabilities.
- A declaração é opt-in: não cria obrigações adicionais além da visibilidade declarada.
- Fases sem o campo (ex.: `intake`, `hypotheses`) mantêm comportamento atual inalterado.

### execution.local_sandbox

Declara que a fase pode criar e usar `$TMPDIR/EAW-[CARD_ID]/` como destino legítimo
para artefatos efêmeros (consultas SQL, dumps temporários, arquivos de análise).

- Disponível em: `findings`, `technical_decision` (track `spike`).
- Requer teardown obrigatório via `trap 'rm -rf "$SANDBOX_PATH"' EXIT` imediatamente após criar o sandbox.
- O isolamento é por CARD_ID: `$TMPDIR/EAW-outro-card/` é bloqueado com `WRITE_SCOPE_VIOLATION` (exit 97).
- Risco residual: `SIGKILL` não executa o trap; artefatos efêmeros persistem até a próxima sessão (impacto BAIXO).

## Emissão de `waiting` vs `completed` nas fases `findings` e `technical_decision`

A fase deve emitir `waiting` no handoff quando a pergunta bloqueante **não pode ser respondida** com as evidências disponíveis na execução corrente:

- Evidência necessária está ausente (dado, acesso, ferramenta inacessível).
- Existe dependência externa não satisfeita (outra equipe, outro card, publicação pendente).
- A investigação identificou ambiguidade que exige resolução antes de uma recomendação fundamentada.

Quando emitir `waiting`:
1. Preencher `blocker` com uma descrição objetiva do que está faltando — frase completa, sem abreviações.
2. Usar o envelope canônico: `{"from_phase":"<fase>","status":"waiting","blocker":"<texto>","messages":[],"codes":[]}`.
3. `blocker` vazio ou ausente causa rejeição pelo runtime.

A fase deve emitir `completed` somente quando a pergunta bloqueante foi respondida com evidência verificada e a decisão pode ser documentada de forma fundamentada.
