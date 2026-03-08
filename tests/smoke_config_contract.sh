#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	echo "SMOKE config contract failed: $*" >&2
	exit 1
}

tmp="$(mktemp -d)"
cleanup() {
	rm -rf "$tmp" || true
}
trap cleanup EXIT

./scripts/eaw init --workdir "$tmp" >/dev/null

rm -f "$tmp/config/eaw.conf"
doctor_out="$(EAW_WORKDIR="$tmp" ./scripts/eaw doctor)"
validate_out="$(EAW_WORKDIR="$tmp" ./scripts/eaw validate)"

grep -Fq "eaw.conf: OPTIONAL_FORMAL" <<<"$doctor_out" || fail "doctor missing OPTIONAL_FORMAL when eaw.conf absent"
grep -Fq "STATUS: OK (errors=0 warnings=0)" <<<"$doctor_out" || fail "doctor should keep warnings=0 when eaw.conf absent"
grep -Fq "INFO: $tmp/config/eaw.conf missing; contrato opcional formal ativo (defaults v1)" <<<"$validate_out" || fail "validate missing optional formal info when eaw.conf absent"
grep -Fq "SUMMARY: errors=0 warnings=0" <<<"$validate_out" || fail "validate should keep warnings=0 when eaw.conf absent"

printf "x=1\n" >"$tmp/config/eaw.conf"
validate_missing_version_out="$(EAW_WORKDIR="$tmp" ./scripts/eaw validate)"
grep -Fq "exists but config_version is missing" <<<"$validate_missing_version_out" || fail "validate should warn when config_version is missing"
grep -Fq "SUMMARY: errors=0 warnings=1" <<<"$validate_missing_version_out" || fail "validate should report warnings=1 when config_version is missing"

printf "config_version=0\n" >"$tmp/config/eaw.conf"
validate_old_version_out="$(EAW_WORKDIR="$tmp" ./scripts/eaw validate)"
grep -Fq "config_version=0 is older than required=1" <<<"$validate_old_version_out" || fail "validate should warn when config_version is older"
grep -Fq "SUMMARY: errors=0 warnings=1" <<<"$validate_old_version_out" || fail "validate should report warnings=1 when config_version is older"

printf "smoke config contract OK\n"
