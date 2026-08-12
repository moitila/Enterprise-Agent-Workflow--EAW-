# CI Feedback Prompt — {{CARD}} / {{TRACK}} / {{PHASE}}

You have just completed a phase of an EAW card. Write a feedback file at:

  {{EAW_WORKDIR}}/ci_feedback/{{TRACK}}/{{PHASE}}/feedback_{{CARD}}.md

NOTE: A escrita em {{EAW_WORKDIR}}/ci_feedback/ é exceção operacional autorizada ao WRITE_SCOPE desta fase e não requer entrada na WRITE_ALLOWLIST soberana.

Este prompt é entregue pelo runtime apenas quando `ci_feedback_enabled=true`.
Quando desabilitado, o agente não recebe este prompt e nenhum arquivo é criado.

Ao receber este prompt, criar o arquivo de feedback.
Se não houver nenhuma observação relevante, registrar apenas:

  Sem observações no momento. A fase, o prompt e os artefatos funcionaram conforme esperado.

Nesse caso, não preencher outras seções.
Não inventar problemas, elogios, ressalvas ou recomendações para completar o template.

Esta avaliação representa a percepção fundamentada do próprio executor sobre sua
execução — não é auditoria independente. Não declarar garantia absoluta de
correção, completude ou aprovação externa. Use linguagem proporcional à evidência.

**Política de placeholders não-resolvidos:** Se qualquer um destes placeholders
aparecer como literal no prompt — `{{INTAKE_PATH}}`, `{{PROMPT_PATH}}`,
`{{ARTIFACT_PATHS}}`, `{{SUCCESS_CRITERIA}}` — fazer as duas coisas:
1. Registrar o problema em `### Runtime issues` abaixo.
2. Marcar a dimensão afetada como NÃO AVALIÁVEL em `### Lacunas e limitações`.
   Não inventar o valor ausente. Continuar avaliando todas as dimensões possíveis.
   Não usar `NÃO AVALIÁVEL` no resultado global automaticamente — usar
   `APROVADO COM RESSALVAS` quando ao menos uma dimensão central puder ser avaliada.

## Feedback format

---
# CI Feedback — {{CARD}} / {{TRACK}} / {{PHASE}}
Date: [YYYY-MM-DD]

## Feedback operacional

Preencher apenas as subseções onde houver observação. Omitir as demais.

### Prompt issues
[Problemas com o prompt renderizado — instruções ambíguas, contexto ausente, escopo confuso]

### Runtime issues
[Comportamento inesperado do runtime EAW — nomes de artefatos errados, erros de schema, fase bloqueada, placeholders não-resolvidos]

### Missing context
[Contexto que teria ajudado o agente a executar melhor a fase]

### Artifact contract issues
[Nomes errados, violações de schema, scaffolds vazios que deveriam ter sido pré-populados]

### Skill/trap suggestions
[Nova trap a documentar, ajuste de skill, nova regra]

### Suggested backlog items
[Melhorias que justificam um card formal]

### Token/cost observations
[Fase custosa demais, prompt muito longo, iterações desnecessárias]

## Qualidade percebida pelo executor

Preencher apenas se houver crítica construtiva, melhoria concreta ou prática
positiva reutilizável. Preencher somente as subseções aplicáveis, com evidência.
Se não houver observação relevante, omitir esta seção inteira.

Regra de evidência: toda divergência, ressalva ou afirmação deve citar trecho
específico do intake, prompt ou artefato. Nunca afirmações genéricas de conformidade.
Ausência de gap é uma conclusão válida — não criar problemas artificiais.

Contexto de referência (resolvido pelo runtime):
- Intake: {{INTAKE_PATH}}
- Prompt renderizado: {{PROMPT_PATH}}
- Artefatos produzidos: {{ARTIFACT_PATHS}}
- Critérios de sucesso declarados: {{SUCCESS_CRITERIA}}

### Resultado da avaliação

`APROVADO` — nenhum gap material; pedido, prompt e artefato coerentes; critérios
verificáveis cobertos; evidência suficiente.

`APROVADO COM RESSALVAS` — limitações ou gaps pequenos presentes, **ou** avaliação
parcial (ao menos uma dimensão não avaliável por insumo ausente, mas a parte
avaliada não apresenta gap material); continuidade segura sem correção imediata.

`REVISÃO NECESSÁRIA` — requisito não atendido; divergência material entre prompt e
artefato; critério importante não coberto; continuidade **não** é segura antes da
correção.

`NÃO AVALIÁVEL` — usar somente quando os insumos ausentes impedirem qualquer
conclusão global: nenhuma dimensão central pode ser avaliada, não há artefato
avaliável ou o prompt efetivo está indisponível sem base alternativa. Quando ao
menos uma dimensão puder ser avaliada, usar `APROVADO COM RESSALVAS`.

[APROVADO | APROVADO COM RESSALVAS | REVISÃO NECESSÁRIA | NÃO AVALIÁVEL]

### Aderência pedido → prompt

Preencher se houver desvio ou limitação relevante a registrar.
Se {{INTAKE_PATH}} ou {{PROMPT_PATH}} não resolvidos: registrar em
`### Lacunas e limitações` e omitir esta subseção.
Quando preenchida: citar trecho do intake e trecho correspondente do prompt.

### Aderência prompt → artefato

Preencher se houver desvio ou discrepância relevante a registrar.
Se {{PROMPT_PATH}} ou {{ARTIFACT_PATHS}} não resolvidos: registrar em
`### Lacunas e limitações` e omitir esta subseção.
Quando preenchida: citar instrução do prompt e o trecho do artefato que a satisfaz ou viola.

### Critérios de sucesso

Omitir se {{SUCCESS_CRITERIA}} não resolvido (já registrado em `### Runtime issues`)
ou se não há critérios verificáveis na fase atual.
Avaliar apenas critérios aplicáveis ao objetivo, contrato e artefatos desta fase.
Critérios destinados a fases posteriores: classificar como `NÃO APLICÁVEL À FASE`,
não como `NÃO COBERTO`.

Classificar cada critério como:
- `COBERTO` — evidência específica citada (trecho literal do artefato)
- `PARCIALMENTE COBERTO` — cobertura parcial com justificativa
- `NÃO COBERTO` — critério aplicável à fase e ausente no artefato
- `NÃO APLICÁVEL À FASE` — critério do card destinado a fase posterior ou fora do escopo atual
- `NÃO AVALIÁVEL` — impossível verificar por ausência de insumo

### Lacunas e limitações

Escopo: limitações da própria avaliação de qualidade — o que não pôde ser avaliado
e por quê (placeholder não-resolvido, artefato ausente, critério ambíguo).
Distingue-se de `### Missing context` (contexto ausente da execução da fase).
Omitir se a avaliação não teve limitações relevantes.
Quando preenchida: causa específica por limitação.

### Evidências

Para resultado `APROVADO`: citar pelo menos uma evidência mínima que sustente a conclusão.
Para demais resultados: citar evidência verificável por divergência ou ressalva registrada.
Omitir apenas se nenhuma subseção de análise acima foi preenchida.

### Confiança

Preencher quando a seção de qualidade for preenchida. ALTA / MÉDIA / BAIXA com
justificativa referenciando limitações em `### Lacunas e limitações` e evidências
em `### Evidências`. Reduzir confiança quando houver placeholder não-resolvido ou
artefato ausente.

### Recomendação

Preencher quando houver problema ou ressalva que exija ação.
Opcional para `APROVADO`.
Quando preenchida: aprovar / revisar / bloquear com causa específica, alvo da ação,
evidência e próximo passo. Não aceitar recomendações genéricas sem indicar
exatamente o que deve mudar.
---

This feedback file is ADDITIONAL — it does not replace any required phase artifact.
