#!/usr/bin/env bash
set -euo pipefail

# Minimal smoke harness for Card Execution Engine (EAW)
# - Creates a temporary git repo
# - Writes a repos.conf pointing to it
# - Runs `eaw feature` for a dummy card
# - Validates expected output artifacts
# - Cleans up

# Make outputs deterministic for the harness
export LC_ALL=C
export TZ=UTC

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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

# structural validations (deterministic checks)
CTX_DIR="$OUTDIR/context/smoke-test"
if [[ ! -d "$CTX_DIR" ]]; then
	printf "Smoke failed: missing context dir %s\n" "$CTX_DIR" >&2
	exit 4
fi

# commit SHA should be present and look like hex
if [[ ! -f "$CTX_DIR/git-commit.txt" ]]; then
	printf "Smoke failed: missing git-commit.txt in %s\n" "$CTX_DIR" >&2
	exit 5
fi
if ! grep -E -q '^[0-9a-f]{7,40}$' "$CTX_DIR/git-commit.txt"; then
	printf "Smoke failed: git-commit.txt content invalid: %s\n" "$(head -n1 "$CTX_DIR/git-commit.txt")" >&2
	exit 6
fi

# branch name should be present
if [[ ! -f "$CTX_DIR/git-branch.txt" || -z "$(<"$CTX_DIR/git-branch.txt")" ]]; then
	printf "Smoke failed: git-branch.txt missing or empty in %s\n" "$CTX_DIR" >&2
	exit 7
fi

# changed-files.txt must exist (may be empty)
if [[ ! -f "$CTX_DIR/changed-files.txt" ]]; then
	printf "Smoke failed: changed-files.txt missing in %s\n" "$CTX_DIR" >&2
	exit 8
fi

# check main md contains ISO date (YYYY-MM-DD)
if ! grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' "$MAIN_MD"; then
	printf "Smoke failed: main md does not contain ISO date (%s)\n" "$MAIN_MD" >&2
	exit 9
fi

# print warnings (if any) but do not fail
if [[ -f "$CTX_DIR/_warnings.txt" ]]; then
	printf "Smoke: warnings present in %s/_warnings.txt\n" "$CTX_DIR"
	sed -n '1,20p' "$CTX_DIR/_warnings.txt" || true
fi

printf "Smoke OK: artifacts present in %s\n" "$OUTDIR"
