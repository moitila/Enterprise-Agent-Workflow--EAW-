#!/usr/bin/env bash

cmd_implement() {
	local card="${1:-}"
	local card_dir impl_dir
	local created=0
	local preserved=0

	if [[ -z "$card" ]]; then
		die "missing <CARD> argument"
	fi
	if [[ ! "$card" =~ ^[0-9]+$ ]]; then
		die "invalid <CARD> '$card' (expected digits only)"
	fi

	card_dir="$EAW_OUT_DIR/$card"
	if [[ ! -d "$card_dir" ]]; then
		die "card output directory not found: $card_dir"
	fi

	impl_dir="$card_dir/implementation"
	if [[ -d "$impl_dir" ]]; then
		echo "PRESERVED: $impl_dir"
		preserved=$((preserved + 1))
	else
		ensure_dir "$impl_dir"
		echo "CREATED: $impl_dir"
		created=$((created + 1))
	fi

	for name in 00_scope.lock.md 10_change_plan.md 20_patch_notes.md; do
		local target="$impl_dir/$name"
		if [[ -f "$target" ]]; then
			echo "PRESERVED: $target"
			preserved=$((preserved + 1))
			continue
		fi
		case "$name" in
		00_scope.lock.md)
			cat >"$target" <<EOF
# Scope Lock - Card $card

## In Scope

## Out of Scope
EOF
			;;
		10_change_plan.md)
			cat >"$target" <<EOF
# Change Plan - Card $card

## Steps

## Validation
EOF
			;;
		20_patch_notes.md)
			cat >"$target" <<EOF
# Patch Notes - Card $card

## Changes

## Risks
EOF
			;;
		esac
		echo "CREATED: $target"
		created=$((created + 1))
	done

	echo "SUMMARY: created=$created preserved=$preserved"
}
