# eaw tracks

## Objetivo

`eaw tracks` lista as tracks oficiais instaladas no repositorio a partir da arvore `tracks/<track>/`.

### Formato da saida

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

### Validacao minima

Uma track so e listada quando todos os criterios abaixo forem verdadeiros:

1. O diretorio `tracks/<track>/` existe.
2. O arquivo `tracks/<track>/track.yaml` existe.
3. Existe pelo menos um arquivo em `tracks/<track>/phases/*.yaml`.
4. `track.id` existe em `track.yaml`.
5. `track.id` coincide exatamente com o nome do diretorio `<track>`.

Se qualquer validacao minima falhar, a track e omitida de `stdout` e uma linha de erro e emitida em `stderr` identificando a track candidata e o criterio nao atendido.

### Condicao de erro

Se a raiz `tracks/` nao existir, o comando falha com mensagem acionavel em `stderr`.

---

## eaw tracks install

### Objetivo

`eaw tracks install` executa o ciclo formal de instalacao de tracks: descoberta, validacao pelo contrato minimo, registro em `tracks/tracks.yaml` e relatorio de resultado.

### Fluxo de instalacao

1. Varre `tracks/` por subpastas candidatas.
2. Valida cada candidata contra o contrato minimo (`eaw_validate_workflow_track`).
3. Registra as validas em `tracks/tracks.yaml` com `status: installed`.
4. Emite relatorio com: candidatas descobertas, instaladas, rejeitadas com motivo.

### Saida do comando

- `stdout`: `discovered: N`, `installed: N`, lista de tracks instaladas.
- `stderr`: `REJECTED: <track>` com motivo detalhado para cada candidata rejeitada.

## `tracks/tracks.yaml`

Registro oficial das tracks instaladas. Estrutura minima por entrada:

```yaml
tracks:
  - track_id: <track_id>
    status: installed
```

Uma track presente em `tracks/` mas ausente de `tracks/tracks.yaml` nao e reconhecida pelo runtime como track oficial.
