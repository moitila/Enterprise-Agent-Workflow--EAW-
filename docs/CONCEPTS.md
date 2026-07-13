# EAW Concepts

Operational reference for five concepts that appear in advanced EAW prompts and
contracts, absent from the quick-start glossary.

For the broader object model, see [`docs/CONCEPTUAL_MODEL.md`](CONCEPTUAL_MODEL.md).

---

## `write_allowlist`

**Definição**: O conjunto de paths absolutos nos quais o agente de fase está
autorizado a escrever durante a execução de um card.

**Como funciona**:
O runtime resolve a `write_allowlist` de um card seguindo uma cadeia de prioridade:
1. `implementation/00_scope.lock.md` — fonte autoritativa, quando presente;
2. arquivo markdown do card com o label `WRITE_ALLOWLIST` — fallback secundário;
3. caminhos declarados em `implementation/10_change_plan.md` — último recurso.

Qualquer escrita fora dos paths resultantes é uma violação de escopo. O executor
injeta a allowlist resolvida no bloco `RUNTIME_ENVIRONMENT` do prompt renderizado.

**Exemplo de uso** (bloco `RUNTIME_ENVIRONMENT` injetado pelo executor):
```
WRITE_ALLOWLIST:
/home/user/dev/eaw/docs/CONCEPTS.md
/home/user/dev/eaw/docs/GETTING_STARTED.md

WRITE_ALLOWLIST_SOURCE: scope_lock:/home/user/dev/.eaw/out/BL-03/implementation/00_scope.lock.md
NOTE: scope.lock is authoritative.
```

**Gerado por / Referência**: `scripts/commands/eaw_commands.sh` [L1712–1752] —
função `eaw_card_write_allowlist_entries` (algoritmo de resolução);
`docs/ARCHITECTURE.md` [L77–88] — Operational Constraints.

---

## `scope.lock` (`00_scope.lock.md`)

**Definição**: Artefato soberano criado durante a fase `implementation_planning`
que declara explicitamente quais paths o agente de implementação está autorizado
a escrever.

**Como funciona**:
`00_scope.lock.md` é declarado como `required_artifact` pela fase
`implementation_planning` e gerado pelo prompt dessa fase. Nas fases de
implementação subsequentes, o executor o injeta como contrato soberano — posição
3 na hierarquia de autoridade do subagente (acima de `10_change_plan.md` e do
prompt da fase). Se houver conflito entre o prompt ou o change plan e o scope
lock, o agente deve parar, registrar o bloqueio e devolver controle ao operador;
nunca improvizar mudando o write set.

**Exemplo de uso** (declaração em `tracks/feature/phases/implementation_planning.yaml`):
```yaml
outputs:
  create_artifacts:
    - implementation/00_scope.lock.md
    - implementation/10_change_plan.md
  completion:
    strategy: required_artifacts_exist
    required_artifacts:
      - implementation/00_scope.lock.md
      - implementation/10_change_plan.md
```

**Gerado por / Referência**: `tracks/feature/phases/implementation_planning.yaml`
[L1–26]; `skills/EAW_operator/card_execution.md` [L155–175] — hierarquia de
autoridade do subagente e contrato soberano.

---

## `handoff.json` (`20_handoff.json`)

**Definição**: Arquivo JSON machine-readable emitido ao final de uma fase para
comunicar exit codes ao mecanismo `skip_when` do runtime.

> **Atenção terminológica**: `docs/QUICKSTART.md` L79 usa "handoff artifact"
> para designar o rendered prompt materializado em `out/<CARD>/prompts/`. Essa
> terminologia é informal e distinta: `20_handoff.json` é um arquivo JSON
> separado, com propósito e schema próprios. A fonte autoritativa é
> `skills/EAW_prompt_creator/SKILL.md` — não o QUICKSTART.

**Como funciona**:
Quando uma fase declara `contract: emit_handoff: true` na transição do track
YAML, o runtime lê `20_handoff.json["codes"]` após a execução e compara com a
lista `skip_when`. Se houver match, a fase seguinte é pulada. O agente deve
escrever o arquivo com **schema compacto** (sem espaços após `:` e `,`) via
`printf` — JSON formatado/pretty-printed falha o parser regex do runtime. O
campo `codes` é obrigatório; quando nenhuma condição de skip se aplica, usar
`"codes":[]`.

**Exemplo de uso** (schema mínimo):
```json
{"from_phase":"investigations","status":"completed","messages":[],"codes":["READY_FOR_IMPL"]}
```

Quando nenhuma condição de skip se aplica:
```json
{"from_phase":"investigations","status":"completed","messages":[],"codes":[]}
```

Relação com `skip_when` no track YAML:
```yaml
transitions:
  investigations:
    next: implementation_planning
    skip_when:
      - READY_FOR_IMPL
    contract:
      emit_handoff: true
```

**Gerado por / Referência**: `skills/EAW_prompt_creator/SKILL.md` [L119–140] —
Handoff Contract (schema, regras, campos obrigatórios);
`skills/EAW_track_creator/SKILL.md` [L140–175] — skip_when contract e guardrails.

---

## `phase.skills`

**Definição**: Campo opcional em `phase.yaml` que declara a lista de skills que
o executor carregará no agente isolado como contexto operacional para aquela fase.

**Como funciona**:
`phase.skills` é distinto de `phase.context`: enquanto `phase.context` injeta
evidências (arquivos e templates que o agente lê como input), `phase.skills`
carrega capacidades operacionais (como o agente opera). As skills são externas ao
prompt e ao contexto injetado — o executor nunca modifica o conteúdo do prompt
para mencionar os nomes das skills.

Quando `phase.skills` está ausente ou vazio, o executor aplica o fallback
implícito `[workspace]` (Tier 1). Quando `phase.skills` está presente e
não-vazio, a lista declarada é o conjunto efetivo (Tier 2). A skill `workspace` é
sempre carregada pelo executor independentemente de ser declarada.

**Exemplo de uso** — fase com skill explícita (Tier 2):
```yaml
phase:
  id: implementation_executor
  prompt:
    path: templates/prompts/feature/implementation_executor/prompt_v7.md
  skills:
    - workspace
    - eaw_workdir_context_v1
```

Fase sem `phase.skills` — Tier 1 fallback ativo (válido e esperado):
```yaml
phase:
  id: implementation_executor
  prompt:
    path: templates/prompts/feature/implementation_executor/prompt_v7.md
```

**Gerado por / Referência**: `docs/WORKFLOW_YAML_CONTRACT.md` [L257–300] — Phase
Skills Block (contrato formal, tiers de resolução, validação conhecida);
`docs/ARCHITECTURE.md` [L41–68] — Modo D cycle e executor role;
`docs/CONCEPTUAL_MODEL.md` [L86–107] — Skill object e distinção `phase.skills`
vs `phase.context`.

---

## `eaw preflight` vs `eaw doctor`

| Dimensão | `eaw preflight <CARD>` | `eaw doctor` |
|---|---|---|
| **Propósito** | Verificar a prontidão de um card específico para avançar de fase | Inspecionar a saúde geral do ambiente EAW |
| **Argumento** | Obrigatório: `<CARD>` (ex: `eaw preflight BL-03`) | Nenhum |
| **Checks realizados** | (1) `EAW_WORKDIR` definido e é diretório válido; (2) repos.conf — cada path existe e contém `.git`; (3) runtime root acessível (`./scripts/eaw`); (4) `out/<CARD>/prompts/` existe com ≥1 arquivo | Dirs resolvidos (`RUNTIME_ROOT`, `EAW_WORKDIR`, etc.); ferramentas (`git`, `rg`, `awk`, `sed`, `bash`); arquivos de config (`repos.conf`, `search.conf`, `eaw.conf`); git hooks; `EAW_SMOKE_SH` |
| **Output** | Binário: `PASS (4/4 checks)` ou `FAIL [n/4]` com lista de falhas | Estruturado por categoria: `OK / WARN / ERROR` por item |
| **Escopo** | Card-específico | Ambiente global |
| **Quando usar** | Antes de `eaw next <CARD>` — confirmar que o card está pronto para avançar | Ao configurar o ambiente, diagnosticar erros inesperados ou validar uma nova instalação |

**Referência**: `scripts/commands/cmd_preflight.sh` [L1–60];
`scripts/commands/cmd_doctor.sh` [L1–80]; `README.md` [L238–241] — seção
Diagnostics.
