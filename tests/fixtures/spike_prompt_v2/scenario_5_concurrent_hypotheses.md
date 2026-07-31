# Cenário 5 — Hipóteses concorrentes: prompt exige evidências favoráveis, contrárias e falsificação

## Propósito

Demonstrar que o prompt de hypotheses v2 exige avaliação de hipóteses concorrentes com campos obrigatórios: evidências favoráveis, contrárias, faltantes, como falsificar, confiança, risco de aceitar incorretamente.

## Entrada simulada

### Intake (resumo)
- **Pergunta de pesquisa:** Por que a fase `implementation_executor` da track `patch` está bloqueada pelo gate `mandatory_analysis_audit`?
- **Decisão bloqueada:** Não podemos contornar ou corrigir o bloqueio sem entender a causa.

### Hipóteses concorrentes esperadas

#### H01 — Bug no runtime (gate não filtra por track_id)
- **Evidências favoráveis:** Gate usa apenas `phase_id` sem verificar `track_id`.
- **Evidências contrárias:** O gate pode ser intencionalmente global (por design).
- **Evidências faltantes:** Intenção arquitetural do gate — contrato não verificado ainda.
- **Como falsificar:** Encontrar doc que declare "gate deve ser global para todas as tracks".
- **Como validar:** Encontrar doc que declare "gate deve verificar track context".
- **Confiança atual:** MÉDIA — comportamento confirmado, intenção não confirmada.
- **Risco de aceitar incorretamente:** Se aceitarmos que é bug e corrigirmos sem verificar intenção, podemos quebrar invariante intencional.

#### H02 — Track incompleta (patch não declara artefatos investigativos)
- **Evidências favoráveis:** `tracks/patch/phases/implementation_executor.yaml` não declara artefatos investigativos.
- **Evidências contrárias:** O gate pode estar correto e a track patch deveria declarar esses artefatos.
- **Evidências faltantes:** Intenção da track patch — foi projetada para ser "sem investigação"?
- **Como falsificar:** Encontrar doc que diga "tracks sem fase investigativa devem declarar artefatos investigativos".
- **Confiança atual:** MÉDIA.
- **Risco de aceitar incorretamente:** Modificar a track patch para exigir artefatos investigativos em todas as fases patch.

#### H03 — Uso incorreto pelo operador (artefatos não produzidos)
- **Evidências favoráveis:** Artefatos investigativos ausentes no card.
- **Evidências contrárias:** A track patch não exige esses artefatos — operador não deveria precisar produzi-los.
- **Como falsificar:** Se track patch não possui fase investigativa em seu YAML → H03 é descartada.
- **Confiança atual:** BAIXA — track patch não tem fase investigativa declarada.

## Saída esperada

### hypotheses
- Todas as 3 hipóteses com todos os campos obrigatórios preenchidos
- H01 e H02 identificadas como concorrentes (explicações alternativas para o mesmo sintoma)
- H03 com confiança BAIXA documentada
- Hipótese dominante: "NENHUMA — avaliar via findings" (confiança equilibrada entre H01 e H02)
- Cobertura verificada contra critérios de sucesso do intake
