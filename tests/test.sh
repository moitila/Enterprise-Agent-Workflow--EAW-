#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf "test suite failed: %s\n" "$1" >&2
	exit 1
}

prepare_feature_planning_with_onboarding() {
	local runtime_root="$1"
	local phase_file="$runtime_root/tracks/feature/phases/planning.yaml"
	python3 - "$phase_file" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
if "onboarding_template: repo_discovery" in text:
    raise SystemExit(0)

if "  context:\n" in text:
    marker = "  context:\n"
    replacement = marker + "    onboarding_template: repo_discovery\n"
    path.write_text(text.replace(marker, replacement, 1))
    raise SystemExit(0)

needle = "  prompt:\n"
idx = text.find(needle)
if idx == -1:
    raise SystemExit("planning prompt block not found")

prompt_end = text.find("\n\n", idx)
if prompt_end == -1:
    raise SystemExit("planning prompt block terminator not found")

insertion = "\n  context:\n    onboarding_template: repo_discovery"
path.write_text(text[:prompt_end] + insertion + text[prompt_end:])
PY
}

run_onboarding_runtime_suite() {
	local tmp_root runtime_root eaw_bin workdir card prompt_file

	tmp_root="$(mktemp -d)"
	trap 'rm -rf "$tmp_root"' RETURN

	runtime_root="$tmp_root/runtime"
	mkdir -p "$runtime_root"
	cp -R "$REPO_ROOT/scripts" "$runtime_root/"
	cp -R "$REPO_ROOT/templates" "$runtime_root/"
	cp -R "$REPO_ROOT/tracks" "$runtime_root/"
	cp -R "$REPO_ROOT/config" "$runtime_root/"
	eaw_bin="$runtime_root/scripts/eaw"

	workdir="$tmp_root/workdir"
	EAW_WORKDIR="$workdir" "$eaw_bin" init --workdir "$workdir" --force >/dev/null
	printf 'local-main|/home/user/dev/EAW-dev|target\n' >"$workdir/config/repos.conf"
	prepare_feature_planning_with_onboarding "$runtime_root"

	advance_feature_card_to_planning() {
		local card_id="$1"
		local card_dir="$workdir/out/$card_id"

		cat >>"$card_dir/investigations/00_intake.md" <<'EOF'

Intake preenchido para onboarding runtime suite.
EOF
		cat >>"$card_dir/investigations/_intake_provenance.md" <<'EOF'

Fonte: onboarding runtime suite.
EOF
		EAW_WORKDIR="$workdir" "$eaw_bin" next "$card_id" >/dev/null
		EAW_WORKDIR="$workdir" "$eaw_bin" next "$card_id" >/dev/null

		cat >>"$card_dir/context/dynamic/00_scope_manifest.md" <<'EOF'

Dynamic context preenchido para onboarding runtime suite.
EOF
		EAW_WORKDIR="$workdir" "$eaw_bin" next "$card_id" >/dev/null

		cat >>"$card_dir/investigations/20_findings.md" <<'EOF'

Findings preenchido para onboarding runtime suite.
EOF
		EAW_WORKDIR="$workdir" "$eaw_bin" next "$card_id" >/dev/null

		cat >>"$card_dir/investigations/30_hypotheses.md" <<'EOF'

Hypotheses preenchido para onboarding runtime suite.
EOF
		EAW_WORKDIR="$workdir" "$eaw_bin" next "$card_id" >/dev/null
	}

	mkdir -p "$workdir/context_sources/onboarding/local-main/docs"
	printf 'alpha\n' >"$workdir/context_sources/onboarding/local-main/README.md"
	printf 'beta\n' >"$workdir/context_sources/onboarding/local-main/docs/info.txt"
	printf 'ignored\n' >"$workdir/context_sources/onboarding/local-main/image.bin"

	card="585ACC"
	EAW_WORKDIR="$workdir" "$eaw_bin" card "$card" --track feature "onboarding acceptance" >/dev/null
	advance_feature_card_to_planning "$card"
	test ! -e "$workdir/out/$card/context/onboarding" || fail "repo_discovery should not materialize onboarding into card context"
	prompt_file="$workdir/out/$card/prompts/planning.md"
	test -f "$prompt_file" || fail "missing planning prompt for onboarding-by-reference validation"
	grep -Fq 'Interpretar consumo de onboarding por referencia como uso exclusivo da superficie de contexto injetada pelo runtime' "$prompt_file" \
		|| fail "planning prompt missing onboarding-by-reference contract"
	grep -Fq 'sem exigir copia para `out/<CARD>/`' "$prompt_file" \
		|| fail "planning prompt missing no-materialization rule"

	rm -rf "$workdir/context_sources/onboarding/local-main"
	card="585ABS"
	EAW_WORKDIR="$workdir" "$eaw_bin" card "$card" --track feature "onboarding absent" >/dev/null
	advance_feature_card_to_planning "$card"
	test ! -e "$workdir/out/$card/context/onboarding" || fail "absent repo_discovery source should still avoid card onboarding materialization"
	prompt_file="$workdir/out/$card/prompts/planning.md"
	test -f "$prompt_file" || fail "missing planning prompt when onboarding source is absent"
	grep -Fq 'Interpretar consumo de onboarding por referencia como uso exclusivo da superficie de contexto injetada pelo runtime' "$prompt_file" \
		|| fail "absent source should preserve onboarding-by-reference contract"

	mkdir -p "$workdir/context_sources/onboarding/local-main"
	printf 'stale\n' >"$workdir/context_sources/onboarding/local-main/a.md"
	card="585IDEMP"
	EAW_WORKDIR="$workdir" "$eaw_bin" card "$card" --track feature "onboarding idempotence" >/dev/null
	advance_feature_card_to_planning "$card"
	rm "$workdir/context_sources/onboarding/local-main/a.md"
	printf 'fresh\n' >"$workdir/context_sources/onboarding/local-main/b.md"
	printf "# planning ok\n" >"$workdir/out/$card/investigations/40_next_steps.md"
	EAW_WORKDIR="$workdir" "$eaw_bin" next "$card" >/dev/null
	test ! -e "$workdir/out/$card/context/onboarding" || fail "rerun should keep repo_discovery onboarding non-materialized"

	rm -rf "$workdir/context_sources/onboarding/local-main"
	mkdir -p "$workdir/context_sources/onboarding/local-main"
	for n in $(seq 1 12); do
		printf 'ordered-%02d\n' "$n" >"$workdir/context_sources/onboarding/local-main/file_$(printf '%02d' "$n").md"
	done
	python3 - "$workdir/context_sources/onboarding/local-main/large.json" <<'PY'
from pathlib import Path
import json
import sys

payload = {"blob": "x" * 205000}
Path(sys.argv[1]).write_text(json.dumps(payload))
PY
	card="585LIMIT"
	EAW_WORKDIR="$workdir" "$eaw_bin" card "$card" --track feature "onboarding limits" >/dev/null
	advance_feature_card_to_planning "$card"
	test ! -e "$workdir/out/$card/context/onboarding" || fail "repo_discovery should not create onboarding artifacts even with oversized source trees"
}

printf "[test] smoke scope\n"
bash "$REPO_ROOT/tests/smoke/smoke_baseline.sh"

printf "[test] integration scope\n"
bash "$REPO_ROOT/tests/integration/integration_suite.sh"

printf "[test] lifecycle scope\n"
bash "$REPO_ROOT/tests/lifecycle/lifecycle_suite.sh"

printf "[test] golden scope\n"
bash "$REPO_ROOT/tests/golden/golden_suite.sh"

printf "[test] onboarding runtime scope\n"
run_onboarding_runtime_suite
