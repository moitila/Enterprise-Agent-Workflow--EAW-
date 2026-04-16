{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro do EAW responsavel por produzir hipoteses formais e testaveis para o card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Gerar `30_hypotheses.md` antes do planning com Coverage Map explicito, 5 a 10 hipoteses testaveis, ranking formal, provenance e emissao de handoff deterministica.

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
- MODE: quando `EAW_WORKDIR` estiver vazio, saida em `OUT_DIR`; quando definido, saida isolada em `EAW_WORKDIR`.
- EXECUTION_STRUCTURE: `RUNTIME_ROOT` nunca deve ser modificado; `TARGET_REPOS` somente leitura; `CARD_DIR` e o limite unico de escrita da fase.

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/30_hypotheses.md`.
- Ao final da fase, emitir `{{CARD_DIR}}/investigations/10_phase_output.json` e `{{CARD_DIR}}/investigations/20_handoff.json` com envelope deterministico.
- Incluir Coverage Map, hipoteses `H[0-9]+`, testes deterministicos, ranking formal, risco residual, provenance e o passo final `HANDOFF_CODE_EMISSION`.

OUTPUT_STRUCTURE
- `30_hypotheses.md` deve conter obrigatoriamente: `## Coverage Map`, hipoteses `H[0-9]+` (entre 5 e 10), `## Ranking de Prioridade`, `## Risco Residual Apos Mitigacao`, `## Provenance`.
- Cada hipotese deve declarar: tipo de risco, descricao objetiva, causa raiz provavel, criterio(s) coberto(s), impacto e sinais observaveis.
- Cada hipotese deve declarar explicitamente quais outras hipoteses seriam invalidadas caso ela seja confirmada.
- Cada hipotese deve ter teste deterministico com resultado esperado e exit code.
- O documento deve identificar explicitamente uma hipotese `DOMINANTE`.

HANDOFF_CODE_EMISSION
- Emitir `10_phase_output.json` com o envelope minimo deterministico:
  - `phase_id`: `hypotheses`
  - `status`: `completed`
  - `summary`: resumo curto da hipotese dominante, do code de handoff e das validacoes que sustentam a saida
- Emitir `20_handoff.json` com o envelope de orquestracao:
  - `from_phase`: `hypotheses`
  - `status`: `completed`
  - `messages`: `[]`
  - `codes`: `[]` ou `["NO_DOMINANT_HYPOTHESIS"]` quando todas as hipoteses forem informacionais
- Tratar `NO_DOMINANT_HYPOTHESIS` como o code canonico publicado para ausencia de hipotese dominante.
- Tratar `HYPOTHESES_NOT_REQUIRED` como drift de backlog e nao publica-lo neste contrato.

READ_SCOPE
- Ler `{{CARD_DIR}}`.
- Ler TARGET_REPOS apenas em modo read-only quando necessario para evidencias complementares.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/30_hypotheses.md`.

RULES
- Executar pre-check em fail-fast:
  - `set -euo pipefail`
  - `cd "{{RUNTIME_ROOT}}"`
  - `test -f ./scripts/eaw`
  - `test -f "{{CONFIG_SOURCE}}"`
- Confirmar existencia de `{{CARD_DIR}}/investigations/00_intake.md` e `{{CARD_DIR}}/investigations/20_findings.md`; se faltar qualquer um, abortar.
- PASSO 1 - EXTRACAO FORMAL:
  - Extrair criterios de aceite, regras deterministicas, comportamentos esperados, comportamentos observados divergentes e contratos de erro.
  - Criar secao `## Coverage Map` listando cada criterio identificado.
  - Incluir no Coverage Map, quando identificados em findings, criterios de adequacao para cenarios de debugging, comportamento de runtime e impacto de mudancas estruturais.
- PASSO 2 - GERACAO DE HIPOTESES:
  - Criar entre 5 e 10 hipoteses no formato `H[0-9]+` (ex.: H1, H2, H3).
  - Para cada hipotese `H[0-9]+`, registrar tipo de risco, descricao objetiva, causa raiz provavel, criterio(s) coberto(s), impacto e sinais observaveis.
  - Aplicar a secao `### DISCRIMINACAO OBRIGATORIA`.
  - Para cada hipotese `H[0-9]+`, declarar quais outras hipoteses seriam invalidadas se ela for confirmada.
  - E proibido criar hipoteses que nao possam ser distinguidas por teste.
  - Aplicar a secao `### REDUCAO DE ESPACO`.
  - O conjunto de hipoteses deve cobrir todas as evidencias relevantes e minimizar sobreposicao.
  - Hipoteses redundantes devem ser eliminadas.
- PASSO 3 - TESTE DETERMINISTICO:
  - Para cada hipotese `H[0-9]+`, definir comando ou cenario controlado.
  - Para cada hipotese `H[0-9]+`, definir resultado esperado com exit code, prefixo textual, presenca ou ausencia de arquivo ou comportamento verificavel.
  - Aplicar a secao `### TESTES DISCRIMINATORIOS`.
  - Cada teste deve confirmar a hipotese alvo e invalidar pelo menos uma outra hipotese.
  - Caso contrario, a hipotese deve ser reescrita.
- PASSO 4 - RANKING FORMAL:
  - Criar ranking ordenado `H[0-9]+ - probabilidade x impacto - justificativa objetiva`.
  - Aplicar a secao `### HIPOTESE DOMINANTE`.
  - O agente deve identificar a hipotese com maior poder explicativo.
  - O agente deve justificar por que ela cobre mais evidencias com menos suposicoes.
  - Esta hipotese deve ser destacada como `DOMINANTE`.
- PASSO 5 - RISCO RESIDUAL:
  - Adicionar secao `## Risco Residual Apos Mitigacao`.
- PASSO 6 - PROVENANCE:
  - Adicionar provenance com arquivos lidos, arquivos ignorados com motivo e limitacoes.
- Confirmar explicitamente que nenhuma decisao de implementacao foi tomada.
- VALIDACOES FINAIS:
  - Validar `test -f "{{CARD_DIR}}/investigations/30_hypotheses.md"`.
  - Confirmar Coverage Map presente.
  - Confirmar ranking presente.
  - Confirmar provenance presente.
  - Confirmar que apenas `30_hypotheses.md` foi alterado.

FORBIDDEN
- Nao alterar codigo.
- Nao criar arquivos adicionais.
- Nao remover headings do template.
- Nao produzir menos de 5 ou mais de 10 hipoteses.
- Nao usar testes subjetivos.
- Nao manter hipoteses indistinguiveis por teste.
- Nao manter hipoteses redundantes ou com sobreposicao nao justificada.
- Nao violar a fronteira operacional da fase (detalhada em FAIL_CONDITIONS).
- Nao tomar decisoes de solucao nesta fase.

FAIL_CONDITIONS
- Falhar em qualquer erro de pre-check ou comando critico (fail-fast).
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `{{CARD_DIR}}/investigations/30_hypotheses.md` nao existir ao final.
- Falhar em qualquer tentativa de leitura fora de `{{CARD_DIR}}` e TARGET_REPOS.
- Falhar se qualquer arquivo alem de `30_hypotheses.md` for alterado.
