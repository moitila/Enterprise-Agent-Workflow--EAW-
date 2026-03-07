# PROMPT CONTRACT ANALYZE PLANNING v1
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Analyze subphase `planning`
Applies to: `eaw analyze` -> `investigations/planning_agent_prompt.md`

---

## 1. Objetivo

Este documento define o contrato estrutural obrigatorio da subfase Planning dentro de Analyze.

Seu proposito e:

- Transformar hipoteses formais em um plano executavel minimo em `investigations/40_next_steps.md`
- Preservar rastreabilidade entre hipoteses `H[0-9]+` selecionadas, criterios verificaveis e a fase Implementation
- Impedir que a subfase crie hipoteses novas ou altere findings anteriores
- Registrar as regras de bloqueio, whitelist de escrita e rollback minimo observados na subfase

## 2. Artefatos de Entrada e Saida

| Categoria | Caminho | Regra |
| --- | --- | --- |
| Entrada obrigatoria | `investigations/00_intake.md` | Deve existir antes do inicio da subfase |
| Entrada obrigatoria | `investigations/20_findings.md` | Deve existir antes do inicio da subfase |
| Entrada obrigatoria | `investigations/30_hypotheses.md` | Deve existir antes do inicio da subfase |
| Artefato runtime | `investigations/planning_agent_prompt.md` | Prompt auxiliar emitido por `eaw analyze` |
| Saida obrigatoria | `investigations/40_next_steps.md` | Registra hipoteses `H[0-9]+` selecionadas, objetivo, estrategia, plano atomico, criterios de aceite, riscos e rollback |
| Saida opcional | `investigations/_warnings.md` | Permitida somente se necessario |

## 3. READ_SCOPE

- Ler `CARD_DIR` inteiro.
- Ler TARGET_REPOS somente em modo read-only quando estritamente necessario para checagens factuais.
- Tratar `investigations/00_intake.md`, `investigations/20_findings.md` e `investigations/30_hypotheses.md` como entradas obrigatorias.

## 4. WRITE_SCOPE

- Escrever somente `investigations/40_next_steps.md`.
- Escrever somente `investigations/_warnings.md` se necessario.
- Qualquer tentativa de escrita fora dessa whitelist deve falhar.

## 5. Regras Obrigatorias

- Executar o pre-check com `cd "$EAW_ROOT_DIR"`, `test -f ./scripts/eaw` e `test -f "$CONFIG_SOURCE"`.
- Confirmar a existencia de `00_intake.md`, `20_findings.md` e `30_hypotheses.md`; se qualquer um estiver ausente, bloquear.
- Produzir `40_next_steps.md` com as secoes `# 40_next_steps`, `## Hipotese(s) Selecionada(s)`, `## Objetivo da Iteracao`, `## Estrategia`, `## Plano Atomico`, `## Criterios de Aceite`, `## Riscos e Mitigacao` e `## Rollback`.
- Em `Hipotese(s) Selecionada(s)`, listar explicitamente identificadores `H[0-9]+` extraidos de `30_hypotheses.md`.
- Garantir que cada passo do plano atomico seja deterministico, executavel e reversivel quando aplicavel.
- Garantir que os criterios de aceite tenham comandos verificaveis, exit codes esperados, artefatos esperados e prefixos textuais quando aplicavel.
- Retornar lista de hipoteses `H[0-9]+` selecionadas, confirmacao de escrita unica e saida literal dos testes.

## 6. Condicoes de Falha

- Ausencia de `./scripts/eaw` no `RUNTIME_ROOT`.
- Ausencia de `CONFIG_SOURCE`.
- Ausencia de qualquer artefato obrigatorio de entrada.
- Ausencia da secao `Hipotese(s) Selecionada(s)` em `40_next_steps.md`.
- Ausencia de pelo menos uma hipotese explicita no formato `H[0-9]+`.
- Ausencia de plano estruturado com passos identificaveis.
- Falha em produzir `investigations/40_next_steps.md` ao final.
- Qualquer tentativa de escrita fora do WRITE_SCOPE.

## 7. Dependencias de Runtime

- Runtime root: `EAW-tool/scripts/eaw`
- Implementacao observada da fase: `scripts/commands/cmd_analyze.sh`
- Template efetivo da subfase: `templates/prompts/default/analyze_planning/prompt_v{ACTIVE}.md` (resolvido via `ACTIVE`)
- Contrato consolidado complementar: `docs/PROMPT_CONTRACT_ANALYZE_v1.md`
- Dependencia de saida para a proxima fase: `investigations/40_next_steps.md` como entrada obrigatoria de Implementation

## 8. Limitacoes Conhecidas

- A subfase Planning nao altera codigo.
- A subfase Planning nao cria hipotese nova.
- A subfase Planning deve permanecer aderente ao escopo e as evidencias do intake, sem expandir arquitetura alem do que estiver sustentado pelo fluxo observado.
- A subfase Planning depende da rastreabilidade definida por hipoteses `H[0-9]+` em `30_hypotheses.md`.

## 9. Relacao com o Contrato Consolidado

Este documento complementa `PROMPT_CONTRACT_ANALYZE_v1.md` com o detalhamento exclusivo da subfase Planning. Em caso de conflito com o comportamento real do runtime, prevalece a evidencia observada em `cmd_analyze.sh` e no prompt gerado `planning_agent_prompt.md`.

## 10. Status

`PROMPT_CONTRACT_ANALYZE_PLANNING_v1` define o contrato observavel da subfase Planning na fase Analyze.
