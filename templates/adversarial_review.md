---
type: adversarial_review
card: {{CARD}}
title: "{{TITLE}}"
date: {{DATE}}
---

# Revisao Adversarial

Auditar se as conclusoes, criterios de aceite e status final declarados de um
card alvo ja executado sao sustentados pela evidencia produzida e pelo
comportamento observavel do sistema.

# Card Alvo

Identificar o card alvo desta revisao (ID, track, localizacao esperada) em
`ingest/raw_card_explication.md` e `investigations/00_intake.md`.

# Escopo

Leitura-primaria, fail-closed, nao-destrutiva por padrao. Nenhuma execucao
real de tecnica adversarial sem allowlist explicita, rollback deterministico,
baseline validado e evidencia preservavel. Esta track nunca cria
automaticamente o card de remediacao recomendado.

# Fases da Track

case_reconstruction, evidence_audit, adversarial_design,
adversarial_execution, verdict, remediation_handoff.

# Restricoes Operacionais

- Nao alterar codigo, comitar ou dar push durante a revisao.
- Nao redesenhar as fases da track nem adicionar fase nova a partir deste
  card.

# Evidencia

Referencias aos artefatos `audit/*.md` produzidos por cada fase da track,
usados como base do veredito multi-eixo e da recomendacao final.
