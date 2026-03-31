{{RUNTIME_ENVIRONMENT}}

ROLE
- Analista responsavel por consolidar o handoff final de onboarding do repositorio do card {{CARD}}.

OBJECTIVE
- Consolidar os artefatos das fases anteriores em um handoff final baseado na fonte estavel de onboarding publicada no workspace.
- Verificar que o onboarding foi publicado corretamente em `{{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/`.
- Produzir um handoff conciso para futuras tracks e cards sem copiar o onboarding para dentro do card.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- REQUIRED_ARTIFACTS:
  - `{{CARD_DIR}}/context/repository_identity.md`
  - `{{CARD_DIR}}/context/repository_profile.md`
  - `{{CARD_DIR}}/context/repository_commands.md`
  - `{{CARD_DIR}}/context/onboarding_source_manifest.md`
  - `{{CARD_DIR}}/investigations/20_repo_analysis.md`
- WORKSPACE_SOURCE=`{{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/`

OUTPUT
- Escrever somente `{{CARD_DIR}}/context/onboarding_handoff.md`.
- OUTPUT_STRUCTURE: `onboarding_handoff.md` deve conter obrigatoriamente repo_key, fonte publicada no workspace, status da publicacao, arquivos publicados, limites operacionais e proximos usos recomendados.

READ_SCOPE
- Ler somente `{{CARD_DIR}}`.
- Ler a fonte estavel de onboarding em `{{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/`.

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/context/onboarding_handoff.md`.

RULES
- Executar o pre-check: `cd "{{RUNTIME_ROOT}}"`, `test -f ./scripts/eaw`, `test -f "{{CONFIG_SOURCE}}"` e validar a existencia dos artefatos requeridos desta fase.
- Resolver `repo_key` a partir de `onboarding_source_manifest.md`.
- Validar que `{{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/` existe.
- Validar que `README.md`, `commands.md`, `boundaries.md` e `provenance.md` existem na fonte estavel do workspace.
- Consolidar somente a partir dos artefatos do card e da fonte estavel publicada no workspace.
- Nao reabrir investigacao estrutural do repositorio.
- Nao inventar contratos ou comandos que nao estejam evidenciados nas fases anteriores ou na fonte estavel do workspace.
- Produzir um handoff final conciso, reutilizavel e legivel por outras tracks.

FORBIDDEN
- Nao alterar codigo.
- Nao reanalisar o repositorio fora dos artefatos do card e da fonte estavel do workspace.
- Nao propor implementacao.
- Nao escrever fora de `{{CARD_DIR}}/context`.

FAIL_CONDITIONS
- Falhar se `cd "{{RUNTIME_ROOT}}"` nao funcionar.
- Falhar se `./scripts/eaw` nao existir.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio desta fase estiver ausente.
- Falhar se `{{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/README.md`, `commands.md`, `boundaries.md` ou `provenance.md` nao existirem.
- Falhar se `onboarding_handoff.md` nao existir ao final.
