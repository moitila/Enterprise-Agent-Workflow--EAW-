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

OUTPUT
- Escrever somente `{{CARD_DIR}}/investigations/30_hypotheses.md`.
- Incluir Coverage Map, hipoteses H#, testes deterministicos, ranking formal, risco residual e provenance.

READ_SCOPE
- Ler `{{CARD_DIR}}`.
- Ler TARGET_REPOS apenas em modo read-only quando necessario para evidencias complementares.

WRITE_SCOPE
- Escrever somente `{{CARD_DIR}}/investigations/30_hypotheses.md`.

RULES
- Executar o pre-check: `cd "{{RUNTIME_ROOT}}"`, `test -f ./scripts/eaw` e `test -f "{{CONFIG_SOURCE}}"`.
- Confirmar existencia de `{{CARD_DIR}}/investigations/00_intake.md` e `{{CARD_DIR}}/investigations/20_findings.md`; se faltar qualquer um, abortar.
- Extrair criterios de aceite, regras deterministicas, comportamentos esperados, comportamentos observados divergentes e contratos de erro.
- Criar secao `## Coverage Map` listando cada criterio identificado.
- Criar entre 5 e 10 hipoteses H#; para cada uma registrar tipo de risco, descricao objetiva, causa raiz provavel, criterio(s) coberto(s), impacto e sinais observaveis.
- Para cada H#, definir comando ou cenario controlado e resultado esperado com exit code, prefixo textual, presenca ou ausencia de arquivo ou comportamento verificavel.
- Criar ranking ordenado `H# - probabilidade x impacto - justificativa objetiva`.
- Adicionar secao `## Risco Residual Apos Mitigacao`.
- Adicionar provenance com arquivos lidos, arquivos ignorados com motivo e limitacoes.
- Considerar concluido apenas se `30_hypotheses.md` existir, tiver Coverage Map, ranking, provenance e apenas esse arquivo tiver sido alterado.
- Confirmar explicitamente que nenhuma decisao de implementacao foi tomada.

FORBIDDEN
- Nao alterar codigo.
- Nao criar arquivos adicionais.
- Nao remover headings do template.
- Nao produzir menos de 5 ou mais de 10 hipoteses.
- Nao usar testes subjetivos.
- Nao tomar decisoes de solucao nesta fase.

FAIL_CONDITIONS
- Falhar se `./scripts/eaw` nao existir em `{{RUNTIME_ROOT}}`.
- Falhar se `{{CONFIG_SOURCE}}` nao existir.
- Falhar se qualquer artefato obrigatorio estiver ausente.
- Falhar se `{{CARD_DIR}}/investigations/30_hypotheses.md` nao existir ao final.
- Falhar se qualquer arquivo alem de `30_hypotheses.md` for alterado.
