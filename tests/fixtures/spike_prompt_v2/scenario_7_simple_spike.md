# Cenário 7 — Spike simples: não forçar análise contratual artificial

## Propósito

Demonstrar que os prompts v2 NÃO obrigam uma spike simples e não arquitetural a produzir análise contratual artificial. A track deve continuar simples para investigações comuns.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** A biblioteca `requests` versão 2.31.0 tem regressão no tratamento de redirects em proxies autenticados comparada à versão 2.28.x?
- **Decisão bloqueada:** Não podemos confirmar se atualizar a biblioteca resolve o problema sem verificar o comportamento de redirect.
- **spike_mode:** research (investigação documental/biblioteca externa)
- **Fatos já conhecidos:** requests 2.31.0 é a versão atual; comportamento de redirect com proxy autenticado está quebrando em produção.
- **Alegações não confirmadas:** A regressão pode ser da biblioteca ou da nossa configuração de proxy.

### O que NÃO deve acontecer com os prompts v2

Os prompts v2 NÃO devem exigir:
- Recuperação de contratos arquiteturais do EAW
- "Mapa de fontes e autoridades" sobre contratos de runtime
- Gate de suficiência sobre decisões de runtime/schema
- Hipóteses de categoria "bug no runtime EAW" ou "track incompleta"

### O que DEVE acontecer com os prompts v2

#### hypotheses
- Hipóteses aplicáveis ao caso (ex: regressão na biblioteca, configuração incorreta de proxy, comportamento de HTTP redirect)
- Campo "Evidências faltantes" preenchido com o que ainda não foi verificado
- Campo "Como falsificar" com teste concreto (ex: testar com requests 2.28.x)
- Hipóteses marcadas como "não aplicável" podem ser omitidas (ex: "hipótese de track incompleta" — não se aplica a spike de biblioteca)

#### findings
- Achados documentados com estrutura: Fato observado, Contrato declarado (neste caso: changelog da biblioteca, issue do GitHub), Divergência identificada
- "Contrato declarado": changelog/release notes da requests — não contrato de runtime EAW
- "Intenção recuperada": comportamento documentado da versão anterior
- "Limite da evidência": o que os testes não cobriram

#### technical_decision
- Gate de suficiência respondido de forma proporcional ao caso (pergunta 1: intenção contratual = changelog da biblioteca, não doc EAW)
- Classificação: GO | LIMITED_GO | NO_GO | NEEDS_EVIDENCE aplicada ao caso de biblioteca
- Nenhuma exigência de "aprovação arquitetural" para usar uma versão de biblioteca

#### backlog_handoff
- Item de backlog de tipo Bug ou Hardening com campos preenchidos para o contexto de biblioteca
- Sem exigência de "mecanismo existente no EAW" — apenas "abordagem existente no projeto"

## Saída esperada

Os prompts v2 permitem que esta spike complete todas as fases sem:
- Análise contratual arquitetural artificial
- Hipóteses inaplicáveis forçadas
- Gate de suficiência disproportional ao caso

A qualidade da track é medida pela precisão da decisão — não pela quantidade de contratos EAW consultados.
