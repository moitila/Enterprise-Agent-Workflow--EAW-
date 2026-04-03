# Dynamic Context Contract — deterministic_baseline_v1

## Identificação do Baseline

**Nome do contrato:** `deterministic_baseline_v1`

**Objetivo operacional:** definir, sem ambiguidade, as entradas, saídas, limites, algoritmo, pipeline e fronteiras semânticas do coletor de contexto dinâmico basal determinístico, de modo que o card 583 possa ser implementado sem decisões adicionais abertas, e que execuções repetidas sobre o mesmo estado de repositório produzam exatamente os mesmos artefatos.

**Caminho de saída:** `out/<CARD>/context/dynamic/`

**Dependência de materialização:** `dynamic_context_template` requer a presença do artefato em `out/<CARD>/context/dynamic/` antes da injeção no prompt. Contexto não materializado não pode ser injetado. O enforcement já está presente em `docs/WORKFLOW_YAML_CONTRACT.md` e em `scripts/eaw_core.sh` e permanece fora de escopo de alteração nesta iteração.

**Precedência de consumo:** quando o contexto dinâmico estiver materializado em `out/<CARD>/context/dynamic/`, essa superfície é a fonte soberana para consumo em prompt. Fontes de coleta, publicação ou preparação fora do card não substituem o artefato materializado no momento da injeção.

---

## Entradas

O baseline opera sobre três classes de entrada, todas tratadas deterministicamente:

### 1. Ingest do card

- Origem: arquivos textuais presentes em `out/<CARD>/ingest/`, lidos em ordem determinística por path.
- Tipos priorizados: `.md`, `.txt`, `.yaml`, `.yml`, `.json`.
- Exclusão obrigatória: arquivos binários e arquivos minificados.
- Limite agregado de leitura aplicado ao conjunto total antes do processamento de tokens.

### 2. Repositório(s) alvo

- Arquivos do repositório alvo declarado no card, lidos conforme necessário durante a fase de coleta de candidatos.
- Leitura restrita a arquivos textuais não excluídos pelo bloco de exclusões obrigatórias.

### 3. Sinais de runtime

- `git diff --name-only`: arquivos alterados desde o commit de referência.
- `git status --porcelain`: arquivos com estado não rastreado ou modificado no working tree.

---

## Definição de Token

Um **token** é qualquer um dos seguintes elementos extraídos do ingest do card:

- Path explícito mencionado no ingest.
- Identificador técnico (nome de variável, constante, função, método, tipo).
- Nome de classe ou símbolo.
- Palavra-chave técnica relevante para o domínio do card.
- Termo relevante extraído do título ou da descrição do card.

Regras de normalização obrigatórias:

- Stopwords são ignoradas (termos sem valor técnico discriminatório).
- Termos abaixo do comprimento mínimo contratual são ignorados.
- Tokens são deduplicados antes da busca.
- Tokens são ordenados estavelmente antes da busca (ordenação determinística).

---

## Saídas Obrigatórias

O baseline materializa os seguintes artefatos em `out/<CARD>/context/dynamic/`:

### `00_scope_manifest.md` — obrigatório

Conteúdo mínimo:

- Identificador do baseline (`deterministic_baseline_v1`).
- Lista dos tokens extraídos após normalização e deduplicação.
- Lista dos arquivos explícitos coletados.
- Lista dos arquivos do delta (`git diff` e `git status`).
- Parâmetros de execução aplicados (limites efetivos).
- Registro de quaisquer truncamentos aplicados.

### `20_candidate_files.txt` — obrigatório

Formato: uma linha por arquivo candidato selecionado, com path relativo ao repositório alvo, ordenado por `score desc` e, em caso de empate, por `path asc`. Cada linha contém o path e o score calculado.

### `30_target_snippets.md` — obrigatório

Formato: blocos de snippet por arquivo, contendo path, número de linha inicial, número de linha final e conteúdo do trecho. Ordenação: mesma ordem de `20_candidate_files.txt`. Cada snippet respeita o limite de `max_snippets` total.

### `40_warnings.md` — opcional

Presente apenas quando houver truncamento, candidatos descartados por limite ou qualquer desvio registrável do comportamento esperado. Conteúdo: descrição objetiva do evento, limite que foi atingido e ação tomada.

### Regra de reuse/refresh

- O baseline é gerado **uma vez** após a conclusão do ingest do card.
- O resultado gerado é **reutilizado nas fases seguintes** sem regeneração.
- O baseline é **regenerado** apenas nas seguintes condições:
  1. O conteúdo de `out/<CARD>/ingest/` mudar.
  2. O estado do repositório alvo mudar de forma relevante para o card.
  3. O usuário solicitar refresh explicitamente.

### Exclusões obrigatórias fixas

Os seguintes caminhos e tipos são excluídos em todas as etapas de coleta, sem exceção:

- `node_modules/`
- `dist/`
- `build/`
- `target/`
- `.git/`
- Arquivos binários (qualquer arquivo não decodificável como texto UTF-8).
- Arquivos minificados (arquivos com linhas excessivamente longas características de minificação).

Extensões futuras de exclusão são configuráveis sem afrouxar o núcleo determinístico obrigatório acima.

---

## Limites Determinísticos

Todos os limites abaixo são obrigatórios e aplicados em toda execução do baseline:

| Parâmetro               | Valor padrão |
|-------------------------|-------------|
| `max_tokens_extraidos`  | 30          |
| `max_hits_por_token`    | 20          |
| `max_arquivos_candidatos` | 50        |
| `max_snippets`          | 10          |
| `max_bytes_total`       | 200 KB por card |

### Aplicação de `max_bytes_total`

- O limite `max_bytes_total` aplica-se à **soma agregada** de todos os artefatos produzidos em `out/<CARD>/context/dynamic/`.
- A materialização é interrompida ao atingir o teto agregado.
- Snippets em andamento são truncados no ponto de interrupção.
- O truncamento é registrado obrigatoriamente em `40_warnings.md`.

### Regra de truncamento auditável

Qualquer truncamento aplicado durante a execução — por `max_snippets`, `max_arquivos_candidatos`, `max_hits_por_token`, `max_bytes_total` ou `max_tokens_extraidos` — deve ser registrado em `40_warnings.md` com:

- O limite atingido.
- A contagem de itens descartados.
- O ponto de interrupção (arquivo ou token).

---

## Pipeline Obrigatória

A pipeline é executada na ordem fixa abaixo, sem variação entre execuções:

1. **Extrair tokens do ingest** — varrer `out/<CARD>/ingest/` e coletar tokens brutos conforme a definição da seção Entradas.
2. **Normalizar tokens** — remover stopwords, descartar termos abaixo do comprimento mínimo contratual, converter para forma canônica.
3. **Deduplicar tokens** — eliminar duplicatas após normalização.
4. **Ordenar tokens estavelmente** — aplicar ordenação determinística ao conjunto deduplicado.
5. **Coletar arquivos explícitos** — identificar paths mencionados explicitamente no ingest e adicioná-los à lista de candidatos com marcação de origem.
6. **Coletar delta** — executar `git diff --name-only` e `git status --porcelain` para adicionar arquivos com mudanças recentes à lista de candidatos com marcação de origem.
7. **Executar `rg` limitado** — buscar cada token no repositório alvo com limite de `max_hits_por_token`, excluindo os caminhos da lista de exclusões obrigatórias.
8. **Consolidar candidatos** — unir resultados de coleta explícita, delta e busca por token, respeitando `max_arquivos_candidatos`.
9. **Aplicar score** — calcular score determinístico para cada candidato conforme algoritmo da seção seguinte.
10. **Selecionar top N** — ordenar por `score desc`, desempate por `path asc`, selecionar até `max_arquivos_candidatos`.
11. **Gerar snippets** — extrair trechos relevantes dos arquivos selecionados, respeitando `max_snippets` total e `max_bytes_total` agregado.

---

## Algoritmo de Score Determinístico

O score de cada arquivo candidato é calculado pela soma dos pesos aplicáveis:

| Critério                              | Peso  |
|---------------------------------------|-------|
| Path explicitamente mencionado no ingest | +4 |
| Arquivo presente no delta (`git diff` ou `git status`) | +3 |
| Match exato de token no conteúdo do arquivo | +2 por token, até o limite de `max_hits_por_token` |
| Arquivo no mesmo diretório de um arquivo explícito do ingest | +1 |
| Arquivo de teste relacionado ao candidato principal | +1 |
| Arquivo em diretório excluído pelas exclusões obrigatórias | −10 (descarte efetivo) |

### Desempate determinístico

- Critério primário: `score desc` (maior score primeiro).
- Critério de desempate: `path asc` (ordem lexicográfica crescente do path relativo).

A ordenação é aplicada de forma estável, garantindo que execuções com o mesmo estado de repositório produzam a mesma sequência de candidatos.

---

## Fronteiras Semânticas

O `dynamic_context` **seleciona**, **delimita** e **organiza** sinais do repositório para uso nas fases de engenharia do card.

O `dynamic_context` **não**:

- interpreta evidências.
- conclui sobre o problema ou a solução.
- gera hipóteses.
- substitui findings ou análises das fases de investigação.
- introduz julgamento analítico de qualquer natureza.

Esta fronteira é inviolável. Qualquer formulação do conteúdo de `out/<CARD>/context/dynamic/` que extrapole seleção, delimitação e organização de sinais constitui violação do contrato.

---

## Suficiência para o Card 583

Este contrato é considerado suficiente para implementar o card 583 quando todas as seguintes condições estiverem satisfeitas:

- **C1** — nome do baseline `deterministic_baseline_v1` está fechado e identificado.
- **C2** — entradas (ingest, repositório alvo, sinais de runtime) estão definidas sem ambiguidade.
- **C3** — definição de token e regras de normalização estão fechadas.
- **C4** — artefatos de saída obrigatórios (`00_scope_manifest.md`, `20_candidate_files.txt`, `30_target_snippets.md`) e seus formatos estão especificados.
- **C5** — regras de reuse/refresh e exclusões obrigatórias estão fixadas.
- **C6** — todos os limites determinísticos e a regra de truncamento auditável estão fechados.
- **C7** — pipeline obrigatória em ordem fixa está especificada.
- **C8** — algoritmo de score com desempate `score desc` e `path asc` está fechado.
- **C9** — fronteiras semânticas de `dynamic_context` estão explícitas.
