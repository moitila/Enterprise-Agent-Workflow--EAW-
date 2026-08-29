# Skill: eaw_implementation_quality

## Objetivo

Auto-validar quality gates antes do handoff do `implementation_executor`. Esta skill é invocada
ao final da fase de implementação, após a escrita do código, e antes de emitir qualquer handoff
`completed`. Ela verifica se o código produzido viola thresholds de qualidade que bloqueiam PRs.

Se checks padrão (ou overrides de repo) detectarem violação, emitir handoff `waiting` com
`blocker` descritivo. Sem violação: emitir `completed` normalmente.

## Localização do Contrato

**Resolver o `repo_key` do card via `repos.conf`:**

```bash
# EAW_WORKDIR é a variável de ambiente já resolvida no prompt
REPOS_CONF="${EAW_WORKDIR}/config/repos.conf"
# repo_key é o nome do repo TARGET declarado em 00_scope.lock.md (campo "resolved_repo_key")
repo_key="<valor de resolved_repo_key do scope.lock>"
OVERRIDE_GLOB="${EAW_WORKDIR}/context_sources/onboarding/${repo_key}/62_*.md"
```

**Regra de resolução:**

1. Se `${EAW_WORKDIR}/context_sources/onboarding/<repo_key>/62_*.md` existir (qualquer arquivo
   correspondendo ao glob), ler o arquivo e aplicar seus thresholds em substituição INTEGRAL
   aos defaults desta skill. Os defaults abaixo ficam inativos para este repo.
2. Se o glob não corresponder a nenhum arquivo, aplicar os Checks Padrão (Defaults) abaixo
   sem erro ou aviso.

## Checks Padrão (Defaults)

Os checks abaixo aplicam-se quando não existe arquivo `62_*.md` para o repo_key resolvido.

---

### Check 1 — @SuppressWarnings

**Objetivo:** Verificar que nenhum arquivo Java escrito nesta implementação contém `@SuppressWarnings`.

**Comando:**
```bash
grep -rn '@SuppressWarnings' <arquivo>.java
```

**Critério:** A saída deve ser vazia (exit code 1 do grep). Qualquer linha retornada indica violação.

**Fallback:** Se `grep` não estiver disponível, inspecionar visualmente cada arquivo Java modificado
e reportar violação se qualquer ocorrência de `@SuppressWarnings` for encontrada no texto.

---

### Check 2 — Excess Function Arguments (> 4 args)

**Objetivo:** Verificar que nenhum método, construtor ou função nos arquivos Java modificados possui
mais de 4 parâmetros.

**Comando:**
```bash
awk '/\(.*,.*,.*,.*,/' <arquivo>.java
```

**Critério:** A saída deve ser vazia. Qualquer linha retornada indica um método com 5+ parâmetros,
configurando violação.

**Fallback declarativo:** Se `awk` não estiver disponível ou produzir resultados ambíguos (lambdas,
anotações com múltiplos atributos), inspecionar manualmente cada assinatura de método/construtor
e contar vírgulas nos parâmetros. Reportar violação se qualquer assinatura tiver > 4 parâmetros.
Varargs e lambdas podem produzir falso-positivo no awk — aplicar julgamento declarativo nesses casos.

---

### Check 3 — String-Heavy Arguments (ratio)

**Objetivo:** Verificar que a proporção de argumentos do tipo `String` no arquivo Java modificado
não excede o limiar padrão.

**Limiar padrão:** < 38% dos argumentos de todas as funções do arquivo devem ser `String`.

**Instrução declarativa:** Este check não possui comando automatizado como primário. O agente deve:
1. Listar todos os métodos/construtores do arquivo Java modificado.
2. Contar o total de argumentos (soma de todos os métodos).
3. Contar quantos são do tipo `String`.
4. Calcular: `(String_count / total_count) * 100`.
5. Se o resultado ≥ 38%, reportar violação com o ratio calculado.

Exemplo de violação: 3 args String em 4 totais = 75% → viola threshold de 38%.

---

## Override por Repo

Quando `${EAW_WORKDIR}/context_sources/onboarding/<repo_key>/62_*.md` existir:

1. Ler o(s) arquivo(s) correspondente(s) integralmente.
2. Extrair os thresholds declarados (ex.: limiar de String%, limite de args, regras de @SuppressWarnings).
3. **Substituir** os Checks Padrão acima pelos thresholds do arquivo de override.
   - Thresholds do override têm precedência absoluta.
   - Checks não declarados no override permanecem como NO-OP (não aplicar o default correspondente).
4. Aplicar os checks do override da mesma forma que os defaults: comando quando disponível,
   fallback declarativo quando não.

Exemplo de override real: `emr-tasy-backend` usa `62_codescene_quality_gates.md` com:
- String args: < 39% (substitui o default de 38%)
- Primitive obsession: < 30%
- Excess args: > 4 (mesmo que o default)
- @SuppressWarnings: proibido (mesmo que o default)

## Sinalização

**Violação detectada** — emitir handoff `waiting`:

```json
{
  "from_phase": "implementation_executor",
  "status": "waiting",
  "blocker": "QUALITY_GATE_FAILED: <nome_do_check>, <arquivo.java>, <método ou linha>",
  "messages": [],
  "codes": []
}
```

Exemplos de `blocker`:
- `"QUALITY_GATE_FAILED: Check1_SuppressWarnings, CorFin/src/.../MyClass.java, linha 42"`
- `"QUALITY_GATE_FAILED: Check2_ExcessArgs, CorFin/src/.../MyService.java, método processPayment (6 args)"`
- `"QUALITY_GATE_FAILED: Check3_StringRatio, CorFin/src/.../MyController.java, ratio=55% (threshold: 38%)"`

**Sem violação** — emitir handoff `completed` normal:

```json
{
  "from_phase": "implementation_executor",
  "status": "completed",
  "messages": [],
  "codes": []
}
```

## Manutenção

### Atualizar os defaults desta skill

Editar diretamente a seção `## Checks Padrão (Defaults)` acima. Cada alteração de threshold
deve ser acompanhada de evidência técnica (ex.: dado CodeScene, policy interna). Registrar
a mudança no `CHANGELOG.md` do repositório `eaw` se aplicável.

### Criar override para um novo repo

1. Criar o arquivo `${EAW_WORKDIR}/context_sources/onboarding/<repo_key>/62_quality_gates.md`
   (ou qualquer nome correspondendo ao glob `62_*.md`).
2. Declarar os thresholds ativos no formato markdown, seguindo o padrão de
   `context_sources/onboarding/emr-tasy-backend/62_codescene_quality_gates.md`.
3. Verificar que o `repo_key` corresponde exatamente ao nome declarado em `repos.conf`
   (campo `<name>` no formato `<name>|<path>|<role>`).
4. O arquivo de override entra em vigor automaticamente na próxima execução de
   `implementation_executor` para cards com `resolved_repo_key` correspondente.
