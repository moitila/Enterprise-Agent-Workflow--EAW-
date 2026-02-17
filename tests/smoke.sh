#!/usr/bin/env bash
set -euo pipefail

# Minimal smoke harness for Card Execution Engine (EAW)
# - Creates a temporary git repo
# - Writes a repos.conf pointing to it
# - Runs `eaw feature` for a dummy card
# - Validates expected output artifacts
# - Cleans up

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

TMPDIR="$(mktemp -d)"
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
trap cleanup EXIT

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
./scripts/eaw feature "$CARD_ID" "Smoke test"

OUTDIR="$REPO_ROOT/out/$CARD_ID"
if [[ ! -d "$OUTDIR" ]]; then
	printf "Smoke failed: missing out dir %s\n" "$OUTDIR" >&2
	exit 2
fi

MAIN_MD="$OUTDIR/feature_${CARD_ID}.md"
if [[ ! -f "$MAIN_MD" ]]; then
	printf "Smoke failed: missing main md %s\n" "$MAIN_MD" >&2
	exit 3
fi

CTX_DIR="$OUTDIR/context/smoke-test"
if [[ ! -d "$CTX_DIR" ]]; then
	printf "Smoke failed: missing context dir %s\n" "$CTX_DIR" >&2
	exit 4
fi

if [[ ! -f "$CTX_DIR/git-commit.txt" ]]; then
	printf "Smoke failed: missing git-commit.txt in %s\n" "$CTX_DIR" >&2
	exit 5
fi

printf "Smoke OK: artifacts present in %s\n" "$OUTDIR"
