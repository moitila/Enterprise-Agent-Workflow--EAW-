#!/usr/bin/env bash
# governance/scripts/install-hooks.sh
# Install governance git hooks into .git/hooks
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SRC="$ROOT_DIR/hooks/commit-msg"
HOOK_DST="$ROOT_DIR/../.git/hooks/commit-msg"

if [[ ! -d "$ROOT_DIR/../.git" ]]; then
  echo "install-hooks: not a git repository (no .git folder found)" >&2
  exit 1
fi

if [[ ! -f "$HOOK_SRC" ]]; then
  echo "install-hooks: hook source not found: $HOOK_SRC" >&2
  exit 1
fi

if [[ -f "$HOOK_DST" ]]; then
  echo "install-hooks: hook already exists at $HOOK_DST" >&2
  echo "If you want to overwrite, run: bash $0 --force" >&2
  exit 1
fi

if [[ "${1:-}" == "--force" ]]; then
  cp -f "$HOOK_SRC" "$HOOK_DST"
else
  cp "$HOOK_SRC" "$HOOK_DST"
fi

chmod +x "$HOOK_DST"
echo "Installed governance commit-msg hook to $HOOK_DST"
