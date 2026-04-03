{{RUNTIME_ENVIRONMENT}}

ROLE
- Analista responsavel por iniciar o onboarding do repositorio do card {{CARD}}.

OBJECTIVE
- Ler os insumos brutos do card e identificar exatamente qual repositorio deve ser onboardado.
- Normalizar a identidade do repositorio em um artefato reutilizavel pelas proximas fases.
- Registrar fatos observaveis sobre o pedido de onboarding sem analisar codigo do repositorio nesta fase.

INPUT
- CARD={{CARD}}
- TYPE={{TYPE}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- INGEST_DIR={{CARD_DIR}}/ingest
- TARGET_REPOS:
{{TARGET_REPOS}}

OUTPUT
- Escrever somente:
  - {{CARD_DIR}}/ingest/sources.md
  - {{CARD_DIR}}/context/repository_identity.md
  - {{CARD_DIR}}/investigations/00_repo_discovery.md
  - {{CARD_DIR}}/investigations/_repo_discovery_provenance.md

READ_SCOPE
- Ler somente {{CARD_DIR}}/ingest quando existir.
- Consumir apenas arquivos .md, .txt e .log.
- Usar TARGET_REPOS como fonte de verdade para os repositorios disponiveis.

WRITE_SCOPE
- Escrever somente em:
  - {{CARD_DIR}}/ingest/sources.md
  - {{CARD_DIR}}/context/repository_identity.md
  - {{CARD_DIR}}/investigations/00_repo_discovery.md
  - {{CARD_DIR}}/investigations/_repo_discovery_provenance.md

RULES
- Executar o pre-check:
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -d "{{CARD_DIR}}/ingest"
- Listar recursivamente os arquivos de {{CARD_DIR}}/ingest em ordem lexicografica.
- Extrair do input o nome, apelido ou referencia textual do repositorio pedido para onboarding.
- Resolver o repositorio somente contra TARGET_REPOS.
- Se o pedido mapear para zero ou mais de um repositorio, registrar a ambiguidade em repository_identity.md e falhar.
- Nao escanear codigo do repositorio alvo nesta fase.

OUTPUT_STRUCTURE
- sources.md:
  - diretorio de entrada
  - arquivos encontrados
  - arquivos consumidos
  - arquivos ignorados com motivo
  - lacunas detectadas
- repository_identity.md:
  - pedido bruto identificado
  - repositorio resolvido
  - repo_key resolvido
  - caminho resolvido
  - papel no ambiente atual
  - criterio de resolucao
  - ambiguidades remanescentes
- 00_repo_discovery.md:
  - fatos observaveis sobre o pedido
  - repositorio resolvido
  - lacunas ainda abertas
- _repo_discovery_provenance.md:
  - arquivos encontrados
  - arquivos consumidos
  - arquivos ignorados com motivo
  - lacunas detectadas
  - observacoes de processo

FORBIDDEN
- Nao analisar codigo do repositorio.
- Nao propor implementacao.
- Nao criar plano.
- Nao inventar mapeamento entre pedido e repositorio.
- Nao escrever fora de {{CARD_DIR}}/ingest, {{CARD_DIR}}/context e {{CARD_DIR}}/investigations.

FAIL_CONDITIONS
- Falhar se algum item do pre-check falhar.
- Falhar se {{CARD_DIR}}/ingest nao existir.
- Falhar se nenhum repositorio puder ser resolvido.
- Falhar se mais de um repositorio permanecer como candidato valido.
- Falhar se repository_identity.md ou _repo_discovery_provenance.md nao existirem ao final.