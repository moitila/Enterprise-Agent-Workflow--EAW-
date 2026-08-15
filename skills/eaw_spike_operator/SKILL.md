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

### execution.readonly_environment

Declara que a fase acessa banco de dados Oracle somente para leitura (consultas investigativas:
`EXPLAIN PLAN`, leitura de dicionário, análise de planos de execução).

- Disponível em: `findings`, `technical_decision` (track `spike`).
- A restrição é imposta pela credencial de banco configurada no workspace (variável de ambiente
  ou arquivo de configuração). O runtime não valida a restrição — é uma declaração contratual.
- Tentativas de INSERT/UPDATE/DELETE falham com erro de privilégio Oracle, não erro de EAW.
- CA-2 de BL-04: verificável por tentativa de INSERT que deve falhar com `ORA-01031: insufficient privileges`.
- Não confundir com `execution.local_sandbox` (filesystem efêmero): são orthogonais.

### execution.escalated

Declara que a fase pode solicitar ao orquestrador a execução de uma operação que excede
o escopo de autonomia do agente (ex.: DDL, operação com credencial privilegiada, aprovação humana).

- Disponível em: `findings`, `technical_decision` (track `spike`).
- Requer `waiting_when: [WAITING]` na transição da fase em `track.yaml`; sem isso, a capability
  é declarada mas inoperante.
- **Quando usar**: operação necessária para concluir a investigação que o agente não pode executar
  de forma autônoma — acesso privilegiado, operação destrutiva, aprovação humana.
- **Quando NÃO usar**: para qualquer operação dentro do escopo de `execution.local_sandbox`
  (filesystem efêmero) ou `knowledge.read` (leitura de repos). Usar a capability mínima necessária.

**Fluxo do agente:**
1. Identificar que a operação excede o escopo.
2. Produzir `investigations/XX_escalation_request.md` com campos obrigatórios:
   - `## operation` — descrição objetiva
   - `## preconditions` — lista verificável
   - `## risks` — lista com severidade
   - `## expected_result` — o que o agente espera receber
   - `## requested_by` — fase solicitante
   - `## result_injection_path` — path para o orquestrador gravar o resultado
3. Emitir handoff: `{"from_phase":"<fase>","status":"waiting","blocker":"escalation_pending: <operacao>","messages":[],"codes":[]}`.
4. O orquestrador executa, grava em `result_injection_path` e retoma com `completed`.


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

## Campo `read_sources` nas fases spike

### Quando declarar

Declare `read_sources:` em uma fase spike quando o runtime precisar registrar explicitamente
no prompt quais arquivos ou paths essa fase lê durante a investigação. A lista serve de contrato
auditável entre o YAML da fase e o agente executor.

### Formato

`read_sources:` é campo top-level no YAML da fase, com itens de lista indentados:

```yaml
read_sources:
  - scripts/lib.sh
  - tracks/spike/phases/findings.yaml
```

Para fases que ainda não declaram fontes específicas, use lista vazia:

```yaml
read_sources: []
```

### Bloco no prompt renderizado

Quando `read_sources:` contiver ao menos um item (lista não-vazia), o runtime injeta o bloco
`READ_SOURCES:` no `RUNTIME_ENVIRONMENT` do prompt renderizado, imediatamente após
`WRITE_ALLOWLIST:` e antes de `CRITICAL_PATHS:`:

```
READ_SOURCES:
scripts/lib.sh
tracks/spike/phases/findings.yaml
```

Quando `read_sources:` está ausente ou é lista vazia, o bloco `READ_SOURCES:` **não é emitido**
— comportamento retroativamente compatível com fases que não usam o campo.

### assert_read_scope

Antes de ler qualquer arquivo listado em `read_sources`, o agente deve chamar
`assert_read_scope <path>` para validar que o path está dentro do escopo declarado.
Leitura sem `assert_read_scope` é permitida em modo não-enforced, mas viola o contrato.

### Lifecycle para cards existentes

Cards materializados antes da implementação de `read_sources` (ex.: cards em `intake/RUN`
com `completed_phases: []`) **não requerem rematerialização**. O runtime (`cmd_next`) relê
`track.yaml` a cada chamada de `next`. Para que o bloco `READ_SOURCES:` apareça no próximo
prompt renderizado, basta:

1. Adicionar `read_sources:` com os itens desejados ao YAML da fase correspondente.
2. Executar `eaw next <CARD>` normalmente.

Cards que não precisam de `read_sources` não são afetados — campo ausente ou lista vazia
não altera o prompt nem bloqueia avanço de fase.
