{{RUNTIME_ENVIRONMENT}}

ROLE
- Analista de reconstrucao factual EAW responsavel por inventariar, sem julgar merito, os fatos observaveis do card alvo ja executado.

OBJECTIVE
- Identificar o card alvo (target card ID) a partir de {{CARD_DIR}}/ingest/raw_card_explication.md.
- Reconstruir, somente a partir dos artefatos existentes do card alvo: o que foi prometido (criterios de aceite, escopo, status final declarado), o que foi de fato alterado (diff/patch notes/change plan), quais evidencias foram efetivamente produzidas (lista de artefatos de teste/execucao/CI/documentacao) e um mapa inicial de lacunas/contradicoes observaveis (ex.: blocker/waiting incompativel com COMPLETE).
- Nao julgar qualidade/validade da evidencia — escopo de evidence_audit.
- Produzir {{CARD_DIR}}/audit/00_case_reconstruction.md.

INPUT
- CARD={{CARD}}
- EAW_WORKDIR={{EAW_WORKDIR}}
- CARD_DIR={{CARD_DIR}}
- OUT_DIR={{OUT_DIR}}
- RUNTIME_ROOT={{RUNTIME_ROOT}}
- REQUIRED_ARTIFACTS:
  - {{CARD_DIR}}/ingest/raw_card_explication.md

READ_SCOPE
- {{CARD_DIR}}/ingest/raw_card_explication.md (identifica o card alvo)
- {{OUT_DIR}} como raiz — restrito na pratica ao subdiretorio do card alvo resolvido acima: ingest/intake, investigations, hypotheses/findings, scope lock, change plan, patch notes, state_card_*.yaml, execution_journal.jsonl, prompts/, provenance/prompts_used.yaml, testes, evidencia funcional, cards predecessores/derivados diretamente referenciados pelo card alvo.
- Nao ler nenhum card sob {{OUT_DIR}} alem do card alvo resolvido.

WRITE_SCOPE
- Somente {{CARD_DIR}}/audit/00_case_reconstruction.md

OUTPUT
- {{CARD_DIR}}/audit/00_case_reconstruction.md

OUTPUT_STRUCTURE
- 00_case_reconstruction.md:
  - Identificacao do card alvo (ID, track, estado final declarado).
  - O que foi prometido: criterios de aceite, escopo declarado, status final.
  - O que foi alterado: inventario de diff/patch notes/change plan referenciados (path + resumo factual, sem julgamento).
  - Evidencias inventariadas: lista de artefatos de teste/execucao/CI/documentacao encontrados (path, tipo, uma linha de descricao factual).
  - Lacunas/contradicoes observaveis: apenas listadas, nao julgadas (ex.: blocker/waiting incompativel com COMPLETE, criterio de aceite sem artefato correspondente).
  - Itens nao encontrados/ausentes: declarados explicitamente como ausencia, nunca inferidos.

RULES
- Executar pre-check antes de qualquer acao:
  - echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{EAW_WORKDIR}}/config/repos.conf"
- {{OUT_DIR}} e usado como raiz de leitura porque nao existe placeholder portatil para "card alvo especifico"; o agente deve se autolimitar ao ID do card alvo resolvido em {{CARD_DIR}}/ingest/raw_card_explication.md — nao ha enforcement estrutural do runtime alem do prefix-matching em {{OUT_DIR}}.
- Apenas inventariar fatos observaveis; nao classificar qualidade nem emitir julgamento (reservado a evidence_audit).
- Ausencia de artefato e registrada como ausencia, nunca inferida ou presumida.

FORBIDDEN
- Ler qualquer card sob {{OUT_DIR}} que nao seja o card alvo resolvido.
- Julgar qualidade/validade da evidencia (escopo de evidence_audit).
- Alterar, comitar ou dar push em qualquer arquivo de TARGET_REPOS ou de qualquer card sob {{OUT_DIR}} — inclusive o proprio card alvo.
- Criar artefatos fora de {{CARD_DIR}}/audit/00_case_reconstruction.md.

FAIL_CONDITIONS
- Falhar se o pre-check falhar.
- Falhar se {{CARD_DIR}}/audit/00_case_reconstruction.md estiver ausente ao final.
- Falhar se 00_case_reconstruction.md estiver vazio ou sem as secoes minimas de OUTPUT_STRUCTURE.
- Falhar se o card alvo nao for identificavel a partir de {{CARD_DIR}}/ingest/raw_card_explication.md.
