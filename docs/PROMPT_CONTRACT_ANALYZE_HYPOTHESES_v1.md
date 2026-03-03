# PROMPT CONTRACT ANALYZE HYPOTHESES v1
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Analyze subphase `hypotheses`
Applies to: `eaw analyze` -> `investigations/hypotheses_agent_prompt.md`

---

## 1. Objetivo

Este documento define o contrato estrutural obrigatorio da subfase Hypotheses dentro de Analyze.

Seu proposito e:

- Formalizar a geracao de `investigations/30_hypotheses.md` com coverage map, hipoteses H#, ranking e provenance
- Garantir que a subfase trabalhe apenas sobre intake e findings ja concluidos
- Preservar rastreabilidade entre criterios, riscos, testes deterministicos e hipoteses
- Impedir que a subfase tome decisoes de implementacao

## 2. Artefatos de Entrada e Saida

| Categoria | Caminho | Regra |
| --- | --- | --- |
| Entrada obrigatoria | `investigations/00_intake.md` | Deve existir antes do inicio da subfase |
| Entrada obrigatoria | `investigations/20_findings.md` | Deve existir antes do inicio da subfase |
| Artefato runtime | `investigations/hypotheses_agent_prompt.md` | Prompt auxiliar emitido por `eaw analyze` |
| Saida obrigatoria | `investigations/30_hypotheses.md` | Registra coverage map, hipoteses H#, ranking, risco residual e provenance |

## 3. READ_SCOPE

- Ler `CARD_DIR` inteiro.
- Ler TARGET_REPOS apenas em modo read-only quando necessario para evidencias complementares.
- Ler `investigations/00_intake.md` e `investigations/20_findings.md` como base obrigatoria.

## 4. WRITE_SCOPE

- Escrever somente `investigations/30_hypotheses.md`.
- Nenhum outro arquivo pode ser alterado durante a subfase.

## 5. Regras Obrigatorias

- Executar o pre-check com `cd "$EAW_ROOT_DIR"`, `test -f ./scripts/eaw` e `test -f "$CONFIG_SOURCE"`.
- Confirmar a existencia de `investigations/00_intake.md` e `investigations/20_findings.md`; se faltar qualquer um, abortar.
- Criar a secao `## Coverage Map` listando os criterios identificados.
- Produzir entre 5 e 10 hipoteses H#.
- Em cada H#, registrar tipo de risco, descricao objetiva, causa raiz provavel, criterio(s) coberto(s), impacto e sinais observaveis.
- Para cada H#, definir comando ou cenario controlado e resultado esperado com exit code, prefixo textual, presenca ou ausencia de arquivo e comportamento verificavel.
- Produzir ranking formal ordenado e secao `## Risco Residual Apos Mitigacao`.
- Adicionar provenance com arquivos lidos, arquivos ignorados com motivo e limitacoes.
- Confirmar explicitamente que nenhuma decisao de implementacao foi tomada.

## 6. Condicoes de Falha

- Ausencia de `./scripts/eaw` no `RUNTIME_ROOT`.
- Ausencia de `CONFIG_SOURCE`.
- Ausencia de qualquer artefato obrigatorio de entrada.
- Falha em produzir `investigations/30_hypotheses.md` ao final.
- Alteracao de qualquer arquivo alem de `30_hypotheses.md`.
- Quantidade de hipoteses fora do intervalo de 5 a 10.
- Ausencia de Coverage Map, ranking ou provenance.

## 7. Dependencias de Runtime

- Runtime root: `EAW-tool/scripts/eaw`
- Implementacao observada da fase: `scripts/commands/cmd_analyze.sh`
- Template versionado da subfase: `templates/prompts/pt-br/analyze/Hipoteses.txt`
- Contrato consolidado complementar: `docs/PROMPT_CONTRACT_ANALYZE_v1.md`

## 8. Limitacoes Conhecidas

- A subfase Hypotheses nao altera codigo.
- A subfase Hypotheses nao cria arquivos adicionais.
- A subfase Hypotheses depende de findings suficientemente evidenciais para gerar testes deterministicos.

## 9. Relacao com o Contrato Consolidado

Este documento complementa `PROMPT_CONTRACT_ANALYZE_v1.md` com o detalhamento exclusivo da subfase Hypotheses. Em caso de conflito com o comportamento real do runtime, prevalece a evidencia observada em `cmd_analyze.sh` e no prompt gerado `hypotheses_agent_prompt.md`.

## 10. Status

`PROMPT_CONTRACT_ANALYZE_HYPOTHESES_v1` define o contrato observavel da subfase Hypotheses na fase Analyze.
