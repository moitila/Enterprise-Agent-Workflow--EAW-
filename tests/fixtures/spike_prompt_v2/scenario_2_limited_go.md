# Cenário 2 — LIMITED_GO: Evidência suficiente apenas para parte delimitada

## Propósito

Demonstrar que quando evidência suporta apenas um subconjunto da alternativa proposta, a classificação é LIMITED_GO com escopo explicitamente delimitado no backlog.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** O hardening da skill `eaw_prompt_creator` resolve sozinho a decisão prematura observada, ou é necessário também um catálogo contratual separado?
- **Decisão bloqueada:** Não podemos decidir se criar catálogo contratual sem saber se o hardening da skill existente é suficiente.
- **Critérios de suficiência:** Quando soubermos se o hardening da skill cobre os gaps, e se o catálogo adiciona algo que a skill não pode conter.

### Findings (resumo)
- F-01: `eaw_prompt_creator` skill v1 não possui seção sobre recuperação de contratos antes de formular hipóteses — gap confirmado.
- F-02: Adicionar seção de recuperação de contratos à skill existente resolve o gap F-01 — verificado via comparação de estrutura.
- F-03: Catálogo contratual separado: não existe equivalente no EAW — comparação de alternativas realizada, mecanismo de registry existente poderia ser reutilizado mas não foi projetado para isso.
- **Contrato declarado:** Parcialmente — skill existe, extensão é possível; catálogo separado não tem contrato.
- **Intenção recuperada:** Para skill existente, sim. Para catálogo separado, não recuperada.
- **Limite da evidência:** Não sabemos se o registry poderia absorver catálogo contratual sem refatoração significativa.

### Gate de suficiência
- Hardening da skill: TODAS as 11 perguntas: SIM → **LIMITED_GO** (apenas hardening da skill, não catálogo)
- Catálogo separado: pergunta 1 (intenção recuperada): NÃO; pergunta 8 (evidência para ampliação): NÃO → **NEEDS_EVIDENCE**

## Saída esperada

### technical_decision
- Hardening da skill existente: **LIMITED_GO** — escopo: apenas adicionar seção de recuperação de contratos
- Catálogo contratual separado: **NEEDS_EVIDENCE** — decisão bloqueada
- Gate de suficiência documentado separadamente para cada alternativa

### backlog_handoff
- BL-01: Hardening skill eaw_prompt_creator — Status: LIMITED_GO — Tipo: Hardening — Escopo explicitamente delimitado: "apenas seção de recuperação de contratos, não redesenho completo da skill"
- SP-01: Investigar se registry existente pode absorver catálogo contratual — tipo Spike (derivada de NEEDS_EVIDENCE)
- Nenhum item de feature gerado para o catálogo
