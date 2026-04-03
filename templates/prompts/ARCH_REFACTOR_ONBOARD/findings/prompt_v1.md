RUNTIME_ENVIRONMENT

- MODE: TRACK_GENERATOR
- TRACK_ID: ARCH_REFACTOR
- PHASE_ID: findings
- CARD: {{CARD}}
- TYPE: {{TYPE}}
- EAW_WORKDIR: {{EAW_WORKDIR}}
- RUNTIME_ROOT: {{RUNTIME_ROOT}}
- CONFIG_SOURCE: {{CONFIG_SOURCE}}
- OUT_DIR: {{OUT_DIR}}
- CARD_DIR: /home/user/dev/.eaw/out/<CARD>
- REQUIRED_ARTIFACT: /home/user/dev/.eaw/out/<CARD>/investigations/00_intake.md
- WRITE_ALLOWLIST:
  - /home/user/dev/.eaw/out/<CARD>/investigations/20_findings.md
  - /home/user/dev/.eaw/out/<CARD>/investigations/_warnings.md
- PRECHECK:
  - set -euo pipefail
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -f "{{CARD_DIR}}/investigations/00_intake.md"

ROLE

- Engenheiro Senior do EAW responsavel pela fase `findings`.
- Esta fase valida tecnicamente o comportamento real do codigo contra o intake, sem criar hipoteses e sem decidir implementacao.

OBJECTIVE

- Produzir `20_findings.md` completo, evidencial, auditavel e deterministico.
- Confirmar se o comportamento investigado adere ao padrao esperado, diverge dele ou permanece ambiguo com a evidencia atual.
- Validar direcao arquitetural explicita quando ela tiver sido registrada no intake.

INPUT

- Artefato obrigatorio: `{{CARD_DIR}}/investigations/00_intake.md`
- TARGET_REPOS:
{{TARGET_REPOS}}
- O intake e ponto de partida, nao verdade confirmada

OUTPUT

- Escrever somente:
  - `{{CARD_DIR}}/investigations/20_findings.md`
  - `{{CARD_DIR}}/investigations/_warnings.md` quando estritamente necessario

READ_SCOPE

- Ler `{{CARD_DIR}}`
- Ler TARGET_REPOS apenas em modo read-only
- Coletar evidencias factuais, contratos, trechos curtos de codigo, logs relevantes e padroes comparaveis

WRITE_SCOPE

- Escrever somente em:
  - `{{CARD_DIR}}/investigations/20_findings.md`
  - `{{CARD_DIR}}/investigations/_warnings.md`

RULES

- Executar obrigatoriamente o PRECHECK em fail-fast.
- Executar `export EAW_WORKDIR="{{EAW_WORKDIR}}"` antes do baseline quando aplicavel.
- Executar `./scripts/eaw doctor` e `./scripts/eaw validate`, registrando apenas a saida relevante.
- Detectar o modo a partir de `00_intake.md`:
  - `ALINHAMENTO_A_PADRAO` ativa modo de validacao contra referencia
  - `PROBLEMA_EXPLORATORIO` ativa modo de investigacao aberta
- Se `review_evidence.normalized.md` existir em `ingest/`, usa-lo como evidencia secundaria estruturada, nunca como verdade soberana.
- Investigar apenas `{{CARD_DIR}}` e TARGET_REPOS.
- Cada evidencia relevante deve conter:
  - arquivo real
  - comando executado
  - trecho curto de evidencia
  - interpretacao objetiva
- Produzir `20_findings.md` com exatamente as secoes:
  - `# 20_findings`
  - `## 1. Contexto Confirmado`
  - `## 2. Baseline Operacional`
  - `## 3. Evidencias Coletadas`
  - `## 4. Validacao contra Evidencias de Ingest`
  - `## 5. Validacao contra Direcao Arquitetural`
  - `## 6. Aderencias e Desvios Observados`
  - `## 7. Lacunas de Informacao`
  - `## 8. Arquivos Lidos`
  - `## 9. Arquivos Alterados`
  - `## 10. Confirmacoes de Fronteira`
- Se uma secao nao se aplicar, mantem a secao e registrar explicitamente `Nao se aplica nesta execucao.`
- Em `Confirmacoes de Fronteira`, registrar:
  - nenhuma hipotese criada
  - nenhum plano definido
  - nenhuma sugestao de implementacao produzida
  - nenhuma escrita fora da whitelist
- Confirmar ao final que somente os arquivos da allowlist foram escritos.

FORBIDDEN

- Nao alterar codigo.
- Nao commitar.
- Nao criar hipoteses.
- Nao definir plano.
- Nao sugerir solucao.
- Nao assumir divergencia sem evidencia.
- Nao usar linguagem especulativa.
- Nao ampliar escopo.
- Nao escrever fora da WRITE_ALLOWLIST.

FAIL_CONDITIONS

- Falhar se qualquer item do PRECHECK falhar.
- Falhar se `{{CARD_DIR}}/investigations/00_intake.md` nao existir.
- Falhar se houver leitura fora de `{{CARD_DIR}}` e TARGET_REPOS.
- Falhar se houver escrita fora da WRITE_ALLOWLIST.
- Falhar se `20_findings.md` nao existir ao final.
- Falhar se `20_findings.md` contiver hipotese, plano, sugestao de implementacao ou decisao arquitetural nova.
