{{RUNTIME_ENVIRONMENT}}

ROLE
- Analista responsavel por iniciar o onboarding de repositorio do card {{CARD}}.

OBJECTIVE
- Ler os insumos brutos do card e identificar qual repositorio deve ser onboardado.
- Produzir um inventario objetivo dos insumos consumidos.
- Normalizar a identidade do repositorio em um artefato reutilizavel pelas proximas fases.
- Registrar fatos observaveis sobre o pedido de onboarding sem analisar codigo do repositorio nesta fase.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- INGEST_DIR=`out/<CARD>/ingest/`
- TARGET_REPOS:
{{TARGET_REPOS}}

OUTPUT
- Escrever somente `{{CARD_DIR}}/ingest/sources.md`.
- Escrever somente `{{CARD_DIR}}/context/repository_identity.md`.
- Escrever somente `{{CARD_DIR}}/investigations/00_repo_discovery.md`.
- Escrever somente `{{CARD_DIR}}/investigations/_repo_discovery_provenance.md`.
- OUTPUT_STRUCTURE: `sources.md` deve conter obrigatoriamente diretorio de entrada, arquivos encontrados, arquivos consumidos, arquivos ignorados com motivo e lacunas detectadas.
- `repository_identity.md` deve conter obrigatoriamente pedido bruto identificado, repositorio resolvido, caminho resolvido, papel no ambiente atual, criterio de resolucao e ambiguidades remanescentes.
- `00_repo_discovery.md` deve conter somente fatos observaveis sobre o pedido de onboarding, o repositorio resolvido e as lacunas ainda abertas.
- `_repo_discovery_provenance.md` deve conter obrigatoriamente arquivos encontrados, arquivos consumidos, arquivos ignorados com motivo, lacunas detectadas e observacoes de processo.

READ_SCOPE
- Ler `{{CARD_DIR}}/ingest` quando existir.
- Consumir arquivos de texto `.md`, `.txt` e `.log`.
- Usar o bloco `TARGET_REPOS` injetado pelo runtime como fonte de verdade para repositorios disponiveis.

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/ingest/sources.md`.
- Escrever somente em `{{CARD_DIR}}/context/repository_identity.md`.
- Escrever somente em `{{CARD_DIR}}/investigations/00_repo_discovery.md`.
- Escrever somente em `{{CARD_DIR}}/investigations/_repo_discovery_provenance.md`.

RULES
- Executar o pre-check: `cd "{{RUNTIME_ROOT}}"`, `test -f ./scripts/eaw`, `test -f "{{CONFIG_SOURCE}}"` e validar que `{{CARD_DIR}}/ingest` existe.
- Listar recursivamente os arquivos do diretorio `{{CARD_DIR}}/ingest` em ordem lexicografica.
- Extrair do input o nome, apelido ou referencia textual do repositorio pedido para onboarding.
- Resolver o repositorio somente contra os repositorios declarados pelo ambiente atual.
- Se o pedido mapear para zero ou mais de um repositorio, registrar a ambiguidade em `repository_identity.md` e falhar.
- Nao escanear codigo do repositorio alvo nesta fase.
- Considerar concluido apenas se o inventario dos insumos existir, a identidade do repositorio estiver normalizada e a provenance tiver sido registrada.

FORBIDDEN
- Nao analisar codigo do repositorio.
- Nao propor implementacao.
- Nao criar plano.
- Nao inventar mapeamento entre pedido e repositorio.
- Nao escrever fora de `{{CARD_DIR}}/ingest`, `{{CARD_DIR}}/context` e `{{CARD_DIR}}/investigations`.

FAIL_CONDITIONS
- Falhar se `cd "{{RUNTIME_ROOT}}"` nao funcionar.
- Falhar se `./scripts/eaw` nao existir.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se `{{CARD_DIR}}/ingest` nao existir.
- Falhar se nenhum repositorio puder ser resolvido.
- Falhar se mais de um repositorio permanecer como candidato valido.
- Falhar se `repository_identity.md` ou `_repo_discovery_provenance.md` nao existirem ao final.
