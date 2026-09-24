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

python3 tracks/domain_analysis/tools/contract_tool.py self-test >/dev/null
python3 -m unittest tracks/domain_analysis/tests/test_contract_tool.py

expected_output=$'ARCH_REFACTOR\nARCH_REFACTOR_ONBOARD\nadversarial_review\nbug\nbug_ONBOARD\ndomain_analysis\nexternal_review\nfeature\nfeature_dynamic\nfeedback_review\npatch\nrepo_onboarding\nrepo_onboarding_refresh\nspike\nstandard\nsystem_analysis\ntrack_creator'
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
cp -R "$REPO_ROOT/skills" "$fixture_root/"

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
cp -R "$REPO_ROOT/skills" "$validate_root/"
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
cp -R "$REPO_ROOT/skills" "$install_root/"
rm -f "$install_root/tracks/tracks.yaml"

set +e
install_out="$(cd "$install_root" && ./scripts/eaw tracks install 2>&1)"
install_rc=$?
set -e
[[ "$install_rc" -eq 0 ]] || fail "fresh install should succeed"

[[ -f "$install_root/tracks/tracks.yaml" ]] || fail "fresh install must create tracks/tracks.yaml"
grep -Fq "track_id:" "$install_root/tracks/tracks.yaml" || fail "fresh install must register valid tracks in tracks/tracks.yaml"

# Case 3: second run is idempotent — already-installed tracks preserved
install_registry_before_second="$tmp_root/install-registry-before-second.yaml"
cp "$install_root/tracks/tracks.yaml" "$install_registry_before_second"

set +e
install2_out="$(cd "$install_root" && ./scripts/eaw tracks install 2>&1)"
install2_rc=$?
set -e
[[ "$install2_rc" -eq 0 ]] || fail "second install should succeed"

grep -Fq "preserved:" <<<"$install2_out" || fail "second install should report preserved tracks"
grep -Fq "installed:" <<<"$install2_out" && fail "second install should not report new installations" || true
cmp -s "$install_registry_before_second" "$install_root/tracks/tracks.yaml" || fail "second install must not change registry bytes"

# Case 4: existing registry order and bytes are preserved while missing tracks are appended
cat >"$fixture_root/tracks/tracks.yaml" <<'EOF'
tracks:
  - track_id: track_creator
    status: installed
  - track_id: adversarial_review
    status: installed
EOF
fixture_registry_prefix="$tmp_root/fixture-registry-prefix.yaml"
cp "$fixture_root/tracks/tracks.yaml" "$fixture_registry_prefix"
fixture_prefix_size="$(wc -c <"$fixture_registry_prefix")"

set +e
reject_out="$(cd "$fixture_root" && ./scripts/eaw tracks install 2>&1)"
reject_rc=$?
set -e
[[ "$reject_rc" -eq 0 ]] || fail "install with partial rejections should still succeed"

grep -Fq "rejected:" <<<"$reject_out" || fail "install should report rejected candidates on stderr"
[[ -f "$fixture_root/tracks/tracks.yaml" ]] || fail "registry must exist after install with partial rejections"
grep -Fq "preserved:" <<<"$reject_out" || fail "valid tracks must be preserved when invalid candidates are present"
cmp -n "$fixture_prefix_size" "$fixture_registry_prefix" "$fixture_root/tracks/tracks.yaml" || fail "existing registry bytes and order must remain unchanged"

expected_appended="$(cd "$fixture_root" && ./scripts/eaw tracks 2>/dev/null | awk '$0 != "track_creator" && $0 != "adversarial_review"')"
actual_appended="$(awk '/^[[:space:]]*-[[:space:]]+track_id:[[:space:]]*/ { print $3 }' "$fixture_root/tracks/tracks.yaml" | tail -n +3)"
[[ "$actual_appended" == "$expected_appended" ]] || fail "missing tracks must be appended in discovery order"

while IFS= read -r track_id; do
	track_count="$(awk -v id="$track_id" '/^[[:space:]]*-[[:space:]]+track_id:[[:space:]]*/ && $3 == id { count++ } END { print count + 0 }' "$fixture_root/tracks/tracks.yaml")"
	[[ "$track_count" -eq 1 ]] || fail "track '$track_id' must appear exactly once"
done < <(awk '/^[[:space:]]*-[[:space:]]+track_id:[[:space:]]*/ { print $3 }' "$fixture_root/tracks/tracks.yaml")

fixture_registry_after_first="$tmp_root/fixture-registry-after-first.yaml"
cp "$fixture_root/tracks/tracks.yaml" "$fixture_registry_after_first"
set +e
reject_second_out="$(cd "$fixture_root" && ./scripts/eaw tracks install 2>&1)"
reject_second_rc=$?
set -e
[[ "$reject_second_rc" -eq 0 ]] || fail "second install with partial rejections should succeed"
grep -Fq "installed:" <<<"$reject_second_out" && fail "second install should not append existing tracks" || true
cmp -s "$fixture_registry_after_first" "$fixture_root/tracks/tracks.yaml" || fail "second install must preserve the complete registry byte for byte"

printf "smoke tracks OK\n"
