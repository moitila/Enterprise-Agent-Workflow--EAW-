#!/usr/bin/env bash

cmd_prompt() {
	local card="$1"
	echo "WARNING: eaw prompt <CARD> is deprecated; use eaw analyze <CARD>." >&2
	cmd_analyze "$card"
}
