# `eaw tracks`

## Objetivo

`eaw tracks` lista as tracks oficiais instaladas no repositorio a partir da arvore `tracks/<track>/`.

## Formato da saida

- `stdout`: uma track valida por linha.
- Ordem: alfabetica.
- Exit code:
  - `0` quando a raiz `tracks/` existe, mesmo se nenhuma track valida for encontrada.
  - diferente de `0` quando a raiz `tracks/` nao existe.

Exemplo de `stdout`:

```text
bug
feature
spike
standard
```

## Validacao minima

Uma track so e listada quando todos os criterios abaixo forem verdadeiros:

1. O diretorio `tracks/<track>/` existe.
2. O arquivo `tracks/<track>/track.yaml` existe.
3. Existe pelo menos um arquivo em `tracks/<track>/phases/*.yaml`.
4. `track.id` existe em `track.yaml`.
5. `track.id` coincide exatamente com o nome do diretorio `<track>`.

Se qualquer validacao minima falhar, a track e omitida de `stdout`.

## Condicao de erro

Se a raiz `tracks/` nao existir, o comando falha com mensagem acionavel em `stderr`.
