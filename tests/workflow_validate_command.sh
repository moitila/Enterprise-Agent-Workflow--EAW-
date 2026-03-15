#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
	printf "workflow_validate_command failed: %s\n" "$1" >&2
	exit 1
}

copy_runtime() {
	local dest="$1"
	mkdir -p "$dest"
	cp -R "$REPO_ROOT/scripts" "$dest/"
	cp -R "$REPO_ROOT/templates" "$dest/"
	cp -R "$REPO_ROOT/tracks" "$dest/"
	cp -R "$REPO_ROOT/config" "$dest/"
}

init_workdir() {
	local runtime_root="$1"
	local workdir="$2"
	"$runtime_root/scripts/eaw" init --workdir "$workdir" --force >/dev/null
}

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

valid_runtime="$tmp_root/runtime-valid"
valid_workdir="$tmp_root/workdir-valid"
copy_runtime "$valid_runtime"
init_workdir "$valid_runtime" "$valid_workdir"

valid_output="$(EAW_WORKDIR="$valid_workdir" "$valid_runtime/scripts/eaw" validate workflow --track feature 2>&1)" || fail "valid feature track should pass"
grep -Fq "OK track=feature" <<<"$valid_output" || fail "valid feature output missing OK summary"
grep -Fq "SUMMARY: errors=0 warnings=0" <<<"$valid_output" || fail "valid feature output missing clean summary"

all_output="$(EAW_WORKDIR="$valid_workdir" "$valid_runtime/scripts/eaw" validate workflow --all 2>&1)" || fail "validate workflow --all should pass on shipped tracks"
grep -Fq "OK track=standard" <<<"$all_output" || fail "validate workflow --all missing standard track"
grep -Fq "OK track=feature" <<<"$all_output" || fail "validate workflow --all missing feature track"

manual_runtime="$tmp_root/runtime-manual"
manual_workdir="$tmp_root/workdir-manual"
copy_runtime "$manual_runtime"
init_workdir "$manual_runtime" "$manual_workdir"
sed -i 's/strategy: required_artifacts_exist/strategy: manual/' "$manual_runtime/tracks/feature/phases/findings.yaml"
if manual_output="$(EAW_WORKDIR="$manual_workdir" "$manual_runtime/scripts/eaw" validate workflow --track feature 2>&1)"; then
	fail "unknown completion strategy should fail"
fi
grep -Fq "field=completion.strategy" <<<"$manual_output" || fail "manual strategy output missing field"
grep -Fq "unknown strategy 'manual'" <<<"$manual_output" || fail "manual strategy output missing message"

transition_runtime="$tmp_root/runtime-transition"
transition_workdir="$tmp_root/workdir-transition"
copy_runtime "$transition_runtime"
init_workdir "$transition_runtime" "$transition_workdir"
sed -i 's/next: hypotheses/next: missing_phase/' "$transition_runtime/tracks/feature/track.yaml"
if transition_output="$(EAW_WORKDIR="$transition_workdir" "$transition_runtime/scripts/eaw" validate workflow --track feature 2>&1)"; then
	fail "missing transition target should fail"
fi
grep -Fq "field=transitions" <<<"$transition_output" || fail "transition output missing field"
grep -Fq "target phase 'missing_phase' does not exist" <<<"$transition_output" || fail "transition output missing target error"

outputs_runtime="$tmp_root/runtime-outputs"
outputs_workdir="$tmp_root/workdir-outputs"
copy_runtime "$outputs_runtime"
init_workdir "$outputs_runtime" "$outputs_workdir"
sed -i 's/^    create_artifacts:$/    create_artifacts: invalid/' "$outputs_runtime/tracks/feature/phases/findings.yaml"
if outputs_output="$(EAW_WORKDIR="$outputs_workdir" "$outputs_runtime/scripts/eaw" validate workflow --track feature 2>&1)"; then
	fail "invalid phase.outputs should fail"
fi
grep -Fq "field=outputs" <<<"$outputs_output" || fail "outputs validation missing field"
grep -Fq "key 'create_artifacts' must be declared as list or []" <<<"$outputs_output" || fail "outputs validation missing structural error"

printf "workflow_validate_command OK\n"
