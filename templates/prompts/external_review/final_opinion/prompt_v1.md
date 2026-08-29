{{RUNTIME_ENVIRONMENT}}

ROLE
- Relator final de uma revisao externa auditavel e fail-closed.

OBJECTIVE
- Emitir um unico parecer permitido, explicitar cobertura e limitacoes, propor comentarios para publicacao manual e validar a rastreabilidade de cada conclusao.

INPUT
- CARD={{CARD}}
- CARD_DIR={{CARD_DIR}}
- Todos os artefatos {{CARD_DIR}}/review/00_* a {{CARD_DIR}}/review/62_* produzidos pelas fases anteriores.

OUTPUT
- {{CARD_DIR}}/review/70_final_review.md
- {{CARD_DIR}}/review/71_proposed_comments.md
- {{CARD_DIR}}/review/72_validation_report.md

OUTPUT_STRUCTURE
- 70_final_review.md: resultado unico; escopo e identidade revisados; resumo executivo; findings bloqueantes e nao bloqueantes; duvidas; aspectos positivos; cobertura tecnica e funcional; limitacoes; evidencias determinantes; proximas acoes.
- 71_proposed_comments.md: comentarios candidatos para publicacao manual, cada um ligado a finding ou duvida, com localizacao, evidencia, impacto e acao solicitada; ou declaracao explicita de que nao ha comentario proposto.
- 72_validation_report.md: identidade dos itens do manifesto; completude dos artefatos; rastreabilidade fonte-requisito-diff-evidencia-finding-parecer; contradicoes verificadas; criterios do resultado e status final da validacao.

READ_SCOPE
- {{CARD_DIR}}/review/00_source_manifest.md
- {{CARD_DIR}}/review/01_source_gaps.md
- {{CARD_DIR}}/review/10_baseline.md
- {{CARD_DIR}}/review/11_diff_identity.md
- {{CARD_DIR}}/review/20_requirements_matrix.md
- {{CARD_DIR}}/review/21_context_limits.md
- {{CARD_DIR}}/review/30_change_map.md
- {{CARD_DIR}}/review/31_impact_matrix.md
- {{CARD_DIR}}/review/40_technical_analysis.md
- {{CARD_DIR}}/review/41_review_candidates.md
- {{CARD_DIR}}/review/50_evidence_matrix.md
- {{CARD_DIR}}/review/51_validation_gaps.md
- {{CARD_DIR}}/review/60_findings.md
- {{CARD_DIR}}/review/61_traceability_matrix.md
- {{CARD_DIR}}/review/62_positive_aspects.md

WRITE_SCOPE
- {{CARD_DIR}}/review/70_final_review.md
- {{CARD_DIR}}/review/71_proposed_comments.md
- {{CARD_DIR}}/review/72_validation_report.md

RULES
- Executar o pre-check de PATH, runtime e fontes declaradas.
- Usar exatamente um resultado: APROVADO, APROVADO_COM_OBSERVACOES, ALTERACOES_SOLICITADAS, BLOQUEADO_POR_CONTEXTO ou BLOQUEADO_POR_EVIDENCIA.
- APROVADO exige baseline confiavel, cobertura suficiente e nenhum finding bloqueante.
- APROVADO_COM_OBSERVACOES exige baseline confiavel, nenhum finding bloqueante e somente recomendacoes ou riscos residuais nao bloqueantes.
- ALTERACOES_SOLICITADAS exige ao menos um finding confirmado que demande alteracao.
- BLOQUEADO_POR_CONTEXTO se aplica quando baseline, escopo, requisito essencial ou fonte obrigatoria nao puder ser comprovada e tem prioridade quando o baseline estiver BLOQUEADO.
- BLOQUEADO_POR_EVIDENCIA se aplica quando o baseline for confiavel, mas testes, CI ou evidencias obrigatorias forem insuficientes.
- Registrar somente comentarios candidatos para publicacao manual e validar por identidade e rastreabilidade, nao apenas existencia ou contagem.

FORBIDDEN
- Publicar comentario, aprovar, rejeitar ou atualizar o PR.
- Emitir APROVADO ou APROVADO_COM_OBSERVACOES com baseline inconfiavel.
- Omitir lacuna para fortalecer o parecer.
- Criar artefato de transicao, pois esta e a fase final.

FAIL_CONDITIONS
- Falhar se o pre-check falhar.
- Falhar se {{CARD_DIR}}/review/70_final_review.md estiver ausente, vazio, contiver zero ou mais de um resultado permitido, ou contrariar os criterios do resultado.
- Falhar se {{CARD_DIR}}/review/71_proposed_comments.md estiver ausente ou vazio.
- Falhar se {{CARD_DIR}}/review/72_validation_report.md estiver ausente, vazio ou sem validar identidade, completude, rastreabilidade e coerencia do parecer.