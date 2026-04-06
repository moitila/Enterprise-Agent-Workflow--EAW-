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

expected_output=$'ARCH_REFACTOR\nARCH_REFACTOR_ONBOARD\nbug\nbug_ONBOARD\nfeature\nrepo_onboarding\nspike\nstandard'
actual_output="$(./scripts/eaw tracks)"
[[ "$actual_output" == "$expected_output" ]] || fail "unexpected output for current repository"

usage_output="$(./scripts/eaw --help)"
grep -Fq "  eaw tracks" <<<"$usage_output" || fail "usage missing eaw tracks"

fixture_root="$tmp_root/fixture"
mkdir -p "$fixture_root"
cp -R "$REPO_ROOT/scripts" "$fixture_root/"
cp -R "$REPO_ROOT/config" "$fixture_root/"
cp -R "$REPO_ROOT/tracks" "$fixture_root/"
cp -R "$REPO_ROOT/templates" "$fixture_root/"

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

# DA-5: eaw tracks install coverage

# Case 1: eaw validate workflow --track <track> works before install (no registry)
validate_root="$tmp_root/validate-before-install"
mkdir -p "$validate_root"
cp -R "$REPO_ROOT/scripts" "$validate_root/"
cp -R "$REPO_ROOT/config" "$validate_root/"
cp -R "$REPO_ROOT/tracks" "$validate_root/"
cp -R "$REPO_ROOT/templates" "$validate_root/"
rm -f "$validate_root/tracks/tracks.yaml"

validate_wf_output="$(cd "$validate_root" && ./scripts/eaw validate workflow --track bug 2>&1)"
grep -Fq "errors=0" <<<"$validate_wf_output" || fail "validate workflow must work before install (no registry)"

# Case 2: fresh install creates registry at tracks/tracks.yaml
install_root="$tmp_root/install-fresh"
mkdir -p "$install_root"
cp -R "$REPO_ROOT/scripts" "$install_root/"
cp -R "$REPO_ROOT/config" "$install_root/"
cp -R "$REPO_ROOT/tracks" "$install_root/"
cp -R "$REPO_ROOT/templates" "$install_root/"
rm -f "$install_root/tracks/tracks.yaml"

set +e
install_out="$(cd "$install_root" && ./scripts/eaw tracks install 2>&1)"
install_rc=$?
set -e
[[ "$install_rc" -eq 0 ]] || fail "fresh install should succeed"

[[ -f "$install_root/tracks/tracks.yaml" ]] || fail "fresh install must create tracks/tracks.yaml"
grep -Fq "track_id:" "$install_root/tracks/tracks.yaml" || fail "fresh install must register valid tracks in tracks/tracks.yaml"

# Case 3: second run is idempotent — already-installed tracks preserved
set +e
install2_out="$(cd "$install_root" && ./scripts/eaw tracks install 2>&1)"
install2_rc=$?
set -e
[[ "$install2_rc" -eq 0 ]] || fail "second install should succeed"

grep -Fq "preserved:" <<<"$install2_out" || fail "second install should report preserved tracks"
grep -Fq "installed:" <<<"$install2_out" && fail "second install should not report new installations" || true

# Case 4: invalid candidate rejected with stderr; batch not interrupted; registry written
set +e
reject_out="$(cd "$fixture_root" && ./scripts/eaw tracks install 2>&1)"
reject_rc=$?
set -e
[[ "$reject_rc" -eq 0 ]] || fail "install with partial rejections should still succeed"

grep -Fq "rejected:" <<<"$reject_out" || fail "install should report rejected candidates on stderr"
[[ -f "$fixture_root/tracks/tracks.yaml" ]] || fail "registry must exist after install with partial rejections"
grep -Fq "preserved:" <<<"$reject_out" || fail "valid tracks must be preserved when invalid candidates are present"

printf "smoke tracks OK\n"
