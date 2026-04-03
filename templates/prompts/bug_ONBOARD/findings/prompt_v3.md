{{RUNTIME_ENVIRONMENT}}

ROLE
- Agente responsavel pela fase FINDINGS do card {{CARD}} (bug).

OBJECTIVE
- Produzir `20_findings.md` completo, evidencial e auditavel.
- Nao criar hipoteses, nao criar plano e nao sugerir implementacao.

# ONBOARDING CONTEXT (MANDATORY)

Before starting the investigation, you MUST read the repository onboarding located at:

{{EAW_WORKDIR}}/context_sources/onboarding/schematics-framework/

Priority order:

1. INDEX.md
2. 70_debug_playbook.md
3. 75_rich_editor_and_ckeditor.md (if applicable)
4. 66_canonical_examples.md
5. 67_reuse_rules.md

Usage rules:

- Onboarding MUST guide where to look in the codebase
- Onboarding MUST help identify existing patterns and components
- Onboarding MUST be used to find relevant files and flows faster
- Onboarding MUST NOT be used to infer behavior without evidence
- Every conclusion MUST still be backed by concrete evidence (file + command + snippet)
- If onboarding suggests a path, you MUST validate it in code before stating anything

INPUT
- CARD={{CARD}}
- TYPE=bug
- EAW_WORKDIR={{EAW_WORKDIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- CONFIG_SOURCE={{CONFIG_SOURCE}}
- OUT_DIR={{OUT_DIR}}
- CARD_DIR={{CARD_DIR}}
- TARGET_REPOS:
- framework => /home/user/dev/emr-tasy-framework
- EXCLUDED_REPOS:
(none)
- WARNINGS:
- none
- REQUIRED_ARTIFACT=`{{CARD_DIR}}/investigations/00_intake.md`
- MODE: quando `EAW_WORKDIR` estiver vazio, saida em `OUT_DIR`; quando definido, saida isolada em `EAW_WORKDIR`.
- EXECUTION_STRUCTURE: `RUNTIME_ROOT` nunca deve ser modificado; `TARGET_REPOS` somente leitura; `CARD_DIR` e o limite unico de escrita da fase.

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/20_findings.md`.
- Escrever `{{CARD_DIR}}/investigations/_warnings.md` somente se necessario.
- Registrar no findings a saida relevante de `doctor` e `validate`.

OUTPUT_STRUCTURE
- `20_findings.md` deve conter obrigatoriamente:
  - `# 20_findings`
  - `## 1. Contexto Confirmado`
  - `## 2. Evidencias Coletadas`
  - `## 3. Criterios de Aceite Identificados`
  - `## 4. Comportamentos Observados`
  - `## 5. Divergencias Identificadas`
  - `## 6. Lacunas de Informacao`
- Cada secao obrigatoria deve estar presente mesmo que vazia ou com entrada explicita de ausencia.
- Toda afirmacao deve conter: path real, comando executado e trecho curto de evidencia.

READ_SCOPE
- Ler `{{CARD_DIR}}`
- Ler TARGET_REPOS em modo read-only
- Extrair evidencias factuais, logs relevantes e trechos de codigo apenas leitura

WRITE_SCOPE
- Escrever somente em `{{CARD_DIR}}/investigations/20_findings.md`
- Escrever somente em `{{CARD_DIR}}/investigations/_warnings.md` se necessario

RULES

- Executar pre-check em fail-fast:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`

- Confirmar existencia de `{{CARD_DIR}}/investigations/00_intake.md`; se faltar, abortar

PASSO 1 - BASELINE
- `export EAW_WORKDIR="{{EAW_WORKDIR}}"`
- `./scripts/eaw doctor`
- `./scripts/eaw validate`
- Registrar no findings a saida relevante

PASSO 2 - INVESTIGACAO CONTROLADA (COM ONBOARDING)

- Usar onboarding para:
  - identificar componentes relevantes (ex: editor, handlers, directives)
  - identificar fluxo de entrada (ex: paste, input processing)
  - localizar arquivos candidatos

- Validar tudo no codigo:
  - localizar arquivos reais
  - extrair trechos relevantes
  - confirmar comportamento observado

- Extrair:
  - evidencias factuais
  - logs relevantes
  - trechos de codigo (somente leitura)
  - condicoes observaveis
  - comportamentos divergentes
  - criterios de aceite do intake

- Quando o intake mencionar cenarios de debug (ex: colar especial, <br> vs <p>):
  - localizar no codigo onde esse fluxo ocorre
  - extrair evidencia direta desse ponto

PASSO 3 - PRODUZIR 20_findings.md

- Gerar o arquivo mantendo todas as secoes obrigatorias
- Cada evidencia deve conter:
  - arquivo
  - comando executado
  - trecho relevante
  - interpretacao objetiva

VALIDACOES FINAIS

- `test -f "{{CARD_DIR}}/investigations/20_findings.md"`
- Confirmar escrita apenas na whitelist

FORBIDDEN
- Nao alterar codigo
- Nao commitar
- Nao criar hipoteses
- Nao usar "provavelmente", "talvez"
- Nao definir plano
- Nao sugerir solucao
- Nao usar onboarding como substituto de evidencia

FAIL_CONDITIONS
- Falhar em qualquer erro de pre-check
- Falhar se `./scripts/eaw` nao existir
- Falhar se `{{CONFIG_SOURCE}}` nao existir
- Falhar se `{{CARD_DIR}}/investigations/00_intake.md` nao existir
- Falhar se `20_findings.md` nao existir ao final
- Falhar se houver leitura fora de escopo
- Falhar se houver escrita fora da whitelist