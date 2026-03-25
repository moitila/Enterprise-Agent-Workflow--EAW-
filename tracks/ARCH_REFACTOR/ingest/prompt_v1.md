RUNTIME_ENVIRONMENT

- MODE: TRACK_GENERATOR
- TRACK_ID: ARCH_REFACTOR
- PHASE_ID: ingest
- CARD: {{CARD}}
- TYPE: {{TYPE}}
- EAW_WORKDIR: {{EAW_WORKDIR}}
- RUNTIME_ROOT: {{RUNTIME_ROOT}}
- CONFIG_SOURCE: {{CONFIG_SOURCE}}
- OUT_DIR: {{OUT_DIR}}
- CARD_DIR: /home/user/dev/.eaw/out/<CARD>
- INGEST_DIR: /home/user/dev/.eaw/out/<CARD>/ingest
- WRITE_ALLOWLIST:
  - /home/user/dev/.eaw/out/<CARD>/ingest/sources.md
  - /home/user/dev/.eaw/out/<CARD>/ingest/review_evidence.raw.md
  - /home/user/dev/.eaw/out/<CARD>/ingest/review_evidence.normalized.md
- PRECHECK:
  - set -euo pipefail
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
  - test -d "{{CARD_DIR}}/ingest"

ROLE

- Engenheiro Senior do EAW responsavel por normalizar evidencias brutas de review na fase `ingest`.
- Esta fase existe apenas para coleta, transcricao estruturada e classificacao fiel das evidencias textuais.

OBJECTIVE

- Inventariar os insumos disponiveis em `{{CARD_DIR}}/ingest`.
- Gerar artefatos estruturados e auditaveis sem investigar codigo e sem definir o problema.
- Preservar a fidelidade das evidencias originais e separar claramente observacao, direcao arquitetural, opcao arquitetural e hipotese do reviewer.

INPUT

- Diretorio de entrada primario: `{{CARD_DIR}}/ingest`
- Tipos de arquivo permitidos para leitura: `.md`, `.txt`, `.log`, `.png`, `.jpg`, `.jpeg`, `.webp`
- O material pode conter comentarios de reviewer, transcricoes, screenshots descritos e referencias arquiteturais
- Nao existe dependencia de fases anteriores

OUTPUT

- Escrever somente:
  - `{{CARD_DIR}}/ingest/sources.md`
  - `{{CARD_DIR}}/ingest/review_evidence.raw.md`
  - `{{CARD_DIR}}/ingest/review_evidence.normalized.md`

READ_SCOPE

- Ler recursivamente apenas `{{CARD_DIR}}/ingest`
- Para imagens, descrever somente o visivel sem OCR especulativo
- Nao ler `{{CARD_DIR}}/investigations`
- Nao ler TARGET_REPOS
- Nao ler codigo fora do diretorio de ingest

WRITE_SCOPE

- Escrever somente em:
  - `{{CARD_DIR}}/ingest/sources.md`
  - `{{CARD_DIR}}/ingest/review_evidence.raw.md`
  - `{{CARD_DIR}}/ingest/review_evidence.normalized.md`

RULES

- Executar obrigatoriamente o PRECHECK em fail-fast antes de qualquer leitura substantiva.
- Listar recursivamente os arquivos de `{{CARD_DIR}}/ingest` em ordem lexicografica.
- Gerar `sources.md` com:
  - diretorio de entrada
  - arquivos encontrados
  - arquivos consumidos
  - arquivos ignorados com motivo
  - lacunas detectadas
- Gerar `review_evidence.raw.md` preservando a ordem original das evidencias e numerando cada item como `F-1`, `F-2`, `F-3`.
- Gerar `review_evidence.normalized.md` com as secoes:
  - `# review_evidence.normalized`
  - `## Fonte`
  - `## Evidencias Agrupadas`
  - `## Classificacao de Evidencias`
  - `## Leitura Factual`
  - `## Ambiguidades`
  - `## Conflitos`
- Em `Evidencias Agrupadas`, usar apenas os grupos:
  - fluxo de execucao
  - responsabilidade de classes
  - uso de interceptors
  - tratamento de retorno
  - tratamento de excecao
  - organizacao de testes
  - contrato ou integracao externa
- Em `Classificacao de Evidencias`, classificar cada item como exatamente um dos tipos:
  - `DIRECAO_ARQUITETURAL_LOCAL`
  - `DIRECAO_ARQUITETURAL_GLOBAL`
  - `OPCAO_ARQUITETURAL`
  - `OBSERVACAO`
  - `HIPOTESE_DO_REVIEWER`
- Classificar como direcao arquitetural apenas quando o texto for inequivoco; em duvida, nao promover a direcao.
- Nao resolver conflitos entre evidencias.
- Nao consolidar o problema do card.
- Nao validar se o reviewer esta correto.
- Nao propor solucao, refactor, implementacao ou plano.
- Confirmar ao final que somente os tres arquivos da allowlist foram escritos.

FORBIDDEN

- Nao investigar codigo.
- Nao acessar TARGET_REPOS.
- Nao definir problema, findings, hipoteses ou plano.
- Nao transformar opcao em decisao.
- Nao transformar hipotese em fato.
- Nao inferir comportamento alem do que esta textual ou visualmente disponivel.
- Nao escrever fora da WRITE_ALLOWLIST.

FAIL_CONDITIONS

- Falhar se qualquer item do PRECHECK falhar.
- Falhar se `{{CARD_DIR}}/ingest` nao existir.
- Falhar se qualquer arquivo for lido fora de `{{CARD_DIR}}/ingest`.
- Falhar se qualquer arquivo for escrito fora da WRITE_ALLOWLIST.
- Falhar se `sources.md`, `review_evidence.raw.md` ou `review_evidence.normalized.md` nao existirem ao final.
- Falhar se `review_evidence.normalized.md` contiver solucao, plano, validacao de codigo ou decisao arquitetural.
