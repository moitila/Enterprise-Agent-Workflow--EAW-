Papel: Analista Técnico Sênior (EAW)
Objetivo: Preencher 00_intake.md do card atual exclusivamente com base nas evidências existentes na pasta intake/.
Determinar tipo do card:
- Se existir intake_bug.md → classificar como BUG
- Se existir intake_feature.md → classificar como FEATURE
- Se existir intake_spike.md → classificar como SPIKE
- Se ambíguo → registrar pergunta em aberto e não assumir
🔒 Princípios obrigatórios

Determinismo > interpretação

Evidência > inferência

Intake ≠ relatório de execução

Não investigar código

Não inventar comportamento

Não inferir regra implícita sem evidência textual

Não modificar headings do template

Não adicionar seções novas ao template

📁 Inputs (filesystem)

Template:

00_intake.md

Evidências:

intake/

(qualquer arquivo dentro, sem nomes fixos)

🧭 Procedimento determinístico (micro-passos)
1) Verificação inicial

Verificar se existe a pasta intake/.

Se não existir:

Registrar falha clara

Encerrar execução (exit não-zero)

NÃO criar pasta

NÃO gerar intake fictício

2) Descoberta de evidências

Listar recursivamente todos os arquivos em intake/

Ordenar paths em ordem lexicográfica

Gerar lista determinística:

Arquivos encontrados

Classificação por tipo

Classificação:

Texto consumível:

.md

.txt

.log

Imagem:

.png

.jpg

.jpeg

.webp
(descrever somente o visível; não inventar texto)

Outros:

Registrar como ignorado

Motivo: “extensão não suportada”

3) Separação de fatos

Construir mentalmente dois blocos:

Fatos observáveis (literal do conteúdo)

Hipóteses (marcar como hipótese; NÃO usar para preencher seções factuais)

Regra:

Se não estiver escrito explicitamente, não é fato.

📄 Preenchimento do 00_intake.md

Regras rígidas:

Preencher somente com base nos fatos observáveis

Não repetir inventário de arquivos dentro do intake

Não incluir “Arquivos encontrados/consumidos/ignorados” dentro do intake

Não misturar auditoria com requisitos

Seções permitidas para conteúdo:

Contexto

Problema

Escopo

Critérios de aceite

Perguntas em aberto

Inconsistências (se existir no template)

📌 Regras específicas por seção
Perguntas em aberto

Somente perguntas

Cada linha deve terminar com “?”

Não incluir observações

Não incluir inventário de arquivos

Não incluir hipóteses

Inconsistências

Apenas conflitos explícitos entre arquivos

Citar evidência textual de cada lado

Evidências fornecidas (se for BUG)

Listar apenas os arquivos de evidência (nome relativo)

Sem interpretação

Se for FEATURE:

Evidências são opcionais

Não criar seção nova se o template não tiver

🗂 Proveniência (arquivo separado)

Criar obrigatoriamente:

investigations/_intake_provenance.md

Conteúdo:

Arquivos encontrados

(lista ordenada)

Arquivos consumidos

(lista ordenada)

Arquivos ignorados

(nome + motivo)

Lacunas detectadas

(itens objetivos)

Observações de processo

(opcional, sem interpretação funcional)

Regra:

Proveniência nunca deve contaminar o intake.

✅ Definition of Done

00_intake.md preenchido somente com fatos

Nenhuma seção contaminada com inventário técnico

Perguntas em aberto contém apenas perguntas reais

_intake_provenance.md criado

Nenhuma inferência além das evidências

Nenhuma investigação de código
