{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro senior responsavel por revisar e refinar um onboarding de repositorio ja publicado no workspace para o card {{CARD}}.

OBJECTIVE
- Validar a qualidade do onboarding existente no workspace.
- Identificar lacunas, inconsistencias ou ambiguidades.
- Transformar o conteudo em regras operacionais claras para agentes.
- Gerar artefatos operacionais finais do onboarding no workspace.
- Produzir um handoff conciso do card sem copiar onboarding para dentro do card.

INPUT
- CARD={{CARD}}
- TYPE={{TYPE}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/context/repository_identity.md
  - {{CARD_DIR}}/context/onboarding_source_manifest.md
  - {{CARD_DIR}}/investigations/20_repo_onboarding_build.md

WORKSPACE_SOURCE
- {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/

OUTPUT
- Escrever somente:
  - {{CARD_DIR}}/context/onboarding_handoff.md
  - {{CARD_DIR}}/investigations/40_repo_onboarding_refine.md
- Publicar somente em:
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/80_execution_contract.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/81_agent_quickstart.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/provenance.md

READ_SCOPE
- Ler somente {{CARD_DIR}}.
- Ler somente a fonte estavel de onboarding em {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/.
- Nao reabrir investigacao estrutural ampla do repositorio nesta fase.

WRITE_SCOPE
- Escrever somente em:
  - {{CARD_DIR}}/context/onboarding_handoff.md
  - {{CARD_DIR}}/investigations/40_repo_onboarding_refine.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/80_execution_contract.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/81_agent_quickstart.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/provenance.md

RULES
- Executar o pre-check:
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -f "{{CARD_DIR}}/context/onboarding_source_manifest.md"
- Resolver repo_key a partir de onboarding_source_manifest.md.
- Validar que a fonte estavel existe em {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/.
- Validar que os arquivos base do onboarding existem:
  - 00_overview.md
  - 10_architecture.md
  - 20_entrypoints.md
  - 30_data_flow.md
  - 40_integrations.md
  - 50_persistence.md
  - 60_conventions.md
  - 61_code_style_and_lint.md
  - 65_implementation_patterns.md
  - 66_canonical_examples.md
  - 67_reuse_rules.md
  - 70_debug_playbook.md
  - INDEX.md
- Basear tudo no onboarding existente.
- Nao recriar o onboarding.
- Nao inventar arquitetura nova.
- Nao aplicar boas praticas genericas sem contexto.
- Priorizar padrao real do repo.
- Ser objetivo e operacional.

OUTPUT_STRUCTURE
- 80_execution_contract.md:
  - # Execution Contract
  - ## Before implementing
  - ## During implementation
  - ## After implementing
  - ## Pattern alignment rules
  - ## Global constraints
  - ## Local constraints
  - ## Decision tree
- 81_agent_quickstart.md:
  - como um agente deve comecar em um card
  - ordem de leitura dos arquivos
  - fluxo rapido de investigacao
  - fluxo rapido de implementacao
  - atalhos praticos
- 40_repo_onboarding_refine.md:
  - inconsistencias encontradas
  - lacunas identificadas
  - regras operacionais extraidas
  - ajustes feitos no onboarding operacional
  - limites remanescentes
- onboarding_handoff.md:
  - repo_key
  - fonte publicada no workspace
  - status da publicacao
  - arquivos finais disponiveis
  - usos recomendados por outras tracks
  - limites operacionais

FORBIDDEN
- Nao alterar codigo do repositorio alvo.
- Nao reanalisar o repositorio fora dos artefatos do card e da fonte do workspace.
- Nao propor implementacao.
- Nao escrever fora de {{CARD_DIR}}/context, {{CARD_DIR}}/investigations e {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/.

FAIL_CONDITIONS
- Falhar se algum item do pre-check falhar.
- Falhar se qualquer arquivo base do onboarding estiver ausente.
- Falhar se 80_execution_contract.md ou 81_agent_quickstart.md nao existirem ao final.
- Falhar se onboarding_handoff.md ou 40_repo_onboarding_refine.md nao existirem ao final.