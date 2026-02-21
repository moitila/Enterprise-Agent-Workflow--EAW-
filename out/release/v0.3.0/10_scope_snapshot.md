# Scope Snapshot — v0.3.0 (pre-Feature 30)

## Objective
Estabelecer um baseline auditável da versão v0.3.0 antes da Feature 30, preservando contratos atuais e determinismo do fluxo EAW.

## IN Scope
- Execução de validações obrigatórias da release (syntax/smoke se existir/validate/doctor).
- Registro de evidências reproduzíveis em `out/release/v0.3.0/`.
- Snapshot de contratos observáveis atuais de CLI e artefatos.
- Snapshot formal de estado git no momento do freeze.

## OUT Scope
- Implementação da Feature 30.
- Mudanças arquiteturais/refatorações.
- Alteração de contratos de IO (CLI/stdout/stderr/paths) além do estritamente necessário para baseline.
- Alterações fora de `out/release/v0.3.0/`.

## Note about Feature 30
A Feature 30 foi explicitamente reservada para mudanças em mensagens, textos hardcoded e i18n/multi-language. Este freeze não inclui essas mudanças.
