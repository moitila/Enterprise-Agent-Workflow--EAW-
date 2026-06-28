{{RUNTIME_ENVIRONMENT}}
<!-- REPO_KEY_RESOLUTION: o placeholder <repo_key> refere-se ao nome (campo 1 de repos.conf name|path|role)
     do repositorio com role=target injetado pelo runtime via {{RUNTIME_ENVIRONMENT}} no bloco TARGET_REPOSITORIES.
     O executor deve ler TARGET_REPOSITORIES do prompt renderizado, identificar o repo com role=target
     e usar seu nome como valor de <repo_key> em todos os paths $EAW_WORKDIR/context_sources/onboarding/<repo_key>/.
     Exemplo: se TARGET_REPOSITORIES contem "eaw => /path/to/eaw", entao <repo_key>=eaw. -->

## OBJETIVO

Analisar os artefatos de onboarding publicados para o repositório alvo e produzir um `drift_report.md`
estruturado, classificando cada artefato por severidade de drift. Quando nenhum drift for detectado,
emitir `20_handoff.json` com o código `NO_DRIFT_DETECTED` para acionar o skip da fase `patch_onboarding`.

## INSUMOS OBRIGATÓRIOS

1. `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/INDEX.md` — lista canônica de artefatos publicados
2. `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/provenance.md` — data e card da última geração
3. Repositório alvo — leitura em modo read-only
4. `$CARD_DIR/intake/pedido.md` (quando existir) — declaração do operador sobre qual repo é alvo do refresh; usar para confirmar ou corrigir o `<repo_key>` derivado de `TARGET_REPOSITORIES`

## ALGORITMO DE EXECUÇÃO

### Passo 1 — Validar repo alvo e ler `INDEX.md` e `provenance.md`

**1a. Confirmar `<repo_key>`:**

- Derivar `<repo_key>` do bloco `TARGET_REPOSITORIES` no `RUNTIME_ENVIRONMENT` deste prompt
- Se `$CARD_DIR/intake/pedido.md` existir: ler o arquivo e verificar se o repo mencionado corresponde ao `<repo_key>` derivado
  - Se divergirem (ex: `pedido.md` menciona `/home/user/dev/emr-tasy-plsql` mas `TARGET_REPOSITORIES` injeta `eaw`): usar o path de `pedido.md` para derivar o `<repo_key>` correto (último segmento do path declarado); registrar a divergência como aviso no `drift_report.md`
- Verificar `$EAW_WORKDIR/config/repos.conf`: contar quantos repos têm `role=target`
  - Se houver mais de um `target`: emitir aviso no `drift_report.md` na seção `## Advertências` — "repos.conf contém N targets; runtime pode ter injetado repo incorreto; repo analisado: `<repo_key>` (derivado de `pedido.md`/`TARGET_REPOSITORIES`)"

**1b. Ler artefatos de onboarding:**

- Abrir `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/INDEX.md`
- Listar todos os artefatos declarados
- Ler `provenance.md` para extrair a data do último onboarding publicado

### Passo 2 — Verificar existência de cada artefato

Para cada artefato listado em `INDEX.md`:
- Executar `test -f $EAW_WORKDIR/context_sources/onboarding/<repo_key>/<artefato>`
- Se ausente: classificar como `MISSING_ARTIFACT`

### Passo 3 — Avaliar staleness dos artefatos presentes

Para cada artefato presente:
- Obter `git log --since=<data_provenance> --oneline -- <paths_relevantes>` no repositório alvo
- Comparar com o conteúdo do artefato (arquitetura, padrões, paths citados)
- Classificar conforme severidade:

| Severidade | Critério | Ação recomendada |
|-----------|---------|-----------------|
| `STALE_MINOR` | Datas antigas; paths e padrões ainda válidos | Patch de `provenance.md` apenas |
| `STALE_MODERATE` | Alguns arquivos desatualizados; estrutura intacta | Patch dos arquivos afetados; atualizar provenance |
| `STALE_MAJOR` | Arquitetura central mudou; padrões inválidos | Re-run de `repo_onboarding` track |
| `MISSING_ARTIFACT` | Arquivo ausente mas esperado | Produzir artefato faltante e adicionar ao provenance |

**Tooling hint:** A classificação de severidade é qualitativa conforme `eaw_onboarding_operator/SKILL.md`
linhas 102–107. Não existem limiares numéricos definidos (W05). Adotar julgamento qualitativo baseado
em evidência lida do repositório alvo. Nunca declarar `STALE_MAJOR` sem evidência lida do código-fonte.

### Passo 4 — Algoritmo determinístico para `repo_ai_context.md`

Executar os seguintes 5 passos em ordem, sem pular:

1. Verificar existência de `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/repo_ai_context.md`
2. Se `repo_ai_context.md` ausente:
   - Verificar presença de fontes IA nativas no repositório alvo:
     - `.github/copilot-instructions.md`
     - `AGENTS.md`
     - `CLAUDE.md`
     - `.cursor/rules`
     - `.windsurfrules`
   - Se **pelo menos uma fonte IA nativa existe** E `repo_ai_context.md` está ausente:
     → Classificar como `MISSING_ARTIFACT` (drift real — arquivo deveria existir)
   - Se **nenhuma fonte IA nativa existe**:
     → Ausência de `repo_ai_context.md` é **correta** — NÃO classificar como drift
3. Se `repo_ai_context.md` presente:
   - Comparar data de `provenance.md` com `git log --since=<data_provenance> -- .github/ AGENTS.md CLAUDE.md .cursor/rules .windsurfrules`
   - Se commits recentes existem nas fontes IA: classificar `repo_ai_context.md` como `STALE_MINOR` ou `STALE_MODERATE` conforme extensão das mudanças
   - Se sem commits recentes: artefato íntegro
4. Registrar resultado no `## Artefatos Analisados` do `drift_report.md`
5. Incluir `repo_ai_context.md` na tabela de `## Classificação de Drift` apenas se classificado como drift

### Passo 5 — Produzir `drift_report.md` e decidir handoff

- Escrever `$CARD_DIR/investigations/drift_report.md` conforme schema obrigatório abaixo
- Se **nenhum drift detectado** em nenhum artefato: emitir `$CARD_DIR/investigations/20_handoff.json` com código `NO_DRIFT_DETECTED`
- Se **qualquer drift detectado**: não emitir `20_handoff.json`; a fase `patch_onboarding` será executada

## SCHEMA OBRIGATÓRIO — `drift_report.md`

O arquivo `drift_report.md` DEVE conter exatamente as 4 seções abaixo, nesta ordem:

```markdown
# drift_report

**Repo analisado:** `<repo_key>` (`<path-do-repo>`)

## Artefatos Analisados

Lista de todos os artefatos verificados com path completo e data do onboarding publicado conforme `provenance.md`.

| Artefato | Path | Data do onboarding publicado | Resultado |
|---------|------|------------------------------|-----------|
| <nome> | <path> | <data> | íntegro / drift detectado / ausente |

## Classificação de Drift

Tabela de artefatos com drift confirmado ou ausência inesperada.

| Artefato | Severidade | Evidência | Ação recomendada |
|---------|-----------|-----------|-----------------|
| <nome> | STALE_MINOR / STALE_MODERATE / STALE_MAJOR / MISSING_ARTIFACT | <evidência objetiva> | <ação> |

## Artefatos sem Drift

Lista de artefatos classificados como íntegros, com justificativa para cada um.

| Artefato | Justificativa |
|---------|--------------|
| <nome> | <por que está íntegro> |

## Conclusão e Handoff Code

Decisão final sobre o estado geral do onboarding.

**Total de artefatos analisados:** <N>
**Com drift:** <N>
**Íntegros:** <N>
**Handoff code:** `NO_DRIFT_DETECTED` (se sem drift) | `<vazio>` (se drift detectado — patch_onboarding será executado)
```

**Regras de preenchimento:**
- Nenhuma seção pode ser omitida, mesmo que vazia (ex: `## Classificação de Drift` com tabela vazia quando sem drift)
- `## Artefatos sem Drift` deve listar todos os artefatos íntegros com justificativa — nunca deixar em branco
- A seção `## Conclusão e Handoff Code` determina se `20_handoff.json` é emitido

## SCHEMA DO `20_handoff.json` — Emitir apenas quando sem drift

Quando todos os artefatos estiverem íntegros, escrever `$CARD_DIR/investigations/20_handoff.json`:

```json
{"from_phase":"detect_drift","status":"completed","messages":[],"codes":["NO_DRIFT_DETECTED"]}
```

**Regras do formato:**
- Formato compacto sem espaços após `:` e `,` — o parser usa regex
- Campos obrigatórios: `from_phase`, `status`, `messages`, `codes`
- `from_phase` deve ser exatamente `"detect_drift"`
- `codes` deve conter `["NO_DRIFT_DETECTED"]` apenas quando sem drift; caso contrário emitir `codes: []` OU não emitir `20_handoff.json`
- `messages` deve ser array (pode ser vazio `[]`)

Quando drift detectado: **não emitir `20_handoff.json`**. O runtime avançará automaticamente para `patch_onboarding`.

## WRITE SCOPE

- Escrever **exclusivamente** em `$CARD_DIR/investigations/`:
  - `$CARD_DIR/investigations/drift_report.md` (obrigatório)
  - `$CARD_DIR/investigations/20_handoff.json` (apenas quando `NO_DRIFT_DETECTED`)
- Nunca escrever no repositório alvo
- Nunca escrever fora de `$CARD_DIR/`

## READ SCOPE

- `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` — leitura completa dos artefatos publicados
- Repositório alvo (`TARGET_REPOS`) — leitura em read-only para evidência de drift
- `$CARD_DIR/intake/pedido.md` (quando existir) — leitura obrigatória para confirmar repo alvo
- `$EAW_WORKDIR/config/repos.conf` — leitura para contar targets e detectar ambiguidade
- `$CARD_DIR/` — leitura de contexto do card

## GUARDRAILS

- Nunca classificar drift sem ler o artefato e o código-fonte relevante
- Nunca declarar `STALE_MAJOR` sem evidência lida do repositório alvo
- Nunca emitir `NO_DRIFT_DETECTED` quando qualquer drift existir
- Nunca omitir `repo_ai_context.md` do algoritmo de verificação
- Nunca inventar paths em `## Artefatos Analisados` que não existam em `INDEX.md`
- Não classificar ausência de `repo_ai_context.md` como drift quando não existem fontes IA nativas no repositório alvo
