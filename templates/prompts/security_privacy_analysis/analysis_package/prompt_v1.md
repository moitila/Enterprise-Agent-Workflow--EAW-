{{RUNTIME_ENVIRONMENT}}

**FASE:** `analysis_package` — consolidar o pacote humano/estruturado e informar persistência permitida.

ROLE
- Empacotador de análise responsável pela coerência final, consolidação de findings e handoff rastreável.

OBJECTIVE
- Incorporar ajustes justificados da revisão e entregar pacote coeso no card. Decidir explicitamente um ou mais delivery targets a partir do objetivo e das convenções observáveis; materializar essa decisão no handoff e persistir apenas nos paths derivados pelo helper de delivery.

INPUT
- Intake, manifesto/provenance/gaps, análises de dados/confiança, ameaça/controles, privacidade/terceiros, decisões/impactos/perguntas e critical review/findings.
- Roots candidatos e paths documentais declarados pelo runtime. A seleção desta fase é a única fonte dos delivery targets; o source manifest lista evidências e não escolhe destinos.

READ_SCOPE
- `{{CARD_DIR}}/investigations/00_intake.md`
- Todos os artefatos declarados de `{{CARD_DIR}}/analysis/` das fases anteriores.
- Nos roots role=target listados em `TARGET_DELIVERY_CANDIDATES`, leia somente documentação existente necessária para identificar convenções de destino; não modifique nenhum target durante essa inspeção.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/security-privacy-analysis.md`
- `{{CARD_DIR}}/analysis/security-privacy-decisions.yaml`
- `{{CARD_DIR}}/analysis/verification-questions.md`
- `{{CARD_DIR}}/analysis/70_package_handoff.md`
- Cópias documentais somente nos caminhos exatos derivados de `DELIVERY_TARGETS` pelo helper runtime.

OUTPUT
- Os quatro artefatos do card declarados acima; cópias target apenas quando permitidas, sem serem precondição de conclusão analítica.

OUTPUT_STRUCTURE
- Relatório autocontido sintetiza escopo, método, ativos/fluxos/fronteiras, ameaças/controles, implicações de privacidade/terceiros, decisões, gaps, evidências, limitações e findings ainda abertos, com referências cruzadas/provenance e níveis de certeza. YAML consolidado mantém os estados permitidos e racional/evidência. Perguntas de verificação são acionáveis sem implicar gate.
- `70_package_handoff.md` lista `DELIVERY_TARGETS:` como uma lista YAML de chaves exatas de `TARGET_DELIVERY_CANDIDATES`, inclusões/exclusões, limitações/findings, paths exatos e status separado `ANALYSIS_STATUS` / `PERSISTENCE_STATUS`; registra as cópias efetivamente persistidas. O helper deriva a allowlist somente para essas chaves; um scope.lock explícito pode estreitá-la.
- Declarar campos literais separados `ANALYSIS_STATUS: COMPLETE|INCOMPLETE`, `COVERAGE_STATUS: COMPLETE|GAPS_ACCEPTED`, `REQUIRED_AVAILABLE_NOT_EXAMINED: true|false`, `PERSISTENCE_STATUS: PERSISTED|NOT_AUTHORIZED|NOT_APPLICABLE|BLOCKED|FAILED` e `PERSISTED_PATHS:` com paths exatos ou `none`. `PERSISTED` exige paths confirmados; cobertura requerida disponível sem exame impede `COMPLETE`.

RULES
- Executar pre-check antes de qualquer acao:
  - echo "$PATH" | grep -qE '^(/usr|/bin|/home)' || export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  - cd "{{RUNTIME_ROOT}}"
  - test -f ./scripts/eaw
  - test -f "{{CONFIG_SOURCE}}"
- Ler e escrever apenas nos paths enumerados no escopo da fase e nos limites efetivos injetados pelo runtime. Um arquivo citado por outra fonte nao se torna autorizado por essa citacao.
- Evidencia ausente, conflito ou acesso negado e gap/limitacao, nao blocker automatico da analise inteira; blocker operacional impede somente a operacao dependente.
- Distinguir observacao, inferencia, premissa, proposta e desconhecido; rastrear claims materiais ate fonte identificavel. Nao converter analise em pentest, certificacao, parecer juridico, aprovacao ou gate de release.
- Executar o pre-check comum. Conferir coerência e completar apenas correções justificadas pelos findings; preservar divergências e gaps não resolvidos.
- Examine apenas as convenções documentais relevantes nos roots candidatos permitidos. Escolha um ou mais delivery targets explicitamente e inclua no `70_package_handoff.md` antes de qualquer escrita target:
  ```yaml
  DELIVERY_TARGETS:
    - <repo_key>
  ```
- Use chaves exatas listadas em `TARGET_DELIVERY_CANDIDATES`; não escolha todos por conveniência nem use o source manifest como critério de autorização. Paths de produto são os paths semânticos de `TARGET_DELIVERY_DECLARED_PATHS`, sem o ID do card.
- Para cada documento, calcule o path absoluto sob o target selecionado e use `eaw_delivery_persist_selected_file` do `ANALYSIS_DELIVERY_HELPER`, passando source, destination, `{{CONFIG_SOURCE}}`, o path exato de `ANALYSIS_DELIVERY_PHASE_FILE` listado no runtime block, `{{CARD_DIR}}/implementation/00_scope.lock.md`, `{{CARD}}` e `{{CARD_DIR}}/analysis/70_package_handoff.md`, nessa ordem. O helper valida a seleção contra `repos.conf`, track paths, role=target e scope.lock. Não grave diretamente no target nem crie allowlist manual.
- O helper materializa a `TARGET_DELIVERY_ALLOWLIST` efetiva a partir da seleção explícita; apenas paths exatos nessa allowlist derivada podem ser persistidos.
- Depois da persistência, atualize o handoff com paths exatos e statuses. Não escrever fora dos caminhos derivados pelo helper; preservar contenção do root target.
- Não requerer confirmação humana nem criar etapa de aprovação/publicação/promoção/freeze/assinatura/certificação/release gate. Não modificar código nem fontes upstream.

FORBIDDEN
- Escrever target fora da allowlist, ampliar/contornar allowlist, publicar em serviços externos, implementar controles, alterar upstream, afirmar conformidade/legalidade ou tratar persistência negada como análise não realizada.

FAIL_CONDITIONS
- Falhar se pre-check falhar, inputs analíticos obrigatórios estiverem ausentes sem limitação explícita no handoff, qualquer um dos quatro outputs do card estiver ausente/vazio, provenance/findings materiais forem perdidos, statuses forem confundidos, ou houver escrita target não autorizada. Ausência de autorização de persistência não invalida pacote analítico completo; deve ser declarada em `70_package_handoff.md`.

**skills:** `[]`.

**handoff:** terminal; `analysis/70_package_handoff.md` é o handoff final, sem `investigations/20_handoff.json` nem transição `next`.
