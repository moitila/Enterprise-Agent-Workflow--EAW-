# Skill: tasy_financial_accounting_db

## Objetivo

Consolidar o conhecimento operacional acumulado sobre o ambiente Oracle
`FINANCIAL_ACCOUNTING`/schema `TASY` e sobre o domínio de resolução de conta
contábil no Tasy EMR, para que futuras investigações (cards spike/bug) não
precisem redescobrir essas armadilhas do zero. Fonte: cadeia de cards
`754707C`/`754707D`/`754707E`/`754707F`/`754707G`.

## Como conectar

Ferramenta: MCP SQLcl (`connect`, `sql_run`, `disconnect`,
`connections_list`).

- Conexão salva: `FINANCIAL_ACCOUNTING` (host
  `srv-dbora-09.whebdc.com.br:1521/FINANCIAL_ACCOUNTING`, usuário `tasy`,
  schema `TASY`).
- Sempre confirmar schema/usuário após conectar:
  `SELECT SYS_CONTEXT('USERENV','CURRENT_SCHEMA'), SYS_CONTEXT('USERENV','SERVICE_NAME') FROM DUAL;`
- Outras conexões salvas vistas via `connections_list`:
  `ADMISSION_DISCHARGE_TRANSFER`, `dev-readonly`, `srv-app-sup01`,
  `technology_pwd`, `BILLING_PHARMACY`, `clinical_records`, `TESTE_1845`,
  `technology`. Algumas têm senha "not saved" (`srv-app-sup01`,
  `technology`) — `connect` falha sem credencial disponível; não presumir
  que uma conexão existe só porque aparece na lista.
- **`AUTOCOMMIT` está `ON` por padrão nesta conexão, no nível do driver.**
  Isso não é o `SET AUTOCOMMIT` do SQLcl — é uma propriedade da conexão
  JDBC subjacente. `ROLLBACK` explícito falha com
  `ORA-17274: Could not rollback with auto-commit enabled` se autocommit
  estiver ativo no momento da chamada.

## TRAP crítica: rotinas com `COMMIT` interno

`atualizar_conta_contabil_conta.prc` e `atualizar_resumo_conta.prc`
(`emr-tasy-plsql`, pacote `tasycon`/`tasy`) contêm `COMMIT` interno. A
técnica de reversão por `RAISE_APPLICATION_ERROR` deliberado ao final de um
bloco PL/SQL anônimo — que funciona de forma confiável para chamadas
isoladas de função pura (ex.: `Define_Conta_Procedimento`, que só retorna
valor via parâmetro `OUT` sem gravar em tabela) — **não desfaz** os efeitos
dessas duas rotinas. O `COMMIT` interno delas já persiste os dados antes do
erro final ser lançado; apenas os efeitos posteriores ao ponto do `COMMIT`
interno são de fato revertidos pela falha do bloco.

Isso já causou incidente real duas vezes (`754707F`, achado F-08; `754707G`,
achado F-11), sempre corrigido com sucesso pelo mesmo protocolo.

### Protocolo obrigatório para simular via essas rotinas

1. Capturar o estado original (baseline) do item/conta ANTES de qualquer
   escrita, com query dedicada.
2. Executar a mudança (inserir regra sintética, chamar a rotina).
3. **Verificar explicitamente, por query separada e após a execução**, se
   os dados foram de fato commitados — nunca assumir rollback automático
   só porque um `RAISE_APPLICATION_ERROR` foi lançado.
4. Se commitados: restaurar manualmente via `UPDATE`/`DELETE` +
   `COMMIT` explícito para o estado original, e validar o resultado com
   nova query.
5. Documentar o incidente e a correção no artefato de evidência — não
   omitir.

### `ie_somente_nula_p` de `atualizar_conta_contabil_conta`

- `'S'` = só atualiza itens com `cd_conta_contabil IS NULL` (não recalcula
  os já preenchidos — cuidado, um item já preenchido é silenciosamente
  ignorado).
- `'N'` = recalcula **todos os itens da conta**, inclusive já preenchidos.
  Antes de usar `'N'`, confirmar que a conta de teste tem só o item que
  você quer afetar (`SELECT COUNT(*) FROM procedimento_paciente WHERE
  nr_interno_conta = ...`), senão o experimento recalcula itens reais não
  relacionados ao teste.

## Domínio: resolução de conta contábil (`define_conta_procedimento.prc`)

- Tabela-chave: `parametros_conta_contabil` — cada linha é uma "regra"
  candidata, com colunas de filtro (`cd_convenio`, `cd_categoria_convenio`,
  `cd_plano`, `cd_estabelecimento`, `ie_tipo_financ_sus`,
  `ie_complexidade_sus`, `cd_procedimento`, `ie_origem_proced`,
  `cd_material`, vigência) e colunas de resultado (`cd_conta_receita` e
  variantes por tipo de conta).
- O cursor `C001` de `define_conta_procedimento.prc` usa predicados
  `nvl(coluna, parametro) = parametro` (regra com coluna `NULL` sempre
  "casa" com qualquer valor do parâmetro — regra "ampla"/coringa) e um
  `ORDER BY` com várias colunas em sequência fixa (ordem relevante,
  aproximada): `ie_responsavel_credito`, vigência, `cd_operacao_nf`,
  `cd_estabelecimento`, `ie_tipo_financ_sus`, `ie_complexidade_sus`,
  `cd_categoria_convenio`, `cd_plano`, `cd_convenio`, `ie_tipo_convenio`,
  ...
- **Mecanismo de precedência (confirmado por execução real, não é só
  leitura de código):** o laço de fetch não interrompe no primeiro match
  (`exit when` só existe no final, sem lógica de "already found the best
  match") — cada linha buscada **sobrescreve** o resultado anterior. Como
  a ordenação é ascendente e `nvl(x,0)`/`nvl(x,'0')` trata `NULL` como o
  menor valor possível, a **última linha buscada é a que tem o maior valor
  na primeira coluna do `ORDER BY` em que as regras concorrentes
  divergem** — e essa é a regra que "vence", **independente de qual seria
  a mais específica sob uma ótica de negócio**.
- Isso foi confirmado por execução real (não só por leitura) para dois
  pares de colunas distintos: `cd_categoria_convenio` (posição ~7) vs.
  `cd_convenio` (posição ~9) em `754707F`; `cd_estabelecimento` (posição
  ~4) vs. `cd_categoria_convenio` (posição ~7) em `754707G`. Em ambos os
  casos, a regra cuja coluna diferenciadora está **mais à esquerda** no
  `ORDER BY` venceu — é um mecanismo genérico e posicional, não peculiar a
  um par específico de colunas.
- Nenhuma decisão de negócio documentada foi encontrada (30 commits
  analisados em `emr-tasy-plsql`, nenhuma reordenação deliberada) — o
  comportamento aparenta ser acidental/nunca revisado, não um contrato.
- Risco estrutural (não confirmado com dado real neste ambiente):
  `ie_tipo_financ_sus`/`ie_complexidade_sus` são comparadas como texto no
  `WHERE` mas como número no `ORDER BY` (`nvl(coluna,0)`) — um valor
  cadastrado não numérico nessas colunas pode causar `ORA-01722` em tempo
  de execução. Testado em `FINANCIAL_ACCOUNTING`: 0 ocorrências reais.

### Mecanismo de sobrescrita AIH

- `atualizar_conta_contabil_conta.prc` lê `ie_contab_rec_proc_aih` de
  `parametro_faturamento`, filtrando por `cd_estabelecimento` — **não é um
  campo da conta do paciente nem do item**, é um parâmetro por
  estabelecimento.
- Se `'S'`, a rotina propaga/sobrescreve em lote a conta contábil de itens
  vinculados a AIH — não neutraliza um cadastro de regra trocado ou
  ambíguo, apenas desloca/amplia o efeito para mais itens da mesma conta.

### Rotina de menu manual (`atualizar_dados_conta_pac.prc`)

- Usa o mesmo resolvedor (`Define_Conta_Procedimento`), mas **sempre passa
  `NULL`** para `ie_complexidade_sus_p`/`ie_tipo_financ_sus_p`, enquanto o
  fechamento automático da conta calcula valores reais para esses
  parâmetros. Para regras que dependem dessas colunas, a rotina manual e o
  fechamento automático podem produzir resultados diferentes para o mesmo
  cadastro.

### Dado "órfão" em `conta_paciente_resumo`

- É possível existir uma linha em `conta_paciente_resumo` para um
  `cd_procedimento` que não tem mais item correspondente em
  `procedimento_paciente` (observado: `nr_sequencia=40002`,
  `cd_procedimento=212010026`, sem item ativo na mesma conta). Não
  presumir que toda linha do resumo tem item vivo correspondente; não
  alterar linhas de resumo sem antes confirmar se pertencem ao experimento
  em curso.

## Fixture de referência já estabelecida (reaproveitar, não recriar)

- `nr_interno_conta=838828` / `procedimento_paciente.nr_sequencia=2623508`:
  `cd_procedimento=407040137`, `ie_origem_proced=7`, `cd_convenio=1` (SUS),
  `cd_categoria='1'`, `cd_estabelecimento=1`.
- Estado "limpo" de referência (restaurar sempre para isto após
  experimentos): `cd_conta_contabil='11713'`, `cd_sequencia_parametro=4227`
  (regra real, commitada originalmente pelo card `754707C`). O mesmo valor
  deve aparecer em `conta_paciente_resumo` (linha do procedimento
  `407040137`).
- Contas contábeis de receita já validadas como utilizáveis (não
  totalizadoras, aceitas por `ctb_consistir_conta_titulo`) para montar
  regras sintéticas: `11713`, `1.16.3085`, `4050`, `1121`, `3010`. Cuidado:
  contas do tipo totalizador (ex.: `1222`) são rejeitadas pela trigger
  `PARAM_CONTA_CONTABIL_ATUAL`/`ctb_consistir_conta_titulo` com
  `ORA-20011`.
- Convênio real `4` ("Blue Life") tem categorias `1` (Apartamento) e `2`
  (Enfermaria) cadastradas — útil para montar pares de regras
  concorrentes sem depender de dado sintético de convênio/categoria.

## Padrão seguro de experimento (checklist)

1. Conectar e confirmar schema/serviço.
2. Se o experimento envolve apenas uma função pura (sem `COMMIT` interno
   conhecido), pode-se usar o padrão "insere regra(s) → chama função →
   `RAISE_APPLICATION_ERROR` com o resultado embutido na mensagem" com
   confiança razoável de que tudo será desfeito — mas **sempre confirmar
   depois** com uma query de contagem de linhas residuais.
2b. Se o experimento invoca `atualizar_conta_contabil_conta` e/ou
   `atualizar_resumo_conta` (ou qualquer rotina não auditada quanto a
   `COMMIT` interno), seguir obrigatoriamente o protocolo da seção
   "TRAP crítica" acima — baseline explícito, verificação pós-execução,
   restauração manual se necessário.
3. Nunca deixar o ambiente em estado diferente do baseline documentado ao
   final da investigação, mesmo que a fase tenha terminado com sucesso.
