#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SRC="$ROOT_DIR/hooks/commit-msg"
HOOK_DST="$ROOT_DIR/.git/hooks/commit-msg"

if [[ ! -f "$HOOK_SRC" ]]; then
  echo "install-hooks: missing $HOOK_SRC" >&2
  exit 1
fi

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
echo "Installed commit-msg hook to $HOOK_DST"
