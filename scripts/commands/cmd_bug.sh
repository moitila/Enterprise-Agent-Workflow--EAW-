#!/usr/bin/env bash

cmd_bug() {
	local card="$1"
	local title="$2"
	cmd_card "bug" "$card" "$title"
}
