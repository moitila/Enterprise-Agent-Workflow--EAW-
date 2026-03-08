# PROMPT CONTRACT v1.2
Enterprise Agent Workflow (EAW)

Status: OFFICIAL
Scope: Intake prompt generation
Applies to: `eaw intake`

---

## 1. Objetivo

Este documento define o contrato estrutural obrigatorio para todos os prompts gerados pelo EAW.

Seu proposito e:

- Garantir determinismo
- Evitar divergencia estrutural
- Impedir expansao implicita de escopo
- Assegurar rastreabilidade entre fases
- Controlar leitura e escrita em ambiente multi-repo

Nenhum prompt pode violar este contrato.

---

## 2. Header Oficial (v2.1)

O prompt de `eaw intake` deve iniciar com o HEADER v2.1, sem modificacoes estruturais.

```text
=== EAW INTAKE PROMPT (CARD {{CARD}} | ROUND {{ROUND}}) ===

EAW_WORKDIR={{EAW_WORKDIR}}
RUNTIME_ROOT={{RUNTIME_ROOT}}
CONFIG_SOURCE={{CONFIG_SOURCE}}
OUT_DIR={{OUT_DIR}}
CARD_DIR={{CARD_DIR}}
INTAKE_DIR=out/<CARD>/intake/**
PROVENANCE_FILE=investigations/_intake_provenance.md
EXECUTION_COMMAND=eaw intake {{CARD}}

MODE:
- When EAW_WORKDIR is empty -> outputs under OUT_DIR.
- When EAW_WORKDIR is set -> outputs isolated under EAW_WORKDIR.

EXECUTION BOUNDARY (INTAKE):
- Reading allowed: "$CARD_DIR/intake" only
- Writing allowed: "$CARD_DIR/investigations" only
- Forbidden:
  - Do NOT read TARGET_REPOS
  - Do NOT scan source code
  - Do NOT write outside CARD_DIR for any reason

PRE-CHECK OBRIGATORIO:

cd "$RUNTIME_ROOT" || { echo "ERROR: cannot cd to RUNTIME_ROOT"; exit 2; }
test -f ./scripts/eaw || { echo "ERROR: not in EAW runtime root (missing ./scripts/eaw)"; exit 2; }
test -f "$CONFIG_SOURCE" || { echo "ERROR: missing CONFIG_SOURCE"; exit 2; }
test -d "$CARD_DIR/intake" || { echo "ERROR: missing intake/ directory at $CARD_DIR/intake"; exit 3; }

Qualquer falha -> abortar imediatamente.
```

Este HEADER e soberano para a fase de intake e nao pode ser redefinido por templates de workspace sem manter a mesma estrutura.

## 3. Regras Globais Imutaveis

O prompt de intake nao pode:

- Modificar `RUNTIME_ROOT`
- Escrever fora de `CARD_DIR`
- Ler `TARGET_REPOS`
- Expandir escopo alem do declarado
- Alterar layout estrutural de saida
- Executar automacoes destrutivas
- Criar arquivos nao previstos pela fase

Leitura e escrita ficam restritas ao card atual conforme o header.

## 4. Sequencia Oficial da Trilha (Bug / Feature)

A trilha oficial e:

1. Intake
2. Analyze
3. Implement

Nenhuma fase pode ser executada se suas pre-condicoes nao forem atendidas.

Qualquer nova fase deve ser adicionada explicitamente a esta secao.

## 5. Artefatos e Dependencias

| Fase | Entrada Obrigatoria | Saida Permitida |
| --- | --- | --- |
| Intake | `intake/` | `investigations/00_intake.md` + `investigations/_intake_provenance.md` |
| Analyze | `investigations/00_intake.md` | `investigations/20_findings.md` + `investigations/30_hypotheses.md` + `investigations/40_next_steps.md` |
| Implement | `investigations/40_next_steps.md` | `implementation/00_scope.lock.md` + `implementation/10_change_plan.md` + `implementation/20_patch_notes.md` |

## 6. Rastreabilidade Obrigatoria

O intake deve:

- Conter no header os campos `EAW_WORKDIR`, `RUNTIME_ROOT`, `CONFIG_SOURCE`, `OUT_DIR`, `CARD_DIR`, `INTAKE_DIR`, `PROVENANCE_FILE` e `EXECUTION_COMMAND`
- Restringir leitura a `intake/`
- Restringir escrita a `investigations/`
- Declarar a criacao obrigatoria de `investigations/_intake_provenance.md`

## 7. Principios Obrigatorios

- Determinismo > criatividade
- Evidencia > opiniao
- Plano antes de execucao
- Micro-passos rastreaveis
- Nunca quebrar ambiente existente
- Nunca inferir comportamento nao documentado

## 8. Compatibilidade

Este contrato nao altera:

- CLI externa
- Layout de diretorios
- Modo workspace
- Suporte multi-repo

Backward compatibility preservada.

## 9. Evolucao

Qualquer alteracao neste contrato deve:

- Criar nova versao (`PROMPT_CONTRACT_v2.md`)
- Declarar breaking vs non-breaking
- Atualizar HEADER se necessario
- Atualizar todos os prompts dependentes

## 10. Status

`PROMPT_CONTRACT_v1.2` esta oficialmente ativo.

O prompt de `eaw intake` deve obedecer integralmente a este contrato.
