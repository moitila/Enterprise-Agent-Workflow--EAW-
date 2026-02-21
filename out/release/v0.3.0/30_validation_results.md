# v0.3.0 Validation Results

Generated at: 2026-02-21T17:04:35Z

## a) Syntax check
- Command: `bash -n ./scripts/eaw`
- Exit code: 0
- Output:
```text
```

## b) smoke.sh
- Command: `./smoke.sh`
- Exit code: 0
- Output:
```text
Wrote /home/user/dev/EAW-dev/out/SMOKE_CARD_1/feature_SMOKE_CARD_1.md
Wrote /home/user/dev/EAW-dev/out/SMOKE_CARD_1/investigations/00_intake.md
Wrote /home/user/dev/EAW-dev/out/SMOKE_CARD_1/investigations/10_baseline.md
Wrote /home/user/dev/EAW-dev/out/SMOKE_CARD_1/investigations/20_findings.md
Wrote /home/user/dev/EAW-dev/out/SMOKE_CARD_1/investigations/30_hypotheses.md
Wrote /home/user/dev/EAW-dev/out/SMOKE_CARD_1/investigations/40_next_steps.md
[phase] init_runtime -> OK (33ms)
[phase] load_config -> OK (3ms)
[phase] resolve_repos -> OK (8ms)
Collecting context for smoke-test -> /tmp/tmp.dOTm4mfJez/test-repo
[phase] collect_context -> OK (36ms)
[phase] search_hits -> OK (36ms)
Execution log for SMOKE_CARD_1:
phase|status|duration_ms|note
init_runtime|OK|33|
load_config|OK|3|
resolve_repos|OK|8|
collect_context|OK|36|
search_hits|OK|36|
[phase] finalize -> OK (5ms)
Smoke: warnings present in /home/user/dev/EAW-dev/out/SMOKE_CARD_1/context/smoke-test/_warnings.txt
allowed to fail: best-effort collection; rg failed or no matches for pattern 'TODO' (see /home/user/dev/EAW-dev/out/SMOKE_CARD_1/context/smoke-test/rg-symbols.txt)
allowed to fail: best-effort collection; rg failed or no matches for pattern 'FIXME' (see /home/user/dev/EAW-dev/out/SMOKE_CARD_1/context/smoke-test/rg-symbols.txt)
allowed to fail: best-effort collection; rg failed or no matches for pattern 'TODO\(.*\)' (see /home/user/dev/EAW-dev/out/SMOKE_CARD_1/context/smoke-test/rg-symbols.txt)
Smoke OK: artifacts present in /home/user/dev/EAW-dev/out/SMOKE_CARD_1
```

## c) smoke_prompt.sh
- Command: `./smoke_prompt.sh`
- Exit code: SKIPPED
- Output:
```text
File ./smoke_prompt.sh not found; step skipped by rule "(se existir)".
```

## d) validate
- Command: `./scripts/eaw validate`
- Exit code: 0
- Output:
```text
EAW validate
Resolved dirs:
  EAW_ROOT_DIR=/home/user/dev/EAW-dev
  EAW_WORKDIR=
  EAW_CONFIG_DIR=/home/user/dev/EAW-dev/config
  EAW_TEMPLATES_DIR=/home/user/dev/EAW-dev/templates
  EAW_OUT_DIR=/home/user/dev/EAW-dev/out
WARNING: /home/user/dev/EAW-dev/config/eaw.conf missing, assuming v1 defaults
OK: repos.conf parsed
OK: search.conf found: /home/user/dev/EAW-dev/config/search.conf
SUMMARY: errors=0 warnings=1
```

## e) doctor
- Command: `./scripts/eaw doctor`
- Exit code: 0
- Output:
```text
EAW doctor
Resolved dirs:
  RUNTIME_ROOT=/home/user/dev/EAW-dev
  CONFIG_SOURCE=/home/user/dev/EAW-dev/config/repos.conf
  EAW_ROOT_DIR=/home/user/dev/EAW-dev
  EAW_WORKDIR=
  EAW_CONFIG_DIR=/home/user/dev/EAW-dev/config
  EAW_TEMPLATES_DIR=/home/user/dev/EAW-dev/templates
  EAW_OUT_DIR=/home/user/dev/EAW-dev/out
Tools:
  git: OK
  rg: OK
  awk: OK
  sed: OK
  bash: GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
Files:
  repos.conf: OK (/home/user/dev/EAW-dev/config/repos.conf)
  search.conf: OK (/home/user/dev/EAW-dev/config/search.conf)
  eaw.conf: MISSING (/home/user/dev/EAW-dev/config/eaw.conf)
STATUS: WARN (errors=0 warnings=1)
```

