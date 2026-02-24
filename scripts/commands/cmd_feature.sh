#!/usr/bin/env bash

cmd_feature() {
	local card="$1"
	local title="$2"
	cmd_card "feature" "$card" "$title"
}
