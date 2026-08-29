# bug_ONBOARD Track — Contracts and Conventions

## 1. Sincronismo `active:` YAML ↔ arquivo ACTIVE

Cada phase YAML em `tracks/bug_ONBOARD/phases/<phase>.yaml` declara `phase.prompt.active: N`.
O arquivo `templates/prompts/bug_ONBOARD/<phase>/ACTIVE` deve conter `vN` exatamente.

**Regra de manutenção:** ao criar um novo `prompt_vN.md`, atualizar o campo `active:` no YAML
correspondente para `N` e o arquivo `ACTIVE` para `vN`. Os dois devem permanecer idênticos.

**Invariante:** INV-10-ACTIVE em `tests/invariants.sh` verifica automaticamente cada fase de
cada track. Falha se `yaml_active != active_file` para qualquer fase que tenha arquivo ACTIVE.

---

## 2. Scaffolds de `implementation/00_scope.lock.md`

O scaffold criado por `eaw card` (via `eaw_scaffold_phase_artifact` em `eaw_commands.sh`) deve
conter as 7 seções obrigatórias declaradas em `required_sections` do YAML
`implementation_planning.yaml`:

```
## Base Obrigatoria
## Hipotese(s) Base
## Contexto
## In Scope
## Out of Scope
## Allowlist de Escrita
## Regra de Escrita
```

A função `eaw_phase_completion_render_expected_scaffold` em `phase_completion.sh` deve gerar
um scaffold idêntico ao criado por `eaw_scaffold_phase_artifact` — os dois são comparados pelo
gate anti-scaffold para detectar scaffolds não preenchidos.

**Allowlist de Escrita:** o agente deve preencher esta seção com paths absolutos reais, um por
linha. Nenhum path fictício ou glob é aceito.

---

## 3. Protocolo `## Allowlist de Escrita` — Gate FIX-SCOPELOCK

A função `has_meaningful_content` em `phase_completion.sh` aplica validação estrutural ao
`implementation/00_scope.lock.md`. O arquivo é aceito somente se:

1. Contém `write_allowlist:` (formato YAML legado), **ou**
2. Contém `## In Scope` **e** `## Out of Scope` **e** `## Allowlist de Escrita` **com pelo menos
   um path real** (contendo `/`) logo abaixo do heading.

Um scope.lock com `## In Scope` + `## Out of Scope` mas sem `## Allowlist de Escrita` preenchida
é **rejeitado** — o gate retorna exit 1 (bloqueio de fase).

**Por que:** sem allowlist explícita, o runtime EAW degrada silenciosamente para permissão
irrestrita sobre `CARD_DIR`. A validação garante que a allowlist soberana esteja sempre declarada.

**Testes:** `tests/smoke_completion_content.sh` cobre os casos (g) e (h):
- `(g)` sem `## Allowlist de Escrita` → gate rejeita
- `(h)` com path real na Allowlist → gate aceita

---

## 4. Separação `## Validacao Read-only` vs `## Validacao Pos-PR`

O template `templates/implementation_10_change_plan.md` e o prompt de
`implementation_planning/prompt_v6.md` declaram duas seções de validação distintas:

### `## Validacao Read-only`
Comandos que o agente executor **pode e deve** executar durante a fase:
- `bash -n <arquivo>` — verificação de sintaxe shell
- `grep`, `diff`, `cat`, `wc` — leitura e comparação de arquivos
- Verificações de presença e conteúdo de artefatos

**Restrição:** sem DDL, sem compilação, sem operações que modifiquem banco ou ambiente.

### `## Validacao Pos-PR`
Operações informativas que só fazem sentido após o merge do PR:
- Compilação de pacotes Java/PL/SQL
- DDL de banco de dados
- Testes de integração que exigem ambiente completo

**Comportamento do executor:** registrar no `20_patch_notes.md` mas **não executar** e **não
bloquear** a fase por itens desta seção.

**Rationale:** misturar DDL com `bash -n` numa única seção criava conflito irreconciliável com
`WRITE_SCOPE` e `FORBIDDEN` do prompt do executor, que proíbe qualquer operação de banco.

**Prompt v6:** `templates/prompts/bug_ONBOARD/implementation_executor/prompt_v6.md` codifica
esta distinção em PASSO 3. Cartas em andamento que apontam para `prompt_v5.md` continuam
funcionando — `v5` não foi modificado.

---

## 5. Invariantes automatizadas

| Invariante | Arquivo | Descrição |
|---|---|---|
| `INV-10-ACTIVE` | `tests/invariants.sh` | `active:` do YAML == sufixo numérico do ACTIVE file |
| `INV-11-SECTIONS` | `tests/invariants.sh` | Cada heading em `required_sections` existe no template correspondente |
| `smoke_completion_content (g/h)` | `tests/smoke_completion_content.sh` | Gate Allowlist de Escrita: rejeita sem path, aceita com path real |
| `smoke_bug_ONBOARD` | `tests/smoke_bug_ONBOARD.sh` | Smoke end-to-end dos 4 defeitos corrigidos neste card |
