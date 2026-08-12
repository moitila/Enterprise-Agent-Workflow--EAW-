#!/usr/bin/env bash
set -euo pipefail

# Minimal smoke harness for Card Execution Engine (EAW)
# - Creates a temporary git repo
# - Writes a repos.conf pointing to it
# - Runs `eaw card --track standard` for a dummy card
# - Validates expected output artifacts
# - Cleans up

# Make outputs deterministic for the harness
export LC_ALL=C
export TZ=UTC

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
unset EAW_WORKDIR
unset EAW_OUT_DIR

for conf in "$REPO_ROOT"/config/search.conf "$REPO_ROOT"/config/search.example.conf; do
	[[ -f "$conf" ]] || continue
	if LC_ALL=C grep -n $'\r' "$conf" >/dev/null; then
		printf "Smoke failed: CRLF detected in config file %s\n" "$conf" >&2
		exit 10
	fi
done

TMPDIR="$(mktemp -d)"
if [[ ! -d "$TMPDIR" ]]; then
	echo "failed to create tempdir" >&2
	exit 1
fi

# Isolate the smoke run against a disposable copy of the runtime so the
# versioned config/repos.conf is never a write target (see docs/TEST_STRATEGY.md).
tmp_runtime="$(mktemp -d)"
if [[ ! -d "$tmp_runtime" ]]; then
	echo "failed to create runtime tempdir" >&2
	exit 1
fi
cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/templates" "$REPO_ROOT/tracks" "$REPO_ROOT/config" "$tmp_runtime/"

cleanup() {
	local rc=$?
	# remove disposable runtime copy and temp repo (the versioned config is untouched)
	rm -rf "$tmp_runtime" "$TMPDIR" || true
	exit "$rc"
}
# ensure cleanup on EXIT, INT and TERM
trap cleanup EXIT INT TERM

# create minimal git repo
REPO_DIR="$TMPDIR/test-repo"
mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q
git -C "$REPO_DIR" config user.email "smoke@example.com"
git -C "$REPO_DIR" config user.name "smoke"
echo "hello" >"$REPO_DIR/README.md"
git -C "$REPO_DIR" add README.md
git -C "$REPO_DIR" commit -q -m "initial commit"

# write the test repos.conf into the disposable runtime copy only
printf "%s|%s\n" "smoke-test" "$REPO_DIR" >"$tmp_runtime/config/repos.conf"

# run eaw (repo-tool mode) against the disposable runtime copy; config/out
# resolve to "$tmp_runtime" via BASH_SOURCE, so the versioned repo is untouched
CARD_ID="SMOKE_CARD_1"
bash "$tmp_runtime/scripts/eaw" card "$CARD_ID" --track standard "Smoke test"

OUTDIR="$tmp_runtime/out/$CARD_ID"
if [[ ! -d "$OUTDIR" ]]; then
	printf "Smoke failed: missing out dir %s\n" "$OUTDIR" >&2
	exit 2
fi

MAIN_MD="$OUTDIR/standard_${CARD_ID}.md"
if [[ ! -f "$MAIN_MD" ]]; then
	printf "Smoke failed: missing main md %s\n" "$MAIN_MD" >&2
	exit 3
fi

# check main md contains ISO date (YYYY-MM-DD)
if ! grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$MAIN_MD"; then
	printf "Smoke failed: main md does not contain ISO date (%s)\n" "$MAIN_MD" >&2
	exit 4
fi

bash "$REPO_ROOT/tests/smoke/smoke_arch_refactor_onboard.sh"
bash "$REPO_ROOT/tests/smoke/smoke_bug_onboard.sh"
bash "$REPO_ROOT/tests/smoke/smoke_feature_dynamic.sh"
bash "$REPO_ROOT/tests/smoke_intake_negative.sh"
bash "$REPO_ROOT/tests/smoke_analyze_negative.sh"
bash "$REPO_ROOT/tests/smoke_implement_negative.sh"
bash "$REPO_ROOT/tests/smoke_prompt_core.sh"
bash "$REPO_ROOT/tests/smoke_config_contract.sh"
bash "$REPO_ROOT/tests/smoke_tracks.sh"
bash "$REPO_ROOT/tests/smoke_card_command.sh"

printf "Smoke OK: artifacts present in %s\n" "$OUTDIR"
