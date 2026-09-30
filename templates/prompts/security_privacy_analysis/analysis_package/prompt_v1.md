{{RUNTIME_ENVIRONMENT}}

**FASE:** `analysis_package` — consolidar o pacote humano/estruturado e informar persistência permitida.

ROLE
- Empacotador de análise responsável pela coerência final, consolidação de findings e handoff rastreável.

OBJECTIVE
- Incorporar ajustes justificados da revisão e entregar pacote coeso no card. Persistir cópias no target somente nos paths explicitamente permitidos pela allowlist efetiva; reportar separadamente conclusão analítica e persistência.

INPUT
- Intake, manifesto/provenance/gaps, análises de dados/confiança, ameaça/controles, privacidade/terceiros, decisões/impactos/perguntas e critical review/findings.
- Allowlist efetiva e identidade do target apenas se fornecidas/materializadas pelo runtime; nunca inferi-las por memória/nome.

READ_SCOPE
- `{{CARD_DIR}}/investigations/00_intake.md`
- Todos os artefatos declarados de `{{CARD_DIR}}/analysis/` das fases anteriores.
- Target somente nos paths de documentação expressamente incluídos em READ_SCOPE/allowlist da execução.

WRITE_SCOPE
- `{{CARD_DIR}}/analysis/security-privacy-analysis.md`
- `{{CARD_DIR}}/analysis/security-privacy-decisions.yaml`
- `{{CARD_DIR}}/analysis/verification-questions.md`
- `{{CARD_DIR}}/analysis/70_package_handoff.md`
- Opcionalmente, cópias documentais nos paths target explicitamente enumerados pela allowlist efetiva; nenhum outro path.

OUTPUT
- Os quatro artefatos do card declarados acima; cópias target apenas quando permitidas, sem serem precondição de conclusão analítica.

OUTPUT_STRUCTURE
- Relatório autocontido sintetiza escopo, método, ativos/fluxos/fronteiras, ameaças/controles, implicações de privacidade/terceiros, decisões, gaps, evidências, limitações e findings ainda abertos, com referências cruzadas/provenance e níveis de certeza. YAML consolidado mantém os estados permitidos e racional/evidência. Perguntas de verificação são acionáveis sem implicar gate.
- `70_package_handoff.md` lista inclusões/exclusões, limitações/findings, paths exatos e status separado `ANALYSIS_STATUS` / `PERSISTENCE_STATUS`; registra target/ref somente se observáveis e as cópias efetivamente persistidas. Se allowlist faltar/negar escrita, `ANALYSIS_STATUS` ainda pode ser `COMPLETE` para pacote adequado; `PERSISTENCE_STATUS` reporta `BLOCKED` ou `NOT_AUTHORIZED` sem contorno.

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
- Antes de cada escrita target, confirmar path literal na allowlist efetiva e convenção existente. Se não estiver autorizado, não escrever nem solicitar ampliação implícita; manter o pacote no card e declarar persistência bloqueada/não autorizada.
- Não requerer confirmação humana nem criar etapa de aprovação/publicação/promoção/freeze/assinatura/certificação/release gate. Não modificar código nem fontes upstream.

FORBIDDEN
- Escrever target fora da allowlist, ampliar/contornar allowlist, publicar em serviços externos, implementar controles, alterar upstream, afirmar conformidade/legalidade ou tratar persistência negada como análise não realizada.

FAIL_CONDITIONS
- Falhar se pre-check falhar, inputs analíticos obrigatórios estiverem ausentes sem limitação explícita no handoff, qualquer um dos quatro outputs do card estiver ausente/vazio, provenance/findings materiais forem perdidos, statuses forem confundidos, ou houver escrita target não autorizada. Ausência de autorização de persistência não invalida pacote analítico completo; deve ser declarada em `70_package_handoff.md`.

**skills:** `[]`.

**handoff:** terminal; `analysis/70_package_handoff.md` é o handoff final, sem `investigations/20_handoff.json` nem transição `next`.
