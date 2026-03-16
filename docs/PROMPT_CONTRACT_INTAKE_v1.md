# PROMPT CONTRACT INTAKE v1
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Intake phase
Applies to: `eaw intake`

---

## 1. Objetivo

Este documento define o contrato observavel da fase Intake no EAW.

Seu proposito e:

- Formalizar o comportamento atual observado do runtime da fase
- Registrar os artefatos obrigatorios e auxiliares produzidos no fluxo
- Explicitar entradas, dependencias, `READ_SCOPE`, `WRITE_SCOPE`, regras obrigatorias e condicoes de falha
- Preservar rastreabilidade entre o contrato documental, o prompt gerado e a implementacao observada

## 2. Artefatos de Entrada e Saida

| Categoria | Caminho | Regra |
| --- | --- | --- |
| Entrada obrigatoria | `out/<CARD>/ingest/` | Quando existir, deve ser tratada como origem primaria dos insumos brutos |
| Compatibilidade de entrada | `out/<CARD>/intake/` | Pode ser usada como fallback temporario durante a transicao |
| Artefato runtime | `out/<CARD>/investigations/intake_agent_prompt.round_<N>.md` | Prompt auxiliar emitido por `eaw intake <CARD> [--round=N]` |
| Saida obrigatoria do fluxo | `out/<CARD>/investigations/00_intake.md` | Artefato preenchido a partir do prompt gerado e das evidencias de `intake/` |
| Saida obrigatoria do fluxo | `out/<CARD>/investigations/_intake_provenance.md` | Proveniencia obrigatoria do intake |

## 3. Inputs Obrigatorios e Dependencias de Runtime

- Runtime root: `EAW-tool/scripts/eaw`
- Implementacao observada da fase: `scripts/commands/cmd_intake.sh`
- Template efetivo observado: `templates/prompts/default/intake/prompt_v{ACTIVE}.md` (resolvido via `ACTIVE`)
- Contrato estrutural complementar do prompt: `docs/PROMPT_CONTRACT_v1.md`
- Configuracao obrigatoria: `config/repos.conf`
- Diretorio primario de entrada por card: `out/<CARD>/ingest/`
- Diretorio de compatibilidade observado por card: `out/<CARD>/intake/`
- Parametro obrigatorio: `<CARD>`
- Parametro opcional observado: `--round=N`

## 4. READ_SCOPE

- Ler `out/<CARD>/ingest/` quando existir e usar `out/<CARD>/intake/` apenas como fallback compativel.
- Consumir arquivos de texto `.md`, `.txt` e `.log` quando instruido pelo prompt ativo.
- Para imagens `.png`, `.jpg`, `.jpeg` e `.webp`, descrever apenas o visivel quando houver consumo pelo agente.
- Nao ler `TARGET_REPOS` na fase Intake.
- Nao investigar source code como parte do intake.

## 5. WRITE_SCOPE

- O runtime observado escreve `out/<CARD>/investigations/intake_agent_prompt.round_<N>.md`.
- O fluxo da fase Intake permite escrita somente em `out/<CARD>/investigations/00_intake.md` e `out/<CARD>/investigations/_intake_provenance.md`.
- Qualquer tentativa de escrita fora de `out/<CARD>/investigations/` deve falhar.

## 6. Regras Obrigatorias

- Executar o pre-check com `cd "$RUNTIME_ROOT"`, `test -f ./scripts/eaw`, `test -f "$CONFIG_SOURCE"` e validar `"$CARD_DIR/ingest"` ou `"$CARD_DIR/intake"` como fonte de entrada.
- Resolver os templates de header e corpo a partir de `EAW_TEMPLATES_DIR`, com fallback para `EAW_ROOT_DIR/templates/` quando necessario.
- Gerar o prompt deterministico em `investigations/intake_agent_prompt.round_<N>.md`.
- Materializar o bloco `RUNTIME_ENVIRONMENT` no inicio do prompt final, mantendo a sequencia imediata `RUNTIME_ENVIRONMENT -> ROLE`.
- Restringir leitura ao perimetro de entrada bruta (`ingest/`, com fallback para `intake/`) e escrita a `investigations/` no prompt gerado.
- Declarar no fluxo de Intake a producao de `investigations/00_intake.md` e `investigations/_intake_provenance.md`.
- Quando a fase de ingest estiver declarada no workflow, tratar `investigations/00_intake.md` como intake estruturado derivado dos insumos brutos, e nao como copia direta do input do usuario.
- Preencher `00_intake.md` somente com fatos observaveis e perguntas abertas reais, conforme o template ativo.
- Registrar em `_intake_provenance.md` os arquivos encontrados, arquivos consumidos, arquivos ignorados com motivo, lacunas detectadas e observacoes de processo.
- Quando definido pelo workflow, registrar a rastreabilidade minima das fontes consolidadas, como `investigations/intake_sources.txt` ou equivalente contratual.

## 7. Condicoes de Falha

- Falha em `cd "$RUNTIME_ROOT"`.
- Ausencia de `./scripts/eaw`.
- Ausencia de `"$CONFIG_SOURCE"`.
- Ausencia simultanea de `"$CARD_DIR/ingest"` e `"$CARD_DIR/intake"`.
- Template de header nao encontrado no path primario nem no fallback.
- Template de body nao encontrado no path primario nem no fallback.
- Uso invalido da CLI fora de `eaw intake <CARD> [--round=N]`.
- Qualquer tentativa de escrita fora do perimetro permitido da fase.

## 8. Fonte de Verdade Observavel do Runtime

O comportamento observavel do runtime desta fase e definido pela implementacao em `scripts/commands/cmd_intake.sh`.

Nessa implementacao observada:

- o comando aceita `<CARD>` e `--round=N`
- o runtime cria `card_dir` e `investigations_dir`
- o prompt final e materializado em `investigations/intake_agent_prompt.round_<N>.md`
- o prompt final inicia com `RUNTIME_ENVIRONMENT` e preserva `ROLE` logo apos o header
- os placeholders `CARD`, `ROUND`, `EAW_WORKDIR`, `RUNTIME_ROOT`, `CONFIG_SOURCE`, `OUT_DIR` e `CARD_DIR` sao resolvidos no prompt gerado

Em caso de conflito entre documentacao auxiliar e o comportamento observado em `scripts/commands/cmd_intake.sh`, prevalece a implementacao observada do runtime em conjunto com o prompt efetivamente gerado.

## 9. Relacao com Outros Contratos

- `docs/PROMPT_CONTRACT_v1.md` permanece como contrato estrutural complementar do prompt de Intake.
- Este documento detalha especificamente a fase Intake e nao altera os contratos das fases Analyze ou Implement.
- Em tracks que declaram `ingest`, a fase Intake passa a representar o intake estruturado gerado a partir da entrada bruta consolidada.

## 10. Limitacoes Conhecidas

- A implementacao observada em `scripts/commands/cmd_intake.sh` materializa diretamente o prompt de round; `00_intake.md` e `_intake_provenance.md` aparecem no fluxo como saidas exigidas pelo prompt ativo.
- Este contrato descreve o comportamento observavel atual e nao amplia escopo, arquitetura ou contratos publicos da CLI.

## 11. Status

`PROMPT_CONTRACT_INTAKE_v1` define o contrato observavel da fase Intake no EAW.
