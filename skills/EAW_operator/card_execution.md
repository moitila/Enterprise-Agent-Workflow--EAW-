# SKILL: eaw_next_execution_v4

## Objective
Executar um card no EAW corretamente usando o comando `next`, respeitando o fluxo por fases e o uso de agentes isolados.

## Mandatory prerequisite

Antes de executar qualquer card, o executor deve conhecer e aplicar a skill `workspace.md`.

- `workspace.md` nao e contexto opcional
- `workspace.md` nao pode ser presumida por memoria do operador
- a descoberta de `EAW_WORKDIR`, `repos.conf`, `RUNTIME_ROOT`, `OUT_DIR` e papeis `target`/`infra` deve seguir explicitamente a skill `workspace.md`
- se o executor nao leu/aplicou `workspace.md` na execucao corrente, ele nao esta autorizado a rodar `next`

## Core rule

- **`EAW_WORKDIR` deve estar exportado antes de qualquer `next`.** Sem isso, o runtime opera em `eaw/out/` (repo tool) em vez do workspace real. Verificar com `echo $EAW_WORKDIR` antes da primeira execução.
- O executor principal deve saber e aplicar `workspace.md` antes da primeira chamada de `next`
- O agente NÃO executa múltiplas fases ao mesmo tempo
- O agente NÃO pula fases
- O agente NÃO valida formalmente a conclusão da fase
- O agente usa o EAW para obter o prompt da fase
- O comando `next` é a autoridade única para validar avanço de fase
- O comando `next` deve ser executado a partir do runtime root validado para o workspace atual
- O runtime root deve ser descoberto pelo ambiente ativo e por `repos.conf`, nunca por nome presumido de repositorio
- O executor principal/orquestrador NAO deve executar diretamente o prompt da fase
- O prompt de cada fase deve ser delegado a um agente separado com contexto isolado
- "Agente isolado" significa: novo agente, sem reutilizar o contexto operacional da fase anterior e sem executar a fase no mesmo contexto do orquestrador
- O uso de agente isolado e obrigatorio, explicito e inegociavel em toda fase
- O executor deve criar o agente isolado por conta propria, sem pedir autorizacao ao usuario e sem esperar confirmacao adicional
- Se a plataforma oferecer mecanismo de subagente, delegacao ou spawn, esse mecanismo deve ser usado de forma explicita para cada fase
- Nao ha excecao por conveniencia, economia de contexto, economia de tokens, pressa, hesitacao operacional ou interpretacao local do executor

## Execution flow

Para executar um card:

1. Ler e aplicar `workspace.md` para descobrir e validar o runtime root do workspace atual

2. Validar `EAW_WORKDIR`, `repos.conf`, papeis `target`/`infra` e `./scripts/eaw` conforme `workspace.md`

2b. Antes de cada `next`, rodar `./scripts/eaw preflight <CARD_ID>`:
   - PASS → prosseguir com `next`
   - FAIL → corrigir as falhas reportadas antes de avançar
   - `preflight` valida o ambiente; `next` avança a fase — não são substitutos

3. Rodar:
   ./scripts/eaw next <CARD_ID>

4. Localizar o prompt renderizado da fase atual em:
   $OUT_DIR/<CARD_ID>/prompts/
   O runtime ja substituiu todos os placeholders (`{{RUNTIME_ENVIRONMENT}}`, `{{TARGET_REPOS}}`,
   `{{EAW_WORKDIR}}`, `{{CARD_DIR}}`, `{{CONTEXT_BLOCK}}`, etc.) — o prompt gerado e autossuficiente.

5. Ler `phase.skills` do YAML da fase atual (ver Skill Routing)

6. Criar explicitamente um agente isolado para a fase atual, equipando-o com:
   - o prompt renderizado da fase (arquivo em `$OUT_DIR/<CARD_ID>/prompts/`)
   - a skill `workspace.md` como regras comportamentais obrigatorias do subagente
   - as skills declaradas em `phase.skills` (+ `workspace` sempre)
   - quando existirem, os contratos soberanos do card que NAO estao inline no prompt:
     `00_scope.lock.md`, `10_change_plan.md`, `Out of Scope`
   NAO reinjetar manualmente `repos.conf`, `RUNTIME_ROOT`, `EAW_WORKDIR`, `OUT_DIR` ou `CARD_DIR`:
   esses valores ja estao no prompt renderizado via `{{RUNTIME_ENVIRONMENT}}` e `{{TARGET_REPOS}}`.

> **Nota histórica (EAW_PATH_ISOLATION):** O isolamento de PATH era gerenciado
> manualmente (passo 6a — salvar variáveis de ambiente do orquestrador antes do spawn)
> até a implementação de EAW_PATH_ISOLATION. O runtime `cmd_next` agora executa
> save/restore automático de `$PATH` via `trap RETURN`. O passo 6a foi removido em 2026-07-13.

7. Executar a fase no agente isolado

8. Ao concluir, solicitar ao agente isolado um relatorio pos-execucao minimo:
   - artefatos produzidos (path + tamanho nao-zero)
   - bloqueios ou falhas encontradas
   - warnings emitidos
   - comportamentos inesperados (ex: PATH corrompido, permissao negada, artefato ausente)
   O orquestrador usa esse relatorio para decidir se chama `next` ou reporta bloqueio.

> **Nota histórica (EAW_PATH_ISOLATION):** O workaround de restaurar PATH manualmente
> antes de cada `next` (passo 8b) foi removido em 2026-07-13. O runtime `cmd_next`
> gerencia save/restore automático de `$PATH` via `trap RETURN` desde EAW_PATH_ISOLATION.

9. Apos receber o relatorio, chamar novamente:
   ./scripts/eaw next <CARD_ID>

10. Se o `next` avancar:
    - seguir para a próxima fase

11. Se o `next` nao avancar:
    - considerar a fase nao concluida
    - cruzar com o relatorio do agente para identificar causa
    - reportar bloqueio ao executor
    - nao forcar avanco manual

### CI Feedback (quando ci_feedback_enabled=true em eaw.conf)
- O prompt renderizado já contém instrução para o agente isolado produzir
  `$EAW_WORKDIR/ci_feedback/<track>/<phase>/feedback_<CARD>.md`
- Ao final do card, o orquestrador pode ler todos os feedbacks da sessão e
  escrever síntese em `$EAW_WORKDIR/ci_feedback/_synthesis/<track>_<phase>.md`
- Consulte `skills/EAW_operator/lessons.md` para classificação e síntese

## Skill Routing

O orquestrador é responsável por equipar cada agente isolado com as skills declaradas na fase.
O prompt da fase não menciona skills — ele fala de artefatos e validações.
As skills necessárias são declaradas no `phase.yaml`, não inferidas pelo orquestrador.

### Declaração no phase.yaml

Cada phase pode declarar quais skills o agente isolado precisa:

```yaml
phase:
  id: post_review
  skills:
    - workspace
    - reviewer
```

O campo `skills` é uma lista de nomes de skills disponíveis no workspace.

### Regras de routing

- O orquestrador lê `phase.skills` do YAML da fase atual
- Se `phase.skills` não estiver declarado, fallback para `[workspace]` apenas
- `workspace` é sempre incluída — se o YAML declarar skills sem `workspace`, o orquestrador adiciona automaticamente
- `workspace` nao e opcional nem decorativa: ela deve ser efetivamente repassada ao subagente como contexto de execucao, e nao apenas presumida pelo operador
- o executor principal tambem deve conhecer `workspace.md`; nao basta repassa-la ao subagente sem aplica-la na orquestracao
- O orquestrador não inventa skills além das declaradas + `workspace`
- O prompt continua sendo a autoridade sobre **o que fazer**; as skills dão ao agente **como fazer**
- O orquestrador não altera o prompt para mencionar skills — as skills são contexto operacional do agente, não conteúdo do prompt
- Se uma skill declarada não existir no workspace, o orquestrador avisa o executor e prossegue sem ela

## Mandatory Delegation Context

O prompt renderizado em `$OUT_DIR/<CARD_ID>/prompts/` ja e autossuficiente para contexto operacional:
o runtime substitui `{{RUNTIME_ENVIRONMENT}}`, `{{TARGET_REPOS}}`, `{{EAW_WORKDIR}}`, `{{CARD_DIR}}`,
`{{CONTEXT_BLOCK}}` e demais placeholders antes de gravar o arquivo.
O orquestrador NAO deve reinjetar manualmente essas informacoes — isso criaria segunda fonte de verdade.

### Sempre obrigatorio ao spawnar o subagente

- prompt renderizado (arquivo em `$OUT_DIR/<CARD_ID>/prompts/`, nao o template original)
- skill `workspace.md` (regras comportamentais: o que nao fazer, como interpretar conflitos, fail-fast)
- skills declaradas em `phase.skills`

### Obrigatorio quando existir no card (nao estao inline no prompt)

- `00_scope.lock.md` — contrato soberano de escrita
- `10_change_plan.md` — plano de mudanca aprovado
- `Out of Scope` — quando declarado separadamente do scope lock

### Hierarquia de autoridade que o subagente deve obedecer

1. `repos.conf` para papeis de repositorio (`target` vs `infra`) — ja injetado via `{{TARGET_REPOS}}`
2. `RUNTIME_ROOT`, `OUT_DIR`, `CARD_DIR` — ja injetados via `{{RUNTIME_ENVIRONMENT}}`
3. `00_scope.lock.md`, allowlist e `Out of Scope`
4. `10_change_plan.md`
5. prompt da fase

Se houver conflito entre prompt/plano e `scope lock`/allowlist:

- o subagente deve parar
- registrar bloqueio
- devolver controle ao operador
- nunca improvisar mudando repo alvo, write set ou superficie de validacao

### Divergência skill vs prompt renderizado
- **Fatos operacionais do card** (EAW_WORKDIR, CARD_DIR, paths, repos): prompt renderizado prevalece
- **Regras comportamentais** (fail-fast, limites de escrita, papéis target/infra): `workspace.md` prevalece
- **Conflito entre dois fatos operacionais**: parar e reportar ao orquestrador — nunca resolver localmente

## Rules

- Cada fase deve ser executada por um agente com contexto isolado
- Cada fase exige spawn/delegacao explicita de um novo agente isolado
- O orquestrador deve validar antes de cada `next` que esta no runtime root correto do workspace atual
- O orquestrador executa apenas o fluxo `next -> localizar prompt -> delegar ao agente isolado -> next`
- O orquestrador nao deve cumprir localmente nenhuma etapa substantiva do prompt da fase
- Se o orquestrador ler o prompt para encaminhamento, isso nao autoriza executar a fase no proprio contexto
- O orquestrador nao deve pedir permissao ao usuario para delegar a fase quando a plataforma suportar agentes
- O orquestrador nao deve bloquear a execucao por receio de custo, latencia, contexto ou preferencia propria quando a skill ja exige agente isolado
- O orquestrador deve repassar ao subagente a skill `workspace.md` e os contratos soberanos do card quando existirem
- O orquestrador deve deixar explicito para o subagente qual repo/papel esta autorizado para escrita na fase atual
- O agente atual NÃO deve:
  - executar múltiplas fases ao mesmo tempo
  - pular fases
  - gerar artefatos fora do prompt da fase
  - decidir manualmente que a fase “passou”
  - implementar validação paralela de avanço

- Nunca assumir que a fase foi executada sem rodar o prompt
- Nunca avançar fase sem executar o agente correspondente
- Nunca substituir a validação do runtime por checagem manual do executor
- Nunca tratar o proprio executor/orquestrador como "agente isolado"
- Nunca escolher o diretorio de execucao do `next` por nome presumido de repositorio
- Nunca executar localmente uma fase que deveria ter sido delegada a agente isolado
- Nunca tratar delegacao como opcional, implicita ou dependente de autorizacao extra do usuario
- Nunca spawnar subagente apenas com o prompt da fase e sem `workspace.md`
- Nunca deixar o subagente inferir `target` vs `infra` por nome de repositorio
- Nunca deixar o subagente escolher repo de escrita diferente do definido por `scope lock`/allowlist
- Nunca aceitar plano ou validacao que aponte para repo diferente da allowlist sem bloquear a execucao
- **Nunca escrever o prompt do subagente manualmente**: o prompt renderizado em `out/<CARD>/prompts/<phase>.md` é o contrato soberano da fase — deve ser passado verbatim ao subagente. Skills e contexto complementar (workspace.md, traps.md) são adicionados ao contexto, nunca substituem nem modificam o conteúdo do prompt renderizado.
- **Fluxo de passagem do prompt**: ler `out/<CARD>/prompts/<phase>.md` de forma mecânica (sem interpretar) e passar o conteúdo bruto ao subagente. Com CI feedback ativo, o subagente valida a qualidade do prompt e reporta em `ci_feedback/` — o orquestrador não precisa pré-validar o conteúdo. **Ler para entender é o erro**: qualquer compreensão do conteúdo habilita reescrita, resumo ou seleção parcial — que são violações.

## Runtime authority

- O comando `./scripts/eaw next <CARD_ID>` é responsável por:
  - validar se os artefatos obrigatórios da fase existem
  - decidir se a fase pode avançar
  - bloquear a transição se a fase não foi concluída corretamente ou se ainda não foi concluida

- O agente executor é responsável apenas por:
  - ler o prompt da fase atual
  - executar a fase
  - produzir os artefatos requeridos pelo prompt
  - devolver o controle ao operador para nova chamada de `next`

- O orquestrador é responsável apenas por:
  - resolver o runtime root correto da execucao corrente
  - rodar `./scripts/eaw next <CARD_ID>`
  - localizar o prompt vigente
  - repassar o prompt a um agente isolado
  - retomar o controle apos a execucao para nova chamada de `next`
  - fazer essa delegacao explicitamente e imediatamente, sem friccao adicional

## Fechamento do card

Ao chamar `./scripts/eaw next <CARD_ID>` na **fase final** de qualquer track, o runtime executa
**AUTO-CLOSE INLINE** sem necessidade de comando separado:

1. Valida os artefatos da fase final (CA3 graceful block).
2. Escreve `phase_completed: true` no state file.
3. Emite evento `track_completed` no `execution_journal.jsonl`.
4. Retorna:
   ```
   CARD <CARD_ID>: <fase_final> marked COMPLETE
   CARD <CARD_ID>: workflow already complete
   ```

`CARD <CARD_ID>: workflow already complete` é a **saída normal de encerramento** — não é erro.

O comportamento é genérico: é determinado pela lógica `current_phase == final_phase` em `cmd_next`,
não por configuração específica do track. Aplica-se a qualquer track cujo fluxo `next` percorra uma
fase final.

**`eaw complete` não é necessário** no fluxo normal. Ele existe como comando standalone de escape
para contextos em que `eaw run` (em vez de `next`) foi usado, ou quando o state file precisou de
correção manual. Em operações normais orquestradas pelo orquestrador, `eaw complete` nunca deve ser
chamado.

**Nota**: nenhuma mensagem `"ERROR: final phase is not marked complete"` é emitida pelo runtime em
nenhuma condição — essa string não existe em `eaw_commands.sh`. Qualquer documentação que a
mencionar está incorreta.

## Anti-patterns

- Rodar `next` múltiplas vezes sem executar o prompt
- Executar lógica manual ao invés de usar o prompt
- Rodar `next` em um diretorio escolhido por nome conhecido, e nao por validacao do ambiente atual
- Executar o prompt no mesmo contexto do agente que orquestra o card
- Usar o agente principal como substituto do agente isolado
- Deixar de criar o agente isolado por cautela, economia de contexto, economia de tokens ou politica local presumida
- Pedir autorizacao ao usuario para usar agente isolado quando a skill ja manda delegar
- Misturar execução de fases
- Reutilizar contexto de fase anterior
- Tentar validar manualmente a conclusão da fase
- Inspecionar artefatos para decidir avanço no lugar do `next`
- Forçar interpretação local de sucesso quando o runtime ainda não avançou
- Spawnar agente isolado sem ler `phase.skills` do YAML
- Inferir skills pelo `phase_role` quando `phase.skills` está declarado
- Mencionar skills dentro do prompt da fase (skills são contexto do agente, não conteúdo do prompt)
- Deixar de incluir `workspace` no agente isolado

### Operational Traps

Ver skill dedicada: `skills/EAW_operator/traps.md`

## Fail-fast

Se:
- o prompt da fase não existir após `next`
- a execução do agente falhar
- o executor nao conseguir criar ou usar agente isolado explicitamente
- após a execução da fase o `next` não avançar

→ parar a execução
→ não forçar progressão manual
→ reportar erro ou bloqueio do runtime
→ não substituir a falta de agente isolado por execução local da fase
