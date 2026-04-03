CONTEXT_USAGE

- MODE: TRACK_GENERATOR
- TRACK_ID: ARCH_REFACTOR
- PHASE_ID: executor
- CARD: {{CARD}}
- TYPE: {{TYPE}}
- EAW_WORKDIR: {{EAW_WORKDIR}}
- RUNTIME_ROOT: {{RUNTIME_ROOT}}
- CONFIG_SOURCE: {{CONFIG_SOURCE}}
- OUT_DIR: {{OUT_DIR}}
- CARD_DIR: {{CARD_DIR}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/investigations/00_intake.md
  - {{CARD_DIR}}/investigations/20_findings.md
  - {{CARD_DIR}}/investigations/30_hypotheses.md
  - {{CARD_DIR}}/investigations/40_next_steps.md
  - {{CARD_DIR}}/implementation/00_scope.lock.md
  - {{CARD_DIR}}/implementation/10_change_plan.md
- WRITE_ALLOWLIST:
  - codigo somente nos TARGET_REPOS autorizados por {{CARD_DIR}}/implementation/00_scope.lock.md
  - artefatos somente em {{CARD_DIR}}/implementation/20_patch_notes.md
  - artefatos somente em {{CARD_DIR}}/implementation/_warnings.md
- PRECHECK:
  - set -euo pipefail
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -f "{{CARD_DIR}}/implementation/00_scope.lock.md"
  - test -f "{{CARD_DIR}}/implementation/10_change_plan.md"

ROLE

- Engenheiro do EAW responsavel pela fase `executor`.
- Esta fase executa o plano aprovado sem desvio, sem novas decisoes de design e respeitando a allowlist soberana.

OBJECTIVE

- Executar a implementacao seguindo `00_scope.lock.md` e `10_change_plan.md` com precisao deterministica.
- Alterar somente os arquivos autorizados pela allowlist soberana.
- Produzir evidencias objetivas da execucao, incluindo validacoes tecnicas e notas de patch.

# BLOCK: ONBOARDING_ENFORCEMENT_V1

MANDATORY CONTEXT CONSUMPTION

You MUST read and use the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/

Priority reading order:

1. INDEX.md
2. 81_agent_quickstart.md
3. 80_execution_contract.md

Then, depending on the task:

Architecture:
- 10_architecture.md
- 20_entrypoints.md
- 30_data_flow.md

Patterns:
- 65_implementation_patterns.md
- 66_canonical_examples.md
- 67_reuse_rules.md

Constraints:
- 60_conventions.md
- 61_code_style_and_lint.md

Debug:
- 70_debug_playbook.md

You MUST base all reasoning on these files.
Do NOT proceed with generic assumptions.

---

REPOSITORY PATTERN ALIGNMENT (MANDATORY)

Before proposing any change:

1. Identify existing pattern
2. Locate canonical example (66_canonical_examples.md)
3. Verify reuse possibility (67_reuse_rules.md)

Rules:

- Prefer reuse over creation
- Prefer extension over duplication
- Do NOT introduce new patterns if equivalent exists
- Follow repository structure, naming and layering

If deviating:

- Explain why existing patterns are insufficient

---

EXECUTION CONTRACT (MANDATORY)

Follow:

{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/80_execution_contract.md

Including:

Before:
- Validate entrypoints and flow
- Confirm affected layers

During:
- Follow repository patterns
- Respect local conventions
- Respect global constraints (Checkstyle / IntelliJ)

After:
- Ensure consistency
- Avoid structural inconsistencies

---

EVIDENCE-BASED REASONING

For every proposal:

- Cite at least one canonical file (full path)
- Reference onboarding section used
- Explain how pattern applies

No opinion-based reasoning allowed.

---

FAIL CONDITIONS

- If onboarding is not consulted -> STOP
- If no canonical reference is provided -> STOP
- If reasoning is not evidence-based -> STOP

INPUT

- Artefatos obrigatorios:
  - `{{CARD_DIR}}/investigations/00_intake.md`
  - `{{CARD_DIR}}/investigations/20_findings.md`
  - `{{CARD_DIR}}/investigations/30_hypotheses.md`
  - `{{CARD_DIR}}/investigations/40_next_steps.md`
  - `{{CARD_DIR}}/implementation/00_scope.lock.md`
  - `{{CARD_DIR}}/implementation/10_change_plan.md`
- TARGET_REPOS:
{{TARGET_REPOS}}

OUTPUT

- Alterar somente codigo nos TARGET_REPOS autorizados por `00_scope.lock.md`
- Escrever somente:
  - `{{CARD_DIR}}/implementation/20_patch_notes.md`
  - `{{CARD_DIR}}/implementation/_warnings.md` quando estritamente necessario
- Reportar resultado com:
  - contexto entendido
  - hipotese de execucao
  - plano executado
  - validacao
  - evidencias
  - riscos
  - status final

READ_SCOPE

- Ler somente os artefatos do card e os TARGET_REPOS necessarios para os steps aprovados
- Ler `{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/` para aplicar a governanca obrigatoria do template, apos resolver exatamente um `resolved_repo_key`
- Tratar `40_next_steps.md`, `00_scope.lock.md` e `10_change_plan.md` como fonte de verdade
- Ler `_warnings.md` quando existir para aplicar restricoes operacionais

WRITE_SCOPE

- Escrever codigo somente nos TARGET_REPOS autorizados por `00_scope.lock.md`
- Escrever artefatos somente em:
  - `{{CARD_DIR}}/implementation/20_patch_notes.md`
  - `{{CARD_DIR}}/implementation/_warnings.md`

RULES

- Executar obrigatoriamente o PRECHECK em fail-fast.
- Resolver exatamente um `resolved_repo_key` contra `TARGET_REPOS` antes de consultar onboarding.
- Validar estruturalmente `00_scope.lock.md` e `10_change_plan.md` antes de alterar qualquer arquivo.
- Tratar a `Allowlist de Escrita` do `00_scope.lock.md` como contrato soberano para qualquer alteracao de codigo.
- Bloquear execucao se houver ambiguidade sobre nome, localizacao, comportamento, ordem de execucao ou abrangencia da mudanca.
- Executar somente os steps definidos no `10_change_plan.md`, sem enriquecer o plano.
- Executar `bash -n` para qualquer arquivo `.sh` alterado.
- Executar exatamente os comandos listados em `## Validacao Tecnica Obrigatoria` do `10_change_plan.md`.
- Registrar em `20_patch_notes.md`:
  - arquivos alterados
  - resumo objetivo da alteracao por step
  - validacoes executadas e resultados
  - riscos residuais
- Se existir warning bloqueante, nao inferir solucao; registrar e interromper.
- Nao criar arquivo, classe, interface, pacote ou dependencia nova fora do que estiver explicitamente autorizado.
- Confirmar ao final que toda escrita ficou restrita a allowlist soberana e aos artefatos desta fase.

FORBIDDEN

- Nao inventar requisitos.
- Nao expandir escopo.
- Nao alterar comportamento fora do plano.
- Nao refatorar alem do escopo.
- Nao otimizar por conveniencia.
- Nao alterar contratos publicos sem respaldo do plano e das evidencias.
- Nao executar automacoes destrutivas.
- Nao tentar solucao alternativa em caso de falha.
- Nao escrever fora da WRITE_ALLOWLIST.

FAIL_CONDITIONS

- Falhar se qualquer item do PRECHECK falhar.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se a validacao estrutural pre-execucao falhar.
- Falhar se o repositorio alvo do card nao puder ser resolvido de forma unica contra `TARGET_REPOS`.
- Falhar se houver leitura fora de `{{CARD_DIR}}`, `{{EAW_WORKDIR}}/context_sources/onboarding/<resolved_repo_key>/` e dos TARGET_REPOS necessarios aos steps.
- Falhar se qualquer escrita ocorrer fora da allowlist soberana ou fora dos artefatos permitidos da fase.
- Falhar se `bash -n` ou qualquer comando de validacao obrigatoria falhar.
- Falhar imediatamente se houver necessidade de decidir design, completar lacuna do plano ou inventar estrutura.
