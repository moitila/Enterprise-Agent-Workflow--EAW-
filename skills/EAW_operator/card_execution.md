# SKILL: eaw_next_execution_v3

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

3. Rodar:
   ./scripts/eaw next <CARD_ID>

4. Localizar o prompt gerado da fase atual em:
   $OUT_DIR/<CARD_ID>/prompts/

5. Ler o prompt da fase atual

6. Ler `phase.skills` do YAML da fase atual (ver Skill Routing)

7. Criar explicitamente um agente isolado para a fase atual, equipando-o com:
   - o prompt integral da fase
   - as skills declaradas em `phase.skills` (+ `workspace` sempre)
   - o contexto de `repos.conf` do workspace
   - a skill `workspace.md` como contexto operacional obrigatorio do subagente
   - quando existirem, os contratos soberanos do card: `00_scope.lock.md`, allowlist de escrita, `Out of Scope` e `10_change_plan.md`

8. Executar o prompt usando esse agente isolado, e nao no contexto do orquestrador

9. Apos concluir a execucao da fase, chamar novamente:
   ./scripts/eaw next <CARD_ID>

10. Se o `next` avancar:
   - seguir para a próxima fase

11. Se o `next` nao avancar:
   - considerar a fase não concluída
   - reportar bloqueio do runtime
   - não forçar avanço manual

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

Ao spawnar/delegar um agente de fase, o operador deve repassar explicitamente o contexto minimo abaixo.
O prompt da fase sozinho nao basta.

### Sempre obrigatorio

- skill `workspace.md`
- `repos.conf` ativo do workspace
- `RUNTIME_ROOT`, `EAW_WORKDIR`, `OUT_DIR` e `CARD_DIR` da execucao corrente
- prompt integral da fase atual

### Obrigatorio quando existir no card

- `00_scope.lock.md`
- `10_change_plan.md`
- allowlist de escrita explicita
- `Out of Scope`
- `WRITE_ALLOWLIST` ou write set declarado no prompt/runtime

### Hierarquia de autoridade que o subagente deve obedecer

1. `repos.conf` para papeis de repositorio (`target` vs `infra`)
2. `RUNTIME_ROOT`, `OUT_DIR`, `CARD_DIR` e limites operacionais do runtime atual
3. `00_scope.lock.md`, allowlist e `Out of Scope`
4. `10_change_plan.md`
5. prompt da fase

Se houver conflito entre prompt/plano e `scope lock`/allowlist:

- o subagente deve parar
- registrar bloqueio
- devolver controle ao operador
- nunca improvisar mudando repo alvo, write set ou superficie de validacao

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

## Operational Traps (learned)

Estas armadilhas foram identificadas em execuções reais e devem ser conhecidas pelo executor:

- `repos.conf` deve ser injetado no contexto do prompt da fase; se ausente, o agente isolado vai inventar caminhos de repositório
- `workspace.md` deve ser injetado no subagente junto do prompt; sem isso, o agente tende a misturar `infra` e `target`
- Se `scope lock` e validacao tecnica apontarem para repositorios diferentes, isso e bloqueio estrutural do card, nao decisao local do executor
- Artefatos vazios (0 bytes ou contendo apenas template/scaffold) não devem passar phase completion; se o runtime aceitar, registrar como bug do runtime
- Erros de `awk`/`sed` nos scripts do runtime podem ser silenciosos; verificar exit codes após cada comando do runtime
- Quando CI falha por dependência não publicada (ex: classes do framework não disponíveis no maven), classificar como "expected dependency gap" e não como regressão
- Cards multi-repo exigem ordem explícita de merge; nunca assumir merge paralelo sem verificar o grafo de dependências
- Se o prompt da fase referencia repos que não estão em `repos.conf`, o agente isolado deve falhar, não improvisar

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
