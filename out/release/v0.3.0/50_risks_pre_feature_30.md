# Risks Before Feature 30 (multi-language / hardcoded text removal)

## Expected risks
- IO contract drift in CLI messages (principalmente `stdout`/`stderr` em `prompt`, `validate`, `doctor`).
- Quebra de determinismo por internacionalização dinâmica (ordem/forma do texto e artefatos).
- Regressão em validações de headings/templates que hoje dependem de termos fixos.
- Divergência entre documentação e comportamento real dos comandos.
- Mudança acidental em paths de artefatos (`out/<CARD>/...`) durante adaptação de mensagens.

## Regression-sensitive items
- Estrutura estável de `out/<CARD>/` definida em `docs/CONTRACT.md`.
- Contrato de `prompt`: conteúdo no `stdout` + confirmação `Wrote ...` no `stderr`.
- Saídas de `validate` e `doctor` usadas como sinais operacionais em integração.
- Compatibilidade com templates e headings mínimos de intake.
- Reprodutibilidade/idempotência de geração de artefatos para mesmo card.
