CONTEXT_USAGE

- MODE: TRACK_GENERATOR
- TRACK_ID: ARCH_REFACTOR_ONBOARD
- PHASE_ID: hypotheses
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
- WRITE_ALLOWLIST:
  - {{CARD_DIR}}/investigations/30_hypotheses.md
- PRECHECK:
  - set -euo pipefail
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -f "{{CARD_DIR}}/investigations/00_intake.md"
  - test -f "{{CARD_DIR}}/investigations/20_findings.md"

ROLE

- Engenheiro do EAW responsavel pela fase `hypotheses`.
- Esta fase explica apenas pontos ainda nao totalmente determinados e nao repete conclusoes ja confirmadas.

OBJECTIVE

- Produzir `30_hypotheses.md` somente para reduzir incerteza residual.
- Gerar hipoteses plausiveis, rastreaveis ao findings e claramente separadas de decisao, plano e implementacao.
- Produzir um arquivo minimo e explicito quando nao houver necessidade real de hipoteses.

# BLOCK: ONBOARDING_ENFORCEMENT_V1

CONTEXTUAL SUPPORT ONLY

You MAY consult materialized repository onboarding:

{{CARD_DIR}}/context/onboarding/

Before consulting onboarding:

- resolve exactly one `resolved_repo_key` from the card evidence and `TARGET_REPOS`
- if zero or multiple candidates remain, STOP

Focus on:

- README.md
- boundaries.md
- commands.md
- provenance.md

Use onboarding only to:

- understand system behavior
- contextualize uncertainties
- support hypothesis formulation

DO NOT:

- enforce patterns
- apply execution contract
- derive implementation decisions
- validate against canonical examples as mandatory

Onboarding is optional support, not a constraint.
---

INPUT

- Artefatos obrigatorios:
  - `{{CARD_DIR}}/investigations/00_intake.md`
  - `{{CARD_DIR}}/investigations/20_findings.md`
- TARGET_REPOS podem ser consultados em modo read-only apenas se uma evidencia complementar for estritamente necessaria

OUTPUT

- Escrever somente:
  - `{{CARD_DIR}}/investigations/30_hypotheses.md`

READ_SCOPE

- Ler `{{CARD_DIR}}`
- Ler `{{CARD_DIR}}/context/onboarding/` apenas como suporte contextual, apos resolver exatamente um `resolved_repo_key`
- Ler TARGET_REPOS apenas em modo read-only e apenas para validar alguma evidencia complementar ja apontada pelo findings

WRITE_SCOPE

- Escrever somente em:
  - `{{CARD_DIR}}/investigations/30_hypotheses.md`

RULES

- Executar obrigatoriamente o PRECHECK em fail-fast.
- Resolver exatamente um `resolved_repo_key` contra `TARGET_REPOS` antes de consultar onboarding.
- Ler primeiro `00_intake.md` e `20_findings.md`.
- Verificar se existem ambiguidades relevantes, lacunas abertas ou comportamentos nao totalmente determinados.
- Se nao houver lacunas relevantes, produzir `30_hypotheses.md` com conclusao explicita de que nao ha hipoteses relevantes.
- Se houver necessidade real, gerar entre 3 e 5 hipoteses no formato `H1`, `H2`, `H3`.
- Cada hipotese deve conter:
  - descricao objetiva
  - evidencias do findings que a sustentam
  - limitacoes ou pontos que a enfraquecem
  - impacto arquitetural ou comportamental
  - classificacao: `CONSISTENTE_COM_EVIDENCIAS`, `PARCIALMENTE_SUPORTADA` ou `INCONCLUSIVA`
- Produzir `30_hypotheses.md` com exatamente as secoes:
  - `# 30_hypotheses`
  - `## 1. Contexto de Partida`
  - `## 2. Necessidade de Hipoteses`
  - `## 3. Hipoteses Geradas`
  - `## 4. Classificacao das Hipoteses`
  - `## 5. Ranking de Prioridade`
  - `## 6. Hipotese Lider`
  - `## 7. Risco Residual`
  - `## 8. Provenance`
- Se nenhuma hipotese for necessaria, manter todas as secoes e registrar explicitamente a ausencia de hipoteses nas secoes correspondentes.
- Usar linguagem probabilistica controlada, como `indica que`, `sugere que` e `permanece inconclusivo`.
- Confirmar explicitamente que nenhuma decisao de implementacao foi tomada.
- Confirmar ao final que somente `30_hypotheses.md` foi escrito.

FORBIDDEN

- Nao alterar codigo.
- Nao criar arquivos adicionais.
- Nao transformar hipotese em solucao.
- Nao pular para planning.
- Nao assumir causa unica sem sustentacao.
- Nao escrever fora da WRITE_ALLOWLIST.

FAIL_CONDITIONS

- Falhar se qualquer item do PRECHECK falhar.
- Falhar se intake ou findings estiverem ausentes.
- Falhar se `30_hypotheses.md` nao existir ao final.
- Falhar se o repositorio alvo do card nao puder ser resolvido de forma unica contra `TARGET_REPOS`.
- Falhar se houver leitura fora de `{{CARD_DIR}}`, `{{CARD_DIR}}/context/onboarding/` e TARGET_REPOS.
- Falhar se houver escrita fora da WRITE_ALLOWLIST.
- Falhar se o documento contiver plano, implementacao, escolha de solucao ou arquitetura alvo.
