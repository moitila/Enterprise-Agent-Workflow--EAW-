#!/usr/bin/env python3
"""Small deterministic quality checks for domain-analysis semantics and coverage."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import yaml


def load(path: str):
    text = Path(path).read_text(encoding="utf-8")
    return json.loads(text) if path.endswith(".json") else yaml.safe_load(text)


def validate_coverage(ledger_path: str, dispositions_path: str) -> dict:
    ledger = load(ledger_path) or {}
    dispositions = load(dispositions_path) or {}
    candidates = ledger.get("candidates", [])
    rows = dispositions.get("dispositions", [])
    ids = [item.get("candidate_id") for item in candidates]
    decided = [item.get("candidate_id") for item in rows]
    errors = []
    if len(ids) != len(set(ids)):
        errors.append("duplicate_candidate_id")
    if sorted(ids) != sorted(decided):
        errors.append("disposition_parity")
    return {"valid": not errors, "checks": {"unique_candidate_ids": len(ids) == len(set(ids)),
            "disposition_parity": sorted(ids) == sorted(decided),
            "no_silent_disappearance": sorted(ids) == sorted(decided)}, "errors": errors}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("coverage", choices=["coverage"])
    parser.add_argument("ledger")
    parser.add_argument("dispositions")
    args = parser.parse_args()
    try:
        result = validate_coverage(args.ledger, args.dispositions)
    except (OSError, ValueError, TypeError, AttributeError, yaml.YAMLError) as exc:
        print(json.dumps({"valid": False, "errors": [str(exc)]}))
        return 2
    print(json.dumps(result, sort_keys=True))
    return 0 if result["valid"] else 1


if __name__ == "__main__":
    sys.exit(main())
