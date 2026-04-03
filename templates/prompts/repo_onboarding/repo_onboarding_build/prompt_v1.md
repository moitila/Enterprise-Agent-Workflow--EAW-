{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro de software senior responsavel por gerar o onboarding estruturado do repositorio do card {{CARD}}.

OBJECTIVE
- Analisar o repositorio resolvido na fase anterior em modo read-only.
- Gerar onboarding estruturado e reutilizavel para agentes.
- Publicar o onboarding no workspace sob {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/.
- Produzir artefatos de analise e manifest do card sem implementar codigo.

INPUT
- CARD={{CARD}}
- TYPE={{TYPE}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- TARGET_REPOS:
{{TARGET_REPOS}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/context/repository_identity.md
  - {{CARD_DIR}}/investigations/00_repo_discovery.md

GLOBAL_CONTEXT
- Ler tambem, quando existirem:
  - /home/user/dev/CCi-Checkstyle/checkstyle.xml
  - /home/user/dev/CCi-Checkstyle/code_style_Intellij.xml

OUTPUT
- Escrever somente:
  - {{CARD_DIR}}/context/onboarding_source_manifest.md
  - {{CARD_DIR}}/investigations/20_repo_onboarding_build.md
- Publicar somente em:
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/00_overview.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/10_architecture.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/20_entrypoints.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/30_data_flow.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/40_integrations.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/50_persistence.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/60_conventions.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/61_code_style_and_lint.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/65_implementation_patterns.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/66_canonical_examples.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/67_reuse_rules.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/70_debug_playbook.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/INDEX.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/provenance.md

READ_SCOPE
- Ler {{CARD_DIR}}.
- Ler o repositorio alvo somente em modo read-only.
- Priorizar README, docs, manifests, configs de build, scripts de automacao e codigo apenas quando necessario para classificar arquitetura, entradas, persistencia, integracoes e padroes reais.

WRITE_SCOPE
- Escrever somente em:
  - {{CARD_DIR}}/context/onboarding_source_manifest.md
  - {{CARD_DIR}}/investigations/20_repo_onboarding_build.md
  - {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/* conforme OUTPUT

RULES
- Executar o pre-check:
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -f "{{CARD_DIR}}/context/repository_identity.md"
  - test -f "{{CARD_DIR}}/investigations/00_repo_discovery.md"
- Ler repository_identity.md e resolver exatamente um repositorio alvo antes de qualquer leitura no codebase.
- Derivar repo_key a partir da identidade resolvida.
- Publicar o onboarding estavel em {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/.
- Sempre basear conclusoes em codigo real e artefatos reais do repositorio.
- Nao responder de forma generica.
- Nao propor modernizacao sem necessidade.
- Nao inventar arquitetura nova.
- Se houver inconsistencia no repo, apontar explicitamente.

OUTPUT_STRUCTURE
- 00_overview.md:
  - resumo executivo do repositorio
  - stack principal
  - objetivo aparente
  - areas principais
- 10_architecture.md:
  - arquitetura real
  - camadas
  - fluxos principais
  - classes/pacotes centrais
- 20_entrypoints.md:
  - entrypoints
  - controllers, listeners, jobs, handlers
  - como o sistema e acessado
- 30_data_flow.md:
  - fluxo tecnico principal
  - entrada -> regra -> persistencia -> integracao
- 40_integrations.md:
  - integracoes externas
  - clients, adaptadores, contratos
- 50_persistence.md:
  - persistencia
  - repositories/DAO
  - entidades
  - acesso a dados
- 60_conventions.md:
  - convencoes locais do repositorio
- 61_code_style_and_lint.md:
  - convencoes globais extraidas de checkstyle/intellij
  - impacto pratico no desenvolvimento
- 65_implementation_patterns.md:
  - padroes locais reais com exemplos concretos
- 66_canonical_examples.md:
  - arquivos/classes modelo para futuras implementacoes
- 67_reuse_rules.md:
  - regras praticas de reutilizacao, aderencia e anti-invencao
- 70_debug_playbook.md:
  - por onde comecar investigacao
  - classes/camadas criticas
  - breakpoints uteis
  - armadilhas comuns
- INDEX.md:
  - navegacao
  - ordem de leitura
  - como usar o onboarding
- provenance.md:
  - card de origem
  - repositorio alvo
  - arquivos publicados
  - fontes consultadas
  - observacoes de estabilidade
- onboarding_source_manifest.md:
  - repo_key
  - caminho publicado no workspace
  - arquivos publicados
  - criterio de publicacao
  - limites observados
- 20_repo_onboarding_build.md:
  - evidencias principais
  - conclusoes observaveis
  - lacunas remanescentes
  - impactos para outras tracks

FORBIDDEN
- Nao alterar codigo.
- Nao criar plano de implementacao.
- Nao escrever onboarding dentro do repositorio alvo.
- Nao escrever fora de {{CARD_DIR}}/context, {{CARD_DIR}}/investigations e {{EAW_WORKDIR}}/context_sources/onboarding/<repo_key>/.

FAIL_CONDITIONS
- Falhar se algum item do pre-check falhar.
- Falhar se a identidade do repositorio continuar ambigua.
- Falhar se qualquer arquivo obrigatorio do onboarding publicado nao existir ao final.
- Falhar se onboarding_source_manifest.md ou 20_repo_onboarding_build.md nao existirem ao final.