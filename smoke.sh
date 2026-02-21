#!/usr/bin/env bash
set -euo pipefail

# Lightweight wrapper for the canonical test harness in tests/
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -x "$REPO_ROOT/tests/smoke.sh" ]]; then
	"$REPO_ROOT/tests/smoke.sh" "$@"
else
	echo "tests/smoke.sh not found or not executable" >&2
	exit 1
fi

# Card 30 minimal content smoke:
# 1) content_enabled=false keeps prompt output identical to legacy.
# 2) content_enabled=true with missing pack fails with EAW_CONTENT_ERROR.
TMPDIR="$(mktemp -d)"
cleanup() {
	rm -rf "$TMPDIR"
}
trap cleanup EXIT

export EAW_WORKDIR="$TMPDIR/.eaw"
"$REPO_ROOT/scripts/eaw" init --workdir "$EAW_WORKDIR" --upgrade >/dev/null
"$REPO_ROOT/scripts/eaw" bug 309001 "content smoke" >/dev/null

legacy_out="$TMPDIR/legacy.out"
disabled_out="$TMPDIR/disabled.out"
"$REPO_ROOT/scripts/eaw" prompt 309001 >"$legacy_out" 2>/dev/null

cat >"$EAW_WORKDIR/config/content.conf" <<EOF
content_enabled=false
default_lang=pt-br
EOF

"$REPO_ROOT/scripts/eaw" prompt 309001 >"$disabled_out" 2>/dev/null
if ! cmp -s "$legacy_out" "$disabled_out"; then
	echo "smoke failed: content_enabled=false changed prompt output" >&2
	exit 1
fi

cat >"$EAW_WORKDIR/config/content.conf" <<EOF
content_enabled=true
default_lang=zz-missing-pack
EOF

set +e
"$REPO_ROOT/scripts/eaw" prompt 309001 >/dev/null 2>"$TMPDIR/content_fail.stderr"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
	echo "smoke failed: expected non-zero exit with content_enabled=true and missing pack" >&2
	exit 1
fi
if ! grep -Fq "EAW_CONTENT_ERROR:" "$TMPDIR/content_fail.stderr"; then
	echo "smoke failed: expected EAW_CONTENT_ERROR prefix on stderr" >&2
	exit 1
fi
