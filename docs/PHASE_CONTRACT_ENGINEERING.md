# Modelo Conceitual Formal

## Phase Contract Engineering for AI

## 1. Objetos Fundamentais

### 1.1 Espaco de trabalho

`Workspace W`: contexto isolado de execucao, incluindo paths, repositorios, configuracao e ferramentas.

`State S`: estado observavel do workspace, incluindo conteudo de arquivos, hashes, metadados e logs.

Formalmente:

```text
S = snapshot(W)
```

Um snapshot e funcao do filesystem mais os metadados relevantes.

### 1.2 Card

`Card C`: unidade de trabalho, como `feature`, `bug` ou `spike`.

Possui:

- `id(C)` por exemplo `506`
- `type(C)`
- `title(C)`
- `track(C)` indicando qual trilha governa a execucao
- `artifacts(C)` como conjunto de artefatos produzidos

### 1.3 Track

`Track T` define o programa do workflow.

Formalmente:

```text
T = (P, order, templates, prompts, gates, policies)
```

Onde:

- `P`: conjunto de fases
- `order`: relacao de precedencia, DAG ou lista
- `templates`: scaffold exigido por fase
- `prompts`: prompt fixo, ou ID, por fase
- `gates`: validacoes por fase
- `policies`: regras globais, como allowlist, idempotencia e proveniencia

### 1.4 Phase

`Phase p ∈ P`: etapa formal do workflow.

Cada fase possui um `Contrato de Fase K_p`.

## 2. Contrato de Fase

Um contrato de fase e um tipo formal para uma execucao.

Definicao:

```text
K_p = (pre, inputs, outputs, invariants, post, forbidden)
```

### 2.1 `pre(S, C, T) -> {true,false}`

Pre-condicoes.

Exemplos:

- estou no root correto
- arquivos do card existem
- `scope.lock` valido

### 2.2 `inputs(C, S)`

Conjunto de artefatos ou arquivos permitidos para leitura que alimentam a fase.

### 2.3 `outputs(C)`

Conjunto de artefatos que a fase pode produzir ou alterar.

### 2.4 `invariants(S_before, S_after, exec_log) -> {true,false}`

Invariantes que devem se manter.

Exemplos:

- nunca escrever fora da allowlist
- sempre registrar provenance

### 2.5 `post(S_after, C, T) -> {true,false}`

Pos-condicoes.

Exemplos:

- arquivo obrigatorio existe
- contem substrings esperadas
- estrutura valida

### 2.6 `forbidden`

Lista explicita do que e proibido.

Exemplos:

- nao alterar codigo
- nao commitar
- nao criar hipoteses na fase Findings

### 2.7 Essencia

O contrato e verificavel. Nao e boa pratica; e gate.

## 3. Execucao como Transicao de Estado

Uma execucao de fase e uma transicao:

```text
run(p, C, T, S) -> (S', A, L)
```

Onde:

- `S'`: novo estado do workspace
- `A`: conjunto de artefatos gerados ou alterados
- `L`: log de execucao com comandos, hashes e checks

Validade:

```text
valid(p, C, T, S, S', A, L) := pre ∧ invariants ∧ post
```

Se `valid` falhar, a execucao deve ser abortada ou marcada como falha auditavel.

## 4. Provenance como Primeiro Cidadao

Cada artefato `a ∈ A` deve carregar um registro de proveniencia:

```text
prov(a) = (
  prompt_id,
  inputs_hashes,
  tool_version,
  track_id,
  phase_id,
  timestamp,
  runner_env_hash
)
```

Regra forte:

### P1. No Artifact Without Provenance

```text
∀ a gerado: prov(a) existe e e completo
```

Isto diferencia um agent framework de uma engenharia governada.

## 5. Determinismo

O determinismo pode ser formalizado em camadas.

### D0. Determinismo Estrutural

Mesmos inputs implicam mesma estrutura de outputs, incluindo arquivos, paths e campos obrigatorios.

Verificacao:

- templates
- gates
- checks

### D1. Determinismo de Conteudo Parcial

Mesmos inputs implicam conteudo equivalente sob uma normalizacao `N(·)`.

```text
N(output_round_1) == N(output_round_2)
```

Isso permite variacao controlada em texto livre, mantendo estaveis headers, secoes e IDs.

### D2. Determinismo Reprodutivel

Mesmos inputs, mesma toolchain e mesma versao do modelo implicam o mesmo output.

Esse nivel e mais dificil em LLMs. Em geral, nao se promete; mede-se o drift.

## 6. Drift e Auditoria como Propriedades do Sistema

### 6.1 Drift de Prompt

Defina `prompt_hash(p)`.

Regra `Dp1`: toda execucao deve registrar o `prompt_hash(p)` usado.

Se `prompt_hash(p)` mudar sem bump de versao, houve drift silencioso.

### 6.2 Drift de Track

Defina `track_hash(T)`.

O mesmo principio vale para a trilha governante.

## 7. Seguranca Operacional

Defina:

- `WL`: write allowlist
- `RL`: read allowlist, opcional

### S1. Write Confinement

```text
writes(exec) ⊆ WL(C, p, T)
```

### S2. Non-Destructive by Default

Sem aprovacao explicita, alteracoes em areas core sao proibidas.

Isso torna a execucao confinada e auditavel, o que e essencial para produto.

### S3. Read Confinement

Regra formal:

```text
reads(exec) ⊆ RL(C, p, T)
```

**Schema de `RL` / `read_sources`:**

- Tipo: lista de paths absolutos (`array<string>`)
- Cardinalidade: 0..N (campo opcional; ausência equivale a `[]`)
- Default: `[]` (zero fontes declaradas; compatibilidade retroativa preservada)

**Validações obrigatórias (por path declarado em `read_sources`):**

1. **Tipo/cardinalidade**: campo é lista de strings; ausência tratada como `[]`.
2. **Pertencimento a `$OUT_DIR`**: cada path deve satisfazer `[[ "$p" == "$OUT_DIR"/* ]]`; path fora de `OUT_DIR` é rejeitado.
3. **Existência**: `test -f "$p"` deve retornar exit 0; path inexistente é rejeitado.
4. **Canonicalização**: `canonicalize_scope_path "$p"` deve ser chamado antes de qualquer uso; path não canonicalizável é rejeitado com erro determinístico.
5. **Rejeição de traversal**: qualquer path contendo `../` (pré ou pós-canonicalização) é rejeitado — maior gap operacional identificado em F-04.
6. **Rejeição de fonte não declarada**: o executor não pode ler um path que não esteja em `RL(C, p, T)` sem violar este invariante.

**Política de symlink:**

`canonicalize_scope_path` depende de `realpath -m` para resolver symlinks. O fallback de resolução de path em `lib.sh:95–124` não resolve symlinks — esta é uma limitação documentada: `realpath` é um requisito de ambiente para enforcement completo do invariante. Em ambientes sem `realpath` nativo (ex.: macOS com PATH mínimo), o fallback é `readlink -f`; se nenhum mecanismo estiver disponível, a resolução é omitida e a lacuna deve ser tratada como risco operacional, não como falha silenciosa.

#### Enforcement runtime

A funcao `assert_read_scope` em `scripts/lib.sh` implementa o invariante formal
`reads(exec) ⊆ RL(C, p, T)` declarado nesta secao.

Assinatura: `assert_read_scope phase command_name source_path [allowed_path...]`

- Exit code 97 com mensagem `READ_SCOPE_VIOLATION: phase=<p> command=<c> blocked_path=<path>`
  quando `source_path` esta fora do allowlist.
- Exit code 0 quando `source_path` pertence a `OUT_DIR` ou a um dos `allowed_path` declarados.
- Campo `read_sources` no JSONL do journal e emitido condicionalmente (omitido quando
  ausente — nao `null`).

**Representação no prompt:**

Quando `read_sources` for não-vazio, o runtime injeta a seção `READ_SOURCES` no bloco `RUNTIME_ENVIRONMENT` do prompt da fase:

```
READ_SOURCES:
- /path/to/authorized/source1
- /path/to/authorized/source2
```

Ausência de `read_sources` (ou lista vazia) implica ausência da seção `READ_SOURCES` no bloco — comportamento análogo ao campo `WRITE_ALLOWLIST`.

## 8. Tracks Configuraveis sem Perder Formalismo

Uma track configuravel nao e livre; e um programa validado.

Definicao:

```text
validate_track(T) -> {true,false}
```
