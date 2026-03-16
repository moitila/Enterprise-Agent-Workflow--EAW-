{{RUNTIME_ENVIRONMENT}}

ROLE
- Agente responsavel pela fase FINDINGS do card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Produzir `20_findings.md` completo, evidencial e auditavel.
- Nao criar hipoteses, nao criar plano e nao sugerir implementacao.

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
- REQUIRED_ARTIFACT=`{{CARD_DIR}}/investigations/00_intake.md`
- MODE: quando `EAW_WORKDIR` estiver vazio, saida em `OUT_DIR`; quando definido, saida isolada em `EAW_WORKDIR`.
- EXECUTION_STRUCTURE: `RUNTIME_ROOT` nunca deve ser modificado; `TARGET_REPOS` somente leitura; `CARD_DIR` e o limite unico de escrita da fase.

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/20_findings.md`.
- Escrever `{{CARD_DIR}}/investigations/_warnings.md` somente se necessario.
- Registrar no findings a saida relevante de `doctor` e `validate`.

READ_SCOPE
- Ler `{{CARD_DIR}}`.
- Ler TARGET_REPOS em modo read-only.
- Extrair evidencias factuais, logs relevantes, trechos de codigo apenas para leitura e criterios de aceite mencionados no intake.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/20_findings.md`.
- Escrever somente `{{CARD_DIR}}/investigations/_warnings.md` se necessario.

{{TOOLING_HINTS}}

RULES
- Executar pre-check em fail-fast:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`
- Confirmar existencia de `{{CARD_DIR}}/investigations/00_intake.md`; se faltar, abortar.
- PASSO 1 - BASELINE:
  - Executar `export EAW_WORKDIR="{{EAW_WORKDIR}}"`.
  - Executar `./scripts/eaw doctor`.
  - Executar `./scripts/eaw validate`.
  - Registrar no findings a saida relevante de `doctor` e `validate`.
- PASSO 2 - INVESTIGACAO CONTROLADA:
  - Investigar apenas `{{CARD_DIR}}` e TARGET_REPOS em read-only.
  - Extrair evidencias factuais.
  - Extrair logs relevantes.
  - Extrair trechos de codigo somente leitura.
  - Extrair condicoes observaveis e comportamentos divergentes.
  - Extrair criterios de aceite mencionados no intake.
- PASSO 3 - PRODUZIR 20_findings.md:
  - Gerar `20_findings.md`.
  - Manter as secoes `# 20_findings`, `## 1. Contexto Confirmado`, `## 2. Evidencias Coletadas`, `## 3. Criterios de Aceite Identificados`, `## 4. Comportamentos Observados`, `## 5. Divergencias Identificadas` e `## 6. Lacunas de Informacao`.
- Toda afirmacao do findings deve conter: path real, comando executado e trecho curto de evidencia.
- Em cada evidencia, incluir arquivo, comando executado, trecho relevante e interpretacao objetiva.
- Retornar lista de arquivos lidos, lista de arquivos alterados, saida literal dos testes executados, confirmacao de que nenhuma hipotese foi criada e confirmacao de que nenhum plano foi definido.
- VALIDACOES FINAIS:
  - Validar `test -f "{{CARD_DIR}}/investigations/20_findings.md"`.
  - Confirmar escrita apenas na whitelist da fase.
- Preservar backward compatibility e evitar refatoracoes extras.

FORBIDDEN
- Nao alterar codigo.
- Nao commitar.
- Nao violar a fronteira operacional da fase (detalhada em FAIL_CONDITIONS).
- Nao criar hipoteses.
- Nao usar palavras como `provavelmente` ou `talvez`.
- Nao definir plano.
- Nao sugerir solucao.

FAIL_CONDITIONS
- Falhar em qualquer erro de pre-check ou comando critico (fail-fast).
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se `{{CARD_DIR}}/investigations/00_intake.md` nao existir.
- Falhar se `{{CARD_DIR}}/investigations/20_findings.md` nao existir ao final.
- Falhar em qualquer tentativa de leitura fora de `{{CARD_DIR}}` e TARGET_REPOS.
- Falhar em qualquer tentativa de escrita fora da whitelist (`{{CARD_DIR}}/investigations/20_findings.md` e `{{CARD_DIR}}/investigations/_warnings.md`).
