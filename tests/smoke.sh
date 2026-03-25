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

cleanup() {
	local rc=$?
	# restore original repos.conf if it existed
	if [[ -n "${REPOS_CONF_BAK:-}" && -f "$REPOS_CONF_BAK" ]]; then
		mv "$REPOS_CONF_BAK" "$CONFIG_DIR/repos.conf"
	else
		rm -f "$CONFIG_DIR/repos.conf"
	fi
	# remove temp repo and out artifact
	rm -rf "$TMPDIR" "$REPO_ROOT/out/$CARD_ID" || true
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

# backup and write repos.conf
CONFIG_DIR="$REPO_ROOT/config"
REPOS_CONF="$CONFIG_DIR/repos.conf"
REPOS_CONF_BAK=""
if [[ -f "$REPOS_CONF" ]]; then
	REPOS_CONF_BAK="$(mktemp)"
	cp "$REPOS_CONF" "$REPOS_CONF_BAK"
fi

printf "%s|%s\n" "smoke-test" "$REPO_DIR" >"$REPOS_CONF"

# run eaw to create a card
CARD_ID="SMOKE_CARD_1"
./scripts/eaw card "$CARD_ID" --track standard "Smoke test"

OUTDIR="$REPO_ROOT/out/$CARD_ID"
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

bash "$REPO_ROOT/tests/smoke_intake_negative.sh"
bash "$REPO_ROOT/tests/smoke_analyze_negative.sh"
bash "$REPO_ROOT/tests/smoke_implement_negative.sh"
bash "$REPO_ROOT/tests/smoke_prompt_core.sh"
bash "$REPO_ROOT/tests/smoke_config_contract.sh"
bash "$REPO_ROOT/tests/smoke_tracks.sh"
bash "$REPO_ROOT/tests/smoke_card_command.sh"

printf "Smoke OK: artifacts present in %s\n" "$OUTDIR"
