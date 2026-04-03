{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro do EAW responsavel por produzir hipoteses formais e testaveis para o card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Gerar `30_hypotheses.md` antes do planning com Coverage Map explicito, 5 a 10 hipoteses testaveis, ranking formal e provenance.

# ONBOARDING CONTEXT (MANDATORY)

Before generating hypotheses, you MUST read the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/schematics-framework/

Priority order:

1. INDEX.md
2. 70_debug_playbook.md
3. 75_rich_editor_and_ckeditor.md (if applicable)
4. 65_implementation_patterns.md
5. 66_canonical_examples.md
6. 67_reuse_rules.md

Usage rules:

- Onboarding MUST be used to understand expected architecture and patterns
- Onboarding MUST be used to identify correct behavior vs incorrect behavior
- Onboarding MUST help map findings to known components and flows
- Onboarding MAY suggest candidate causes, but MUST NOT replace evidence
- Every hypothesis MUST be grounded in findings and validated patterns
- If onboarding contradicts findings, findings take precedence

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
- EXCLUDED_REPOS:
{{EXCLUDED_REPOS}}
- WARNINGS:
{{WARNINGS_BLOCK}}
- REQUIRED_ARTIFACTS:
  - `{{CARD_DIR}}/investigations/00_intake.md`
  - `{{CARD_DIR}}/investigations/20_findings.md`

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/30_hypotheses.md`.

OUTPUT_STRUCTURE
- `30_hypotheses.md` deve conter obrigatoriamente:
  - `## Coverage Map`
  - hipoteses `H[0-9]+` (entre 5 e 10)
  - `## Ranking de Prioridade`
  - `## Risco Residual Apos Mitigacao`
  - `## Provenance`

- Cada hipotese deve declarar:
  - tipo de risco
  - descricao objetiva
  - causa raiz provavel
  - criterio(s) coberto(s)
  - impacto
  - sinais observaveis

- Cada hipotese deve ter teste deterministico com resultado esperado e exit code

READ_SCOPE
- Ler `{{CARD_DIR}}`
- Ler TARGET_REPOS apenas em modo read-only quando necessario

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/30_hypotheses.md`

RULES

- Executar pre-check:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`

- Confirmar existencia de:
  - `00_intake.md`
  - `20_findings.md`

PASSO 1 - EXTRACAO FORMAL

- Extrair:
  - criterios de aceite
  - comportamentos esperados
  - comportamentos observados divergentes
  - contratos de erro

- Criar `## Coverage Map`:

- Cada item deve representar:
  - regra esperada
  - comportamento observado
  - gap identificado

- Usar onboarding para:
  - validar se o comportamento esperado esta alinhado ao framework
  - identificar se o comportamento divergente quebra padrao conhecido

PASSO 2 - GERACAO DE HIPOTESES

- Criar 5 a 10 hipoteses `H1..Hn`

- Cada hipotese deve:

  - derivar diretamente de findings
  - ser consistente com arquitetura do onboarding
  - explicar claramente o gap do Coverage Map

- Tipos comuns de hipotese:
  - erro de transformacao de dados
  - erro de pipeline (entrada → processamento → saida)
  - erro de integracao (ex: CKEditor vs wrapper)
  - erro de configuracao
  - erro de consistencia entre modulos

PASSO 3 - TESTE DETERMINISTICO

- Para cada hipotese:

  - definir cenario controlado
  - definir comando ou acao reproduzivel
  - definir resultado esperado
  - definir criterio objetivo de sucesso/falha (exit code, DOM, log, etc.)

PASSO 4 - RANKING FORMAL

- Ordenar hipoteses por:
  - probabilidade
  - impacto

- Justificar cada posicao com base em:
  - evidencias do findings
  - aderencia ao onboarding

PASSO 5 - RISCO RESIDUAL

- Identificar riscos mesmo apos validacao das hipoteses

PASSO 6 - PROVENANCE

- Listar:
  - arquivos lidos
  - arquivos ignorados
  - limitacoes

VALIDACOES FINAIS

- Confirmar:
  - Coverage Map presente
  - 5–10 hipoteses
  - ranking presente
  - provenance presente
  - apenas 30_hypotheses.md foi escrito

- Confirmar explicitamente:
  - nenhuma decisao de implementacao foi tomada

FORBIDDEN
- Nao alterar codigo
- Nao criar arquivos adicionais
- Nao produzir menos de 5 ou mais de 10 hipoteses
- Nao usar testes subjetivos
- Nao tomar decisoes de solucao
- Nao usar onboarding como substituto de evidencia

FAIL_CONDITIONS
- Falhar se pre-check falhar
- Falhar se artefatos obrigatorios nao existirem
- Falhar se `30_hypotheses.md` nao existir ao final
- Falhar se houver leitura fora de escopo
- Falhar se houver escrita fora da whitelist