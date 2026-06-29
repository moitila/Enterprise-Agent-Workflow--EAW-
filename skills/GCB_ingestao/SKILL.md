---
name: gcb_ingestao_prova
description: Inventario e classificacao de material bruto de prova GCB. Orienta o agente a catalogar arquivos, separar papeis documentais e registrar qualidade de extracao sem analisar conteudo semantico.
---

# SKILL: gcb_ingestao_prova

## Objetivo

Orientar o agente a inventariar materiais brutos de prova depositados em `ingest/`,
separar papéis documentais e registrar qualidade de extração. Esta fase não analisa
conteúdo semântico — apenas cataloga o que existe.

## EAW_WORKDIR guard (obrigatório)

Antes de qualquer operação:
```
export EAW_WORKDIR=/home/user/Coringas/GCB/.eaw
echo $EAW_WORKDIR   # deve imprimir /home/user/Coringas/GCB/.eaw
```
Se EAW_WORKDIR for diferente de `/home/user/Coringas/GCB/.eaw` → PARAR e reportar conflito.

## Quando usar

- Sempre na fase `ingestao_prova`.

## Quando NÃO usar

- Em qualquer fase analítica (mapa_de_pistas em diante).

## Entradas esperadas

- Arquivos depositados em `out/<CARD>/ingest/` pelo operador
- `out/<CARD>/ingest/gcb_prova_metadata.md` (preenchido pelo operador)

## Saídas esperadas

- `investigations/01_inventario_arquivos.md` — lista de arquivos com papel documental
- `investigations/01_provenance.md` — log de processo: arquivos encontrados, consumidos, ignorados

## Regras

1. Para cada arquivo em `ingest/`, atribuir papel documental:
   `enunciado | gabarito | resolucao | apoio | evidencia_entrega | controle | indeterminado`
2. Registrar tipo de mídia técnico: `pdf | docx | txt | md | imagem | audio | video | planilha | outro`
3. Registrar status de extração: `extraido_com_sucesso | ocr_executado | extracao_parcial | nao_extraido`
4. Registrar qualidade de OCR quando aplicável: `alta | media | baixa | nao_aplicavel`
5. Não analisar o conteúdo semântico de nenhum arquivo nesta fase
6. Se `gcb_prova_metadata.md` existir, usar suas informações como contexto inicial
7. Arquivo sem papel definível → classificar como `indeterminado` e registrar dúvida em `01_provenance.md`
8. Listar arquivos em ordem lexicográfica

## Antipadrões

- Classificar foto de entrega como enunciado
- Misturar gabarito com resolução (gabarito = lista de respostas; resolução = explicação do caminho)
- Analisar conteúdo semântico nesta fase
- Inventar arquivo que não existe em `ingest/`
- Omitir qualidade de OCR quando relevante

## Formato de 01_inventario_arquivos.md

```markdown
# Inventário de Arquivos — <PROVA_ID>

## Arquivos catalogados

| Arquivo | Tipo mídia | Papel documental | Status extração | Qualidade OCR |
|---|---|---|---|---|
| texto.md | md | enunciado | extraido_com_sucesso | nao_aplicavel |

## Metadados da prova (de gcb_prova_metadata.md)

- PROVA_ID:
- ANO_GCB:
- TITULO_PROVA:
- Fontes disponíveis:
- Fontes ausentes:
```
