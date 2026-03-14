#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
	printf "smoke_tracks failed: %s\n" "$1" >&2
	exit 1
}

tmp_root="$(mktemp -d)"
cleanup() {
	rm -rf "$tmp_root" || true
}
trap cleanup EXIT

expected_output=$'bug\nfeature\nspike\nstandard'
actual_output="$(./scripts/eaw tracks)"
[[ "$actual_output" == "$expected_output" ]] || fail "unexpected output for current repository"

usage_output="$(./scripts/eaw --help)"
grep -Fq "  eaw tracks" <<<"$usage_output" || fail "usage missing eaw tracks"

fixture_root="$tmp_root/fixture"
mkdir -p "$fixture_root"
cp -R "$REPO_ROOT/scripts" "$fixture_root/"
cp -R "$REPO_ROOT/config" "$fixture_root/"
cp -R "$REPO_ROOT/tracks" "$fixture_root/"

mkdir -p "$fixture_root/tracks/invalid-no-phases"
cat >"$fixture_root/tracks/invalid-no-phases/track.yaml" <<'EOF'
track:
  id: invalid-no-phases
EOF

mkdir -p "$fixture_root/tracks/invalid-no-track-file"

mkdir -p "$fixture_root/tracks/invalid-mismatch/phases"
cat >"$fixture_root/tracks/invalid-mismatch/track.yaml" <<'EOF'
track:
  id: another-track
EOF
cat >"$fixture_root/tracks/invalid-mismatch/phases/intake.yaml" <<'EOF'
phase:
  id: intake
  prompt:
    path: templates/prompts/default/intake/prompt_v1.md
EOF

fixture_output="$(cd "$fixture_root" && ./scripts/eaw tracks)"
[[ "$fixture_output" == "$expected_output" ]] || fail "invalid track should be omitted from fixture output"

missing_tracks_root="$tmp_root/missing-tracks"
mkdir -p "$missing_tracks_root"
cp -R "$REPO_ROOT/scripts" "$missing_tracks_root/"
cp -R "$REPO_ROOT/config" "$missing_tracks_root/"

set +e
missing_output="$(cd "$missing_tracks_root" && ./scripts/eaw tracks 2>&1)"
missing_rc=$?
set -e

[[ "$missing_rc" -ne 0 ]] || fail "missing tracks root should fail"
grep -Fq "ERROR: tracks directory not found" <<<"$missing_output" || fail "missing tracks error should be actionable"

printf "smoke tracks OK\n"
