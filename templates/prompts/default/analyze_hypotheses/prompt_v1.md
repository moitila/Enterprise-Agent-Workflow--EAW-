{{RUNTIME_ENVIRONMENT}}

ROLE
- Engenheiro do EAW responsavel por produzir hipoteses formais e testaveis para o card {{CARD}} ({{TYPE}}).

OBJECTIVE
- Gerar `30_hypotheses.md` antes do planning com Coverage Map explicito, 5 a 10 hipoteses testaveis, ranking formal e provenance.

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
- Incluir Coverage Map, hipoteses `H[0-9]+`, testes deterministicos, ranking formal, risco residual e provenance.

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
- PASSO 2 - GERACAO DE HIPOTESES:
  - Criar entre 5 e 10 hipoteses no formato `H[0-9]+` (ex.: H1, H2, H3).
  - Para cada hipotese `H[0-9]+`, registrar tipo de risco, descricao objetiva, causa raiz provavel, criterio(s) coberto(s), impacto e sinais observaveis.
- PASSO 3 - TESTE DETERMINISTICO:
  - Para cada hipotese `H[0-9]+`, definir comando ou cenario controlado.
  - Para cada hipotese `H[0-9]+`, definir resultado esperado com exit code, prefixo textual, presenca ou ausencia de arquivo ou comportamento verificavel.
- PASSO 4 - RANKING FORMAL:
  - Criar ranking ordenado `H[0-9]+ - probabilidade x impacto - justificativa objetiva`.
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
