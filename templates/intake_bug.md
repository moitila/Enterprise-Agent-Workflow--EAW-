# 00 Intake

## Contexto

Descreva o problema ou feature a ser implementada.

Inclua:
- objetivo do card
- motivação técnica
- contexto do sistema

---

## Evidências

Liste fatos observáveis que sustentam o problema.

Exemplos:
- caminhos de arquivos
- comportamento do sistema
- logs
- evidência de código

---

## Hipóteses

Liste possíveis explicações técnicas.

Formato:

- H1:
- H2:
- H3:

---

## Impacto esperado

Descreva o impacto esperado da mudança.

Exemplos:

- correção de bug
- melhoria de governança
- simplificação estrutural
- aumento de segurança

---

# CONTRACT FREEZE

Esta seção define o contrato estrutural congelado para evitar ambiguidades.

## Estrutura mínima obrigatória de prompts


ROLE
OBJECTIVE
INPUT
OUTPUT
READ_SCOPE
WRITE_SCOPE
FORBIDDEN
FAIL_CONDITIONS


## Seções opcionais permitidas

Exemplos comuns:


RULES
NOTES
EXAMPLES
GUIDELINES
CONTEXT
ASSUMPTIONS
REFERENCES
SECURITY
CONSTRAINTS


Ausência de seções opcionais **não invalida o prompt**.

---

## Escopo de validação de prompts

O validador deve processar apenas prompts canônicos versionados:


templates/prompts/**/prompt_v*.md


Arquivos fora deste padrão devem ser ignorados.

---

## Classificação de seções desconhecidas

Seção desconhecida:


WARNING


Seção contendo palavra-chave crítica:


ERROR


---

## Palavras-chave críticas

Lista fechada:


OVERRIDE
BYPASS
IGNORE
DISABLE
EXCEPTION
EXECUTE
RUN
SHELL
COMMAND
SCRIPT
WRITE_ANYWHERE
READ_ANYWHERE
TARGET_REPOS
WORKSPACE
ACTIVE_REPO
ACTIVE_REPOS
GLOBAL_WRITE
GLOBAL_READ


---

## Perguntas em aberto

Liste dúvidas que ainda precisam ser resolvidas antes da implementação.

---

## Próximos passos

Definir ações recomendadas para a próxima fase.
