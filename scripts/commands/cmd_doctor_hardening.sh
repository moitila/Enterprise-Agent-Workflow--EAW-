#!/usr/bin/env bash

cmd_doctor_hardening() {
	local root_dir script_path script_name rc status
	local critical_failures=0
	local warning_count=0
	local risk="BAIXO"

	root_dir="$EAW_ROOT_DIR"

	emit_result() {
		local category="$1"
		local result="$2"
		local detail="$3"
		printf "%s: %s - %s\n" "$category" "$result" "$detail"
	}

	run_critical_check() {
		local category="$1"
		local detail="$2"
		shift 2

		if "$@" >/dev/null 2>&1; then
			emit_result "$category" "PASS" "$detail"
			return 0
		fi

		rc=$?
		emit_result "$category" "FAIL" "$detail (rc=$rc)"
		critical_failures=$((critical_failures + 1))
		return 0
	}

	run_optional_warning_check() {
		local category="$1"
		local detail="$2"
		shift 2

		if "$@" >/dev/null 2>&1; then
			emit_result "$category" "PASS" "$detail"
			return 0
		fi

		rc=$?
		emit_result "$category" "WARN" "$detail (rc=$rc)"
		warning_count=$((warning_count + 1))
		return 0
	}

	echo "EAW doctor-hardening"
	echo "CATEGORIES: PASS/FAIL/WARN"
	echo "Resolved dirs:"
	echo "  EAW_ROOT_DIR=$EAW_ROOT_DIR"
	echo "  EAW_WORKDIR=${EAW_WORKDIR:-}"
	echo "  EAW_CONFIG_DIR=$EAW_CONFIG_DIR"
	echo "  EAW_OUT_DIR=$EAW_OUT_DIR"

	run_critical_check "PROMPT_ACTIVE" "scripts/eaw prompt validate (ACTIVE metadata)" \
		"$root_dir/scripts/eaw" prompt validate

	if "$root_dir/scripts/eaw" validate >/dev/null 2>&1; then
		emit_result "VALIDATE" "PASS" "scripts/eaw validate (errors=0)"
	else
		rc=$?
		if [[ "$rc" -eq 2 ]]; then
			emit_result "VALIDATE" "FAIL" "scripts/eaw validate returned errors>0 (rc=$rc)"
			critical_failures=$((critical_failures + 1))
		else
			emit_result "VALIDATE" "WARN" "scripts/eaw validate returned non-critical rc=$rc"
			warning_count=$((warning_count + 1))
		fi
	fi

	for script_name in \
		"tests/smoke.sh" \
		"tests/run_phase_smoke.sh" \
		"tests/smoke_prompt_core.sh" \
		"tests/smoke_config_contract.sh" \
		"tests/golden_structure_check.sh" \
		"tests/scaffold_parity_smoke.sh"; do
		script_path="$root_dir/$script_name"
		if [[ ! -f "$script_path" ]]; then
			emit_result "CANONICAL_CHECK" "FAIL" "$script_name missing"
			critical_failures=$((critical_failures + 1))
			continue
		fi
		if env -u EAW_WORKDIR bash "$script_path" >/dev/null 2>&1; then
			emit_result "CANONICAL_CHECK" "PASS" "$script_name"
		else
			rc=$?
			emit_result "CANONICAL_CHECK" "FAIL" "$script_name (rc=$rc)"
			critical_failures=$((critical_failures + 1))
		fi
	done

	run_optional_warning_check "TOOLS" "command -v rg (fallback to grep tolerated)" command -v rg

	if [[ "${EAW_DOCTOR_HARDENING_FORCE_CRITICAL_FAIL:-0}" == "1" ]]; then
		emit_result "INJECTED_CRITICAL" "FAIL" "forced by EAW_DOCTOR_HARDENING_FORCE_CRITICAL_FAIL=1"
		critical_failures=$((critical_failures + 1))
	fi

	if [[ "$critical_failures" -gt 0 ]]; then
		risk="ALTO"
	elif [[ "$warning_count" -gt 0 ]]; then
		risk="MEDIO"
	fi

	echo "RISK: $risk"
	echo "SUMMARY: critical_failures=$critical_failures warnings=$warning_count"

	if [[ "$critical_failures" -gt 0 ]]; then
		return 1
	fi
	return 0
}
