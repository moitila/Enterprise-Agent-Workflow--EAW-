{{RUNTIME_ENVIRONMENT}}

<!-- REPO_KEY_RESOLUTION: TARGET_REPOSITORIES lista TODOS os repos target do workspace — é contexto
     de workspace, não escopo do card. Para derivar <repo_key> nesta fase:
     1. Campo "**Repo analisado:**" no cabeçalho de drift_report.md — fonte mais confiável
     2. Arquivos em $CARD_DIR/intake/ — declaração original do operador
     3. Confirmar que o repo resolvido existe em TARGET_REPOSITORIES
     4. Se ainda ambiguo: parar e reportar ao operador; nunca inferir -->

## OBJETIVO

Aplicar patches cirúrgicos nos artefatos de onboarding identificados como desatualizados ou ausentes
em `drift_report.md`. Usar `drift_report.md` como única fonte de autoridade para decidir quais artefatos
atualizar. Produzir `patch_notes.md` documentando cada alteração realizada.

## INSUMOS OBRIGATÓRIOS

1. `$CARD_DIR/intake/` — ler todos os arquivos presentes antes de qualquer outra ação; confirmam o escopo e o repo alvo declarados pelo operador
2. `$CARD_DIR/investigations/drift_report.md` — autoridade única sobre quais artefatos têm drift
3. `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` — artefatos publicados a serem atualizados
4. Repositório alvo — leitura em read-only para evidência de mudanças

## ALGORITMO DE EXECUÇÃO

### Passo 1 — Identificar o repo alvo e ler `drift_report.md`

**1a. Derivar `<repo_key>` a partir dos artefatos já criados no card:**

- Ler `$CARD_DIR/investigations/drift_report.md` campo `**Repo analisado:**` no cabeçalho — fonte primária (artefato produzido pela fase anterior)
- Se não presente: ler todos os arquivos em `$CARD_DIR/intake/` — declaração original do operador
- Confirmar que o repo resolvido existe em `TARGET_REPOSITORIES` do `RUNTIME_ENVIRONMENT`
- Se ainda ambíguo: **parar e reportar ao operador; nunca inferir**

> `TARGET_REPOSITORIES` lista todos os repos target do workspace — um workspace pode ter 20 repos. O `drift_report.md` e o `intake/` definem qual é o escopo deste card.

**1b. Ler `drift_report.md`:**

- Extrair a tabela `## Classificação de Drift` — esta é a única lista autoritativa de artefatos a atualizar
- Nunca atualizar artefatos ausentes da tabela de `## Classificação de Drift`
- Verificar se algum artefato tem severidade `STALE_MAJOR`:
  - Se sim: **não aplicar patch** para esse artefato — registrar em `## Advertências` do `patch_notes.md` com instrução de re-run de `repo_onboarding`

### Passo 2 — Aplicar patches cirúrgicos (apenas `STALE_MINOR`, `STALE_MODERATE`, `MISSING_ARTIFACT`)

Para cada artefato com drift classificado como `STALE_MINOR`, `STALE_MODERATE` ou `MISSING_ARTIFACT`:

1. Ler o arquivo atual antes de escrever:
   - `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/<artefato>`
2. Preservar todas as seções não afetadas pelo drift
3. Atualizar apenas a(s) seção(ões) com drift confirmado em `drift_report.md`
4. Não regenerar o arquivo inteiro a menos que todas as seções sejam stale
5. Para `MISSING_ARTIFACT`: criar o artefato completo e adicioná-lo ao `INDEX.md`

**Para `STALE_MAJOR`: NÃO aplicar patch.** Registrar em `## Advertências` do `patch_notes.md`:
```
STALE_MAJOR detectado em <artefato>: re-run de `repo_onboarding` track é necessário.
Não foi aplicado patch. Ação requerida antes de uso em produção.
```

### Passo 3 — Atualizar `provenance.md`

Para cada artefato atualizado ou criado:
- Adicionar nova entrada ao `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/provenance.md`
- Nunca remover entradas anteriores de `provenance.md`
- Usar o formato de entrada de patch abaixo

**Formato de entrada de patch em `provenance.md`:**

```markdown
## Patch — <CARD_ID>

| Campo | Valor |
|-------|-------|
| **Card** | `<CARD_ID>` |
| **Data** | <YYYY-MM-DD> |
| **Fase** | `patch_onboarding` |
| **Tipo** | `STALE_MINOR` / `STALE_MODERATE` / `MISSING_ARTIFACT` |

**Arquivos alterados:**

| Arquivo | Alteração |
|---------|-----------|
| `<arquivo>` | <breve descrição da mudança> |

**Motivo:** <descrição objetiva do drift detectado conforme drift_report.md>
```

### Passo 4 — Produzir `patch_notes.md`

Escrever `$CARD_DIR/investigations/patch_notes.md` conforme schema obrigatório abaixo.
**Nota:** o arquivo já existe como scaffold (conteúdo placeholder gerado pelo runtime) — substituir inteiramente pelo conteúdo real conforme schema.

## SCHEMA OBRIGATÓRIO — `patch_notes.md`

O arquivo `patch_notes.md` DEVE conter exatamente as 4 seções abaixo, nesta ordem:

```markdown
# patch_notes

## Artefatos Atualizados

Tabela de todos os artefatos que receberam patch nesta execução.

| Artefato | Seção atualizada | Motivo | Data |
|---------|-----------------|--------|------|
| <nome> | <seção> | <motivo conforme drift_report> | <YYYY-MM-DD> |

## Entradas de Provenance Adicionadas

Registro das entradas adicionadas ao `provenance.md` por arquivo atualizado.

| Artefato | Card | Data | Tipo de drift |
|---------|------|------|--------------|
| <nome> | <CARD_ID> | <YYYY-MM-DD> | STALE_MINOR / STALE_MODERATE / MISSING_ARTIFACT |

## Artefatos sem Alteração

Lista de artefatos do `drift_report.md` que não receberam patch nesta execução, com justificativa.

| Artefato | Motivo da não-alteração |
|---------|------------------------|
| <nome> | STALE_MAJOR (re-run requerido) / íntegro conforme drift_report |

## Advertências

Casos especiais que requerem atenção do operador.

- **STALE_MAJOR — `<artefato>`:** Re-run de `repo_onboarding` track é necessário. Patch não aplicado.
- **MISSING_ARTIFACT criado — `<artefato>`:** Arquivo criado do zero; adicionar ao `INDEX.md` se ausente.
```

**Regras de preenchimento:**
- Nenhuma seção pode ser omitida, mesmo que vazia (ex: `## Advertências` sem casos especiais → escrever `(nenhuma)`)
- `## Artefatos sem Alteração` deve listar todos os artefatos íntegros e todos os `STALE_MAJOR` com justificativa
- `## Entradas de Provenance Adicionadas` deve ter exatamente uma linha por arquivo que recebeu entrada de provenance

## WRITE SCOPE

- Escrever **exclusivamente** em:
  - `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` — artefatos de onboarding atualizados
  - `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/provenance.md` — entradas de patch
  - `$CARD_DIR/investigations/patch_notes.md` — artefato de saída desta fase
- Nunca escrever no repositório alvo
- Nunca escrever fora de `context_sources/onboarding/<repo_key>/` nos artefatos de onboarding
- Nunca remover arquivos existentes do onboarding sem declarar em `provenance.md`

## READ SCOPE

- `$CARD_DIR/investigations/drift_report.md` — leitura obrigatória antes de qualquer escrita
- `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` — leitura dos artefatos a serem atualizados
- Repositório alvo (`TARGET_REPOS`) — leitura em read-only para referência de conteúdo atual

## GUARDRAILS

- Nunca aplicar patch em artefato ausente do `## Classificação de Drift` de `drift_report.md`
- Nunca aplicar patch em artefato com severidade `STALE_MAJOR` — sempre instruir re-run de `repo_onboarding`
- Nunca regenerar arquivo inteiro quando apenas seções específicas estão desatualizadas
- Nunca remover entradas anteriores de `provenance.md`
- Nunca escrever no repositório alvo
- Nunca adicionar artefatos ao `INDEX.md` sem criar o artefato correspondente primeiro
- Para `STALE_MAJOR`: registrar em `## Advertências` do `patch_notes.md` — não silenciar
- O `WRITE_ALLOWLIST` do `RUNTIME_ENVIRONMENT` pode listar apenas `$CARD_DIR` — isso é esperado para este track; o WRITE SCOPE declarado no corpo deste prompt é autoritativo; os paths em `context_sources/onboarding/<repo_key>/` estão dentro do escopo permitido desta fase
