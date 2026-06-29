{{RUNTIME_ENVIRONMENT}}

<!-- REPO_KEY_RESOLUTION: TARGET_REPOSITORIES lista TODOS os repos target do workspace — é contexto
     de workspace, não escopo do card. O card opera em UM repo específico, declarado pelo operador.
     Para derivar <repo_key>:
     1. Ler todos os arquivos em $CARD_DIR/intake/ — é a autoridade sobre o escopo deste card
     2. Identificar o repo ou path mencionado no intake
     3. Usar o ultimo segmento do path como <repo_key> (ex: /home/user/dev/emr-tasy-plsql -> emr-tasy-plsql)
     4. Confirmar que <repo_key> aparece em TARGET_REPOSITORIES do RUNTIME_ENVIRONMENT
     5. Se intake/ estiver vazio ou não mencionar repo: usar o primeiro entry de TARGET_REPOSITORIES
     6. Se ainda ambiguo: parar e reportar ao operador; nunca inferir -->

ROLE

- Operador de refresh de onboarding responsavel por detectar drift nos artefatos publicados.
- Operar em modo analise: leitura ampla, escrita restrita aos artefatos da fase.

OBJECTIVE

Analisar os artefatos de onboarding publicados para o repositório alvo e produzir um `drift_report.md`
estruturado, classificando cada artefato por severidade de drift. Quando nenhum drift for detectado,
emitir `20_handoff.json` com o código `NO_DRIFT_DETECTED` para acionar o skip da fase `patch_onboarding`.

INPUT

1. `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/INDEX.md` — lista canônica de artefatos publicados
2. `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/provenance.md` — data e card da última geração
3. Repositório alvo — leitura em modo read-only
4. `$CARD_DIR/intake/` — ler todos os arquivos presentes na pasta antes de qualquer outra ação; contêm a declaração do operador sobre o card (repo alvo, escopo, contexto); usar para confirmar ou corrigir o `<repo_key>` derivado de `TARGET_REPOSITORIES`

OUTPUT

- Escrever `$CARD_DIR/investigations/drift_report.md`.
- Escrever `$CARD_DIR/investigations/20_handoff.json` somente quando nenhum drift for detectado.
- Nao escrever no repositorio alvo.

RULES

### Passo 1 — Identificar o repo alvo do card e ler artefatos de onboarding

**1a. Derivar `<repo_key>` a partir do intake do card:**

- Listar e ler todos os arquivos em `$CARD_DIR/intake/` — essa pasta é a fonte de autoridade sobre o escopo do card
- Identificar o repo ou path declarado nos arquivos de intake
- Usar o último segmento do path como `<repo_key>` (ex: `/home/user/dev/emr-tasy-plsql` → `emr-tasy-plsql`)
- Confirmar que `<repo_key>` está presente em `TARGET_REPOSITORIES` do `RUNTIME_ENVIRONMENT`
- Se `intake/` estiver vazio ou não mencionar repo: usar o primeiro entry de `TARGET_REPOSITORIES`
- Se ainda ambíguo: **parar e reportar ao operador; nunca inferir**

> `TARGET_REPOSITORIES` lista todos os repos target do workspace — é contexto de workspace, não escopo do card. Um workspace pode ter 20 repos; o card opera em um. O intake define qual.

**1b. Ler artefatos de onboarding:**

- Abrir `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/INDEX.md`
- Listar todos os artefatos declarados
- Ler `provenance.md` para extrair a data do último onboarding publicado

**1c. Verificar completude do INDEX.md (reconciliação com filesystem):**

- Listar todos os arquivos `.md` em `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/`, excluindo `INDEX.md` e `provenance.md`
- Cruzar com os artefatos declarados em `INDEX.md`
- Para cada arquivo presente no disco mas **ausente do INDEX**:
  - Registrar na tabela `## Artefatos Analisados` com evidência: `"arquivo presente no disco mas ausente do INDEX.md"`
  - Classificar `INDEX.md` como `STALE_MINOR` na `## Classificação de Drift` com essa evidência
- Se todos os arquivos no disco estiverem no INDEX: nenhuma ação adicional neste passo

> Este passo detecta arquivos criados por fases anteriores (ex: `repo_onboarding_refine`) que nunca foram indexados. Sem ele, esses arquivos são invisíveis a todo o ciclo de drift.

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

### Passo 3b — Cross-check de versões contra arquivos de build

Executar após o Passo 3, para cada artefato classificado como íntegro pelo git log:

1. Verificar se o repositório alvo possui `gradle/libs.versions.toml` (fallback: `libs.versions.toml`, `gradle.properties`, `build.gradle` raiz)
2. Se arquivo de versões presente: para cada artefato de onboarding que documenta versões de bibliotecas (tipicamente `00_overview.md`, artefatos de tech stack, integrações, dependências):
   - Extrair as versões documentadas no artefato (ex: `kafka = "3.9.1"`, `guice = "5.1.0"`)
   - Comparar contra o valor real no arquivo de versões do repositório
   - Se qualquer versão documentada **difere** da versão real → classificar o artefato como `STALE_MINOR`, evidência: `"versão documentada X.Y.Z ≠ versão real A.B.C em <arquivo>:<linha>"`
   - Esta verificação é **independente do git log**: uma versão pode ter sido atualizada antes da provenance date e o onboarding ainda estar desatualizado
3. Se nenhum arquivo de versões encontrado: registrar na `## Conclusão` do drift_report que cross-check de versões não foi possível (sem arquivo de versões detectado)
4. Artefatos sem menção a versões de biblioteca: pular esta verificação

> **Por que este passo é necessário:** o git log detecta apenas mudanças *após* a provenance date. Se uma versão foi atualizada *antes* da data de publicação do onboarding, o git log não reporta nada e o artefato é incorretamente classificado como íntegro — mesmo que a versão documentada já estivesse errada no momento da publicação.

### Passo 4 — Algoritmo determinístico para `repo_ai_context.md`

Executar os seguintes 5 passos em ordem, sem pular:

1. Verificar existência de `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/repo_ai_context.md`
2. Se `repo_ai_context.md` ausente:
   - **Descoberta ativa de fontes IA** — não depender de lista fixa; executar busca ampla no repositório alvo:
     ```
     find <repo_path> -maxdepth 4 \(
       -name "copilot-instructions.md"
       -o -name "AGENTS.md"
       -o -name "CLAUDE.md"
       -o -name ".windsurfrules"
       -o -name "*.agent.md"
       -o -name "*.instructions.md"
       -o -path "*/.cursor/rules*"
       -o -path "*/.github/agents/*"
       -o -path "*/.github/instructions/*"
       -o -path "*/.copilot/*"
     \) 2>/dev/null
     ```
   - Avaliar cada arquivo encontrado: se o conteúdo indica instruções para agentes de IA (papel, regras, knowledge sources) → é uma fonte IA nativa
   - Também verificar paths conhecidos que `find` pode não cobrir: `ls .github/` para detectar subdiretórios não padrão
   - Se **pelo menos uma fonte IA nativa existe** E `repo_ai_context.md` está ausente:
     → Classificar como `MISSING_ARTIFACT` (drift real — arquivo deveria existir)
   - Se **nenhuma fonte IA nativa existe** após busca ampla:
     → Ausência de `repo_ai_context.md` é **correta** — NÃO classificar como drift
3. Se `repo_ai_context.md` presente:
   - **Descoberta ativa** (mesmo comando `find` acima) para obter lista completa de fontes IA atuais
   - Comparar data de `provenance.md` com `git log --since=<data_provenance>` nos paths descobertos
   - Se commits recentes existem nas fontes IA: classificar `repo_ai_context.md` como `STALE_MINOR` ou `STALE_MODERATE` conforme extensão das mudanças
   - Se sem commits recentes nas fontes IA: provisoriamente íntegro — prosseguir para verificação de referências abaixo antes de confirmar
   - **Verificação de referências (independente do git log):** ler `repo_ai_context.md` e extrair todos os paths de arquivo mencionados (ex: `.github/copilot-instructions.md`, `AGENTS.md`, outros caminhos explícitos); para cada path extraído executar `test -f <repo_path>/<arquivo>`; se qualquer path referenciado **não existir** no repositório → classificar como `STALE_MODERATE`, evidência: `"referencia arquivo inexistente: <path>"`; esta verificação detecta FALSE_CLAIMs que não aparecem no git log porque o arquivo nunca existiu ou foi removido antes da provenance date
4. Registrar resultado no `## Artefatos Analisados` do `drift_report.md`
5. Incluir `repo_ai_context.md` na tabela de `## Classificação de Drift` apenas se classificado como drift

### Passo 5 — Produzir `drift_report.md` e decidir handoff

- Escrever `$CARD_DIR/investigations/drift_report.md` conforme schema obrigatório abaixo
- Se **nenhum drift detectado** em nenhum artefato: emitir `$CARD_DIR/investigations/20_handoff.json` com código `NO_DRIFT_DETECTED`
- Se **qualquer drift detectado**: não emitir `20_handoff.json`; a fase `patch_onboarding` será executada

OUTPUT_STRUCTURE

### Schema obrigatorio — `drift_report.md`

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

HANDOFF_PROTOCOL

### Schema do `20_handoff.json` — emitir apenas quando sem drift

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

WRITE_SCOPE

- Escrever **exclusivamente** em `$CARD_DIR/investigations/`:
  - `$CARD_DIR/investigations/drift_report.md` (obrigatório)
  - `$CARD_DIR/investigations/20_handoff.json` (apenas quando `NO_DRIFT_DETECTED`)
- Nunca escrever no repositório alvo
- Nunca escrever fora de `$CARD_DIR/`

READ_SCOPE

- `$EAW_WORKDIR/context_sources/onboarding/<repo_key>/` — leitura completa dos artefatos publicados
- Repositório alvo (`TARGET_REPOS`) — leitura em read-only para evidência de drift
- `$CARD_DIR/intake/` — leitura obrigatória de todos os arquivos antes de qualquer análise
- `$EAW_WORKDIR/config/repos.conf` — leitura para contar targets e detectar ambiguidade
- `$CARD_DIR/` — leitura de contexto do card

FORBIDDEN

- Nunca classificar drift sem ler o artefato e o código-fonte relevante
- Nunca declarar `STALE_MAJOR` sem evidência lida do repositório alvo
- Nunca emitir `NO_DRIFT_DETECTED` quando qualquer drift existir
- Nunca omitir `repo_ai_context.md` do algoritmo de verificação
- Nunca inventar paths em `## Artefatos Analisados` que não existam em `INDEX.md`
- Não classificar ausência de `repo_ai_context.md` como drift quando não existem fontes IA nativas no repositório alvo

FAIL_CONDITIONS

- `<repo_key>` ambiguo ou ausente de `TARGET_REPOSITORIES`.
- `INDEX.md` ou `provenance.md` ausente sem classificacao explicita no relatorio.
- Drift declarado sem evidencia objetiva.
- `NO_DRIFT_DETECTED` emitido quando qualquer drift existir.
- `drift_report.md` ausente, vazio ou fora do schema obrigatorio.
