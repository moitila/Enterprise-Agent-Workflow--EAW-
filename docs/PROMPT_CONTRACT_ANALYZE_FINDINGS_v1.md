# PROMPT CONTRACT ANALYZE FINDINGS v1
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Analyze subphase `findings`
Applies to: `eaw analyze` -> `investigations/findings_agent_prompt.md`

---

## 1. Objetivo

Este documento define o contrato estrutural obrigatorio da subfase Findings dentro de Analyze.

Seu proposito e:

- Garantir que a primeira subfase da Analyze produza evidencias auditaveis em `investigations/20_findings.md`
- Restringir leitura e escrita ao perimetro observado do card atual
- Preservar a separacao entre investigacao factual, hipoteses e planejamento
- Registrar a whitelist de escrita e as condicoes de falha observadas no runtime

## 2. Artefatos de Entrada e Saida

| Categoria | Caminho | Regra |
| --- | --- | --- |
| Entrada obrigatoria | `investigations/00_intake.md` | Deve existir antes do inicio da subfase |
| Artefato runtime | `investigations/findings_agent_prompt.md` | Prompt auxiliar emitido por `eaw analyze` |
| Saida obrigatoria | `investigations/20_findings.md` | Consolida contexto confirmado, evidencias, criterios, comportamentos, divergencias e lacunas |
| Saida opcional | `investigations/_warnings.md` | Permitida somente se a subfase precisar registrar warnings |

## 3. READ_SCOPE

- Ler `CARD_DIR` inteiro.
- Ler TARGET_REPOS apenas em modo read-only.
- Ler logs, codigo e documentacao somente para extrair evidencias factuais.
- Tratar `investigations/00_intake.md` como entrada obrigatoria da subfase.

## 4. WRITE_SCOPE

- Escrever somente `investigations/20_findings.md`.
- `investigations/_warnings.md` e opcional, condicionado ao prompt gerado e ao comportamento observado do runtime quando houver necessidade de registrar warnings.
- Qualquer tentativa de escrita fora dessa whitelist deve falhar.

## 5. Regras Obrigatorias

- Executar o pre-check com `cd "$EAW_ROOT_DIR"`, `test -f ./scripts/eaw` e `test -f "$CONFIG_SOURCE"`.
- Confirmar a existencia de `investigations/00_intake.md`; se faltar, bloquear a subfase.
- Executar baseline com `EAW_WORKDIR` apontando para o workspace ativo, seguido de `./scripts/eaw doctor` e `./scripts/eaw validate`.
- Produzir `20_findings.md` com estrutura equivalente ao template e ao prompt ativos, preservando as secoes observadas para contexto confirmado, evidencias coletadas, criterios de aceite identificados, comportamentos observados, divergencias identificadas e lacunas de informacao.
- Em cada evidencia, registrar arquivo, comando executado, trecho relevante e interpretacao objetiva.
- Retornar rastreabilidade de execucao com arquivos lidos, arquivos alterados, saida literal dos testes e confirmacao de que nenhuma hipotese ou plano foi criado.

## 6. Condicoes de Falha

- Ausencia de `./scripts/eaw` no `RUNTIME_ROOT`.
- Ausencia de `CONFIG_SOURCE`.
- Ausencia de `investigations/00_intake.md`.
- Falha em produzir `investigations/20_findings.md` ao final.
- Qualquer tentativa de escrita fora do WRITE_SCOPE.
- Qualquer introducao de hipotese, plano ou sugestao de implementacao nesta subfase.

## 7. Dependencias de Runtime

- Runtime root: `EAW-tool/scripts/eaw`
- Implementacao observada da fase: `scripts/commands/cmd_analyze.sh`
- Template versionado da subfase: `templates/prompts/pt-br/analyze/Findings.txt`
- Contrato consolidado complementar: `docs/PROMPT_CONTRACT_ANALYZE_v1.md`

## 8. Limitacoes Conhecidas

- A subfase Findings nao decide solucao.
- A subfase Findings nao altera codigo nem contratos publicos.
- A subfase Findings depende da qualidade estrutural do `00_intake.md`.

## 9. Relacao com o Contrato Consolidado

Este documento complementa `PROMPT_CONTRACT_ANALYZE_v1.md` com o detalhamento exclusivo da subfase Findings. Em caso de conflito com o comportamento real do runtime, prevalece a evidencia observada em `cmd_analyze.sh` e no prompt gerado `findings_agent_prompt.md`.

## 10. Status

`PROMPT_CONTRACT_ANALYZE_FINDINGS_v1` define o contrato observavel da subfase Findings na fase Analyze.
