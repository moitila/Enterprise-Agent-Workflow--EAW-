# EAW Operational Traps

Traps aprendidas em execuções reais. Incluir no Mandatory Delegation Context de cada fase.

## Ambiente

- **PATH corrompido após subagente**: salvar `SAFE_PATH="$PATH"` antes de delegar; restaurar `export PATH="$SAFE_PATH"` antes de chamar `next`
- **EAW_WORKDIR não exportado entre sessões**: verificar `echo $EAW_WORKDIR` retorna path válido antes de qualquer `next`
- **Runtime root errado**: `./scripts/eaw` deve existir no diretório corrente; nunca assumir CWD

## Delegação

- **Delegar template em vez de prompt renderizado**: sempre usar `out/<CARD>/prompts/`, nunca `templates/prompts/`
- **Orquestrador escrevendo prompt custom**: o orquestrador NUNCA escreve o prompt do subagente manualmente. O conteúdo de `out/<CARD>/prompts/<phase>.md` deve ser passado verbatim. Escrever um prompt próprio em vez de usar o renderizado: (1) perde o bloco PHASE_CONTRACTS, (2) perde o bloco CI FEEDBACK, (3) diverge do contrato da fase.
- **Batchear múltiplas fases em um único subagente**: cada fase exige um agente isolado próprio. Batchear 2+ fases em um subagente: (1) invalida o CI feedback (o agente não sabe qual `<phase>` usar em cada momento), (2) mistura contextos e responsabilidades, (3) viola o princípio de isolamento do EAW. O custo de tokens não justifica o batching — o EAW é uma ferramenta para problemas complexos, não para otimizar tokens.
- **Orquestrador processando o prompt antes de passar**: ler `out/<CARD>/prompts/<phase>.md` mecanicamente e passar verbatim ao subagente — sem interpretar, resumir, reescrever ou adicionar conteúdo próprio. Com CI feedback ativo, o subagente reporta qualidade do prompt via `ci_feedback/`; o orquestrador não precisa pré-validar.
- **Orquestrador lendo o prompt para entendimento**: qualquer leitura com intenção de compreender o conteúdo habilita reescrita. O orquestrador **não lê para entender** — extrai bytes do arquivo e passa ao subagente. Processar entre leitura e delegação é a violação. Ler parcialmente e escrever prompt próprio é a consequência típica.
- **workspace.md não repassada ao subagente**: sem ela, agente mistura papéis `infra` e `target`
- **Agente isolado operando CLI**: agente isolado de fase NÃO roda `./scripts/eaw`; apenas o orquestrador roda

## Artefatos

- **Completion é por IDENTIDADE, não por tamanho**: um artefato "preenchido" = existe **E** não-vazio **E** NÃO-idêntico ao scaffold/template **E** sem token de placeholder de template (`<CARD>`, `{{...}}`). NÃO há piso de tamanho (nem gate nem audit) — um artefato legítimo curto (ex.: handoff JSON ~64B) PASSA. O runtime é máquina determinística sem LLM: valida proveniência/identidade, nunca qualidade semântica. O predicado único é `eaw_phase_completion_artifact_has_meaningful_content` (`scripts/lib/phase_completion.sh`).
- **Audit reusa o predicado do gate (ponto único)** *(EAW-FIX-SCAFFOLD-HYGIENE)*: `eaw_card_enforce_mandatory_analysis_audit` chama `has_meaningful_content` com a fase PRODUTORA do artefato — audit e gate compartilham exatamente a mesma regra de identidade (sem `[[ ! -s ]]` isolado, sem tamanho). `min_bytes: 500` declarado nos `tracks/**/phases/*.yaml` ficou INERTE (backlog de higiene; não é mais usado como critério).
- **`implementation/10_change_plan.md`, `20_patch_notes.md` e o default de fase são AUSENTES por padrão (deferidos)** *(EAW-FIX-SCAFFOLD-HYGIENE)*: `eaw_scaffold_phase_artifact` não pré-cria esses artefatos — o melhor scaffold é o arquivo ausente, então `create_file` funciona no primeiro preenchimento e um `test -s` isolado não avança fase. `implementation/00_scope.lock.md` permanece scaffold mínimo ESTRUTURAL (`## In Scope`/`## Out of Scope`, enriquecido com `write_allowlist: []`); `*.json` intacto (envelope por schema).
- **Artefatos vazios (0 bytes / só scaffold)**: não devem passar phase completion; rejeitados por não-vazio + anti-scaffold (`cmp`), não por `wc -c`
- **Handoff JSON com strings em messages**: `"messages": ["string"]` → runtime rejeita com `envelope schema validation failed`; usar `"messages": []` sempre. O bloco `PHASE_CONTRACTS` do prompt já emite aviso `CRITICAL` após o schema — não ignorar. `messages[]` é para uso interno do runtime; agentes não devem populá-lo.
- **Artefato derivado fora da allowlist**: builds podem regenerar; manter se reverter quebra o build; registrar em `_warnings.md`
- **Handoff JSON sem envelope completo**: `handoff.json` não pode ser `{}`. Usar sempre:
  `{"from_phase":"<phase>","status":"completed","messages":[],"codes":[]}` .
  Envelope incompleto causa `envelope schema validation failed` no runtime.
- **dynamic_context com nomes customizados**: a fase exige nomes fixos:
  `00_scope_manifest.md`, `20_candidate_files.txt`, `30_target_snippets.md`, `40_warnings.md`.
  Não criar nomes por item de backlog — isso não satisfaz `phase.completion`.

## CI / Runtime

- **CI falha por dependência não publicada**: classificar como "expected dependency gap", não regressão
- **Cards multi-repo exigem ordem explícita de merge**: nunca assumir merge paralelo
- **Prompt da fase referencia repo não listado em repos.conf**: falhar, não improvisar
- **scope.lock não parseável pelo runtime**: preencher com allowlist no formato correto antes de chamar `next`
- **`scope_lock_empty` — TARGET_REPOS: (none)** *(BL-CI-14)*: quando todos os repos são `infra` e nenhum é `target`, o scaffold de `implementation/00_scope.lock.md` gerado é mínimo (sem `write_allowlist`). O runtime detecta "scope.lock presente mas não parseável" e emite `scope_lock_empty`. A correção (runtime ≥ BL-CI-14) injeta `write_allowlist: []` automaticamente. Em runtimes mais antigos, adicionar manualmente `write_allowlist: []` ao `00_scope.lock.md` antes de chamar `next`. `00_scope.lock.md` permanece scaffold mínimo com `write_allowlist: []` e é validado por PARSE ESTRUTURAL PRÓPRIO (`write_allowlist:` OU headings `## In Scope` + `## Out of Scope`), executado APÓS o anti-scaffold `cmp` e independente de tamanho — não por piso de bytes.
- **Audit de artefatos de análise é skip-aware e track-aware** *(EAW-FIX-HYP-GATE)*: `eaw_card_enforce_mandatory_analysis_audit` (`scripts/lib/phase_completion.sh`) só exige um artefato quando sua fase produtora ∈ `completed_phases` do `state_card_<track>.yaml` **e** a fase declara esse artefato como saída na `track.yaml`. Fonte durável do skip = `completed_phases` (fase pulada nunca vira `current_phase`, bloco 614A). Fases puladas (`skip_when`) e fases inexistentes na track (ex.: `patch` sem `findings`/`hypotheses`) não bloqueiam `next`. `state` ausente/ilegível → fail-safe: exige tudo (não-regressão). Mapa fixo: `20_findings←findings`, `30_hypotheses←hypotheses`, `40_next_steps←planning`, `00_scope.lock`/`10_change_plan←implementation_planning`.
- **`ci_feedback_prompt.md` com fase errada** *(corrigido em runtime — 2026-07-13)*: anteriormente renderizado uma vez com `card_init` hardcoded. Agora re-renderizado por fase em `eaw_render_phase_prompt_template` com o `step_id` correto. Se encontrar `card_init` em `ci_feedback_prompt.md`, o runtime está desatualizado.

## Repos

- **Role `target`/`infra` é por contexto, não global**: o mesmo repo pode ser `target` em um card (quando o card trabalha sobre ele) e `infra` em outro (quando é apenas tooling). Mudar `repos.conf` antes de criar cards que trabalham sobre o repo; restaurar após. Não há suporte a dual-role no mesmo `repos.conf`.

## Estado WAITING

- **Envelope `waiting` com `blocker` ausente**: o runtime rejeita com `20_handoff.json status=waiting requires non-empty blocker field`. O agente deve sempre preencher `blocker` com uma descrição objetiva do que impede a conclusão. Envelope `waiting` sem `blocker` nunca passa a validação de schema.
- **Envelope `waiting` com `blocker` vazio (`""`)**: idêntico ao caso anterior — o runtime rejeita. Um valor não-vazio real é exigido.
- **`messages` não-vazio bloqueia phase completion**: usar sempre `"messages": []` no handoff. O runtime rejeita se `messages` contiver entradas sem `type` e `code`. O campo `messages` é para uso interno do runtime; agentes não devem populá-lo.
- **Envelope `waiting` correto** (canônico):
  ```json
  {"from_phase":"<nome-da-fase>","status":"waiting","blocker":"<descricao-nao-vazia>","messages":[],"codes":[]}
  ```
