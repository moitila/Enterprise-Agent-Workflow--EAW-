# Template de Metadados de Prova GCB
# Depositar como: out/<CARD>/ingest/gcb_prova_metadata.md
# Preencher ANTES de executar a primeira fase.

## Identificação

- PROVA_ID:          # ex: GCB-2013-P14-NOMES-DE-RUAS-DE-BLUMENAU
- ANO_GCB:           # ex: 2013 (ou edição: ex: 21)
- NUMERO_PROVA:      # ex: 14
- TITULO_PROVA:      # ex: Nomes de Ruas de Blumenau
- EDICAO_GCB:        # ex: 21 GCB - ano 2013

## Material depositado em ingest/

# Liste cada arquivo com nome e tipo:
# - texto.md        (texto extraído do DOCX/PDF)
# - resumo_extracao.md
# - imagens/        (imagens extraídas, se houver)

## Papel documental da fonte principal

# Escolher um: enunciado | gabarito | resolucao | apoio | evidencia_entrega | controle | indeterminado
- Papel:

## Tipo provável de prova (rascunho inicial)

# Exemplos: rua/historica/documental | cifra | video | madrugada | social | objeto
- Tipo:

## Fontes materiais locais disponíveis

- ROL de Ruas CSV:       sim | não   # analiseContexto/fontes/ruas/rol_ruas.csv
- ROL de Ruas PDF:       sim | não   # ACERVO/ROL de RUAS/pdfrolderuas.pdf
- Gabarito local:        sim | não   # (citar caminho se sim)
- Resolução local:       sim | não   # (citar caminho se sim)
- Blumenau em Cadernos:  sim | não   # (parcial — citar se disponível)
- Acervo extraído:       sim | não   # analiseContexto/extraido/ACERVO/
- Outro:                             # (descrever)

## Fontes materiais ausentes / pendentes

# Liste fontes que seriam necessárias mas não estão disponíveis localmente:
# - Jornal de Santa Catarina (recortes) — necessita_upload
# - Guia online prefeitura — necessita_internet

## Lacunas conhecidas de extração

# Exemplo: OCR de baixa qualidade, arquivo corrompido, página faltando, CDR não extraído
# - (descrever ou "nenhuma conhecida")

## EAW_WORKDIR — OBRIGATÓRIO antes de executar qualquer fase

export EAW_WORKDIR=/home/user/Coringas/GCB/.eaw
# Verificar com: echo $EAW_WORKDIR
# Deve imprimir: /home/user/Coringas/GCB/.eaw
