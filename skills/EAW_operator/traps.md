# EAW Operational Traps

Traps aprendidas em execuções reais. Incluir no Mandatory Delegation Context de cada fase.

## Ambiente

- **PATH corrompido após subagente**: salvar `SAFE_PATH="$PATH"` antes de delegar; restaurar `export PATH="$SAFE_PATH"` antes de chamar `next`
- **EAW_WORKDIR não exportado entre sessões**: verificar `echo $EAW_WORKDIR` retorna path válido antes de qualquer `next`
- **Runtime root errado**: `./scripts/eaw` deve existir no diretório corrente; nunca assumir CWD

## Delegação

- **Delegar template em vez de prompt renderizado**: sempre usar `out/<CARD>/prompts/`, nunca `templates/prompts/`
- **Orquestrador escrevendo prompt custom**: o orquestrador NUNCA escreve o prompt do subagente manualmente. O conteúdo de `out/<CARD>/prompts/<phase>.md` deve ser passado verbatim. Escrever um prompt próprio em vez de usar o renderizado: (1) perde o bloco PHASE_CONTRACTS, (2) perde o bloco CI FEEDBACK, (3) diverge do contrato da fase.
- **workspace.md não repassada ao subagente**: sem ela, agente mistura papéis `infra` e `target`
- **Agente isolado operando CLI**: agente isolado de fase NÃO roda `./scripts/eaw`; apenas o orquestrador roda

## Artefatos

- **Artefatos vazios (0 bytes / só scaffold)**: não devem passar phase completion; verificar `wc -c` > 0
- **Handoff JSON com strings em messages**: `"messages": ["string"]` → runtime rejeita; usar `"messages": []`
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
