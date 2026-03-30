# Environment Variables

## EAW_SMOKE_SH

### O que controla

`EAW_SMOKE_SH` aponta para o smoke harness de runtime do operador. Quando definida, o `implementation_executor` invoca o script ao final da execucao para validar o estado do ambiente apos a aplicacao de patches com mudanca de codigo.

### Valor esperado

Caminho absoluto para um script executavel no ambiente do operador.

Exemplo:

```
EAW_SMOKE_SH=/home/user/dev/EAW-tool/tests/smoke_runtime.sh
```

### Forma de injecao

A variavel deve ser definida no ambiente antes da execucao autonoma. O EAW nao injeta `EAW_SMOKE_SH` automaticamente; a responsabilidade de configurar o valor concreto e do operador.

### Comportamento na ausencia

Quando `EAW_SMOKE_SH` nao estiver definida no ambiente:

- O `implementation_executor` registra `SKIP: EAW_SMOKE_SH not set` e continua sem falha.
- O componente `eaw doctor` emite um warning (`EAW_SMOKE_SH: WARN (not set)`) e incrementa o contador de warnings, sem bloquear a execucao.

A ausencia da variavel nao e tratada como erro fatal em nenhum componente do EAW.

### Nao-obrigatoriedade

A verificacao de `EAW_SMOKE_SH` e condicional em todos os tracks do `implementation_executor` (`feature`, `bug`, `default`, `spike`, `ARCH_REFACTOR`). Cards puramente documentais — que nao produzem mudanca de codigo — nao requerem a variavel; o modelo condicional preserva a opcionalidade nesses casos.
