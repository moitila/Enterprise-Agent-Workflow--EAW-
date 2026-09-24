#!/usr/bin/env python3
"""Mechanical validators for the system_analysis track contract."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any, Callable


CONTRACT_PATH = Path(__file__).resolve().parents[1] / "contracts" / "contract_v1.json"


class ContractError(ValueError):
    """A deterministic domain-contract validation failure."""


def load_json(path: Path, *, compact: bool = False) -> Any:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ContractError(f"cannot read {path}: {exc.strerror}") from exc
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ContractError(f"invalid JSON: {exc.msg}") from exc
    if compact:
        encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        if raw not in (encoded, encoded + "\n"):
            raise ContractError("handoff JSON must be compact")
    return value


def load_contract() -> dict[str, Any]:
    contract = load_json(CONTRACT_PATH)
    if not isinstance(contract, dict) or contract.get("contract_version") != 1:
        raise ContractError("unsupported contract version")
    return contract


def require_object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContractError(f"{label} must be an object")
    return value


def require_non_empty_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ContractError(f"{label} must be a non-empty string")
    return value


def require_contract_version(value: dict[str, Any]) -> None:
    if value.get("contract_version") != 1:
        raise ContractError("contract version mismatch")


def is_sha256(value: Any) -> bool:
    return (
        isinstance(value, str)
        and len(value) == 64
        and value == value.lower()
        and all(character in "0123456789abcdef" for character in value)
    )


def aggregate_digest(files: dict[str, str]) -> str:
    payload = b"".join(
        destination.encode("utf-8") + b"\0" + files[destination].encode("ascii") + b"\n"
        for destination in sorted(files)
    )
    return hashlib.sha256(payload).hexdigest()


def validate_handoff(
    handoff: Any, phase: str, status: str, contract: dict[str, Any]
) -> dict[str, Any]:
    value = require_object(handoff, "handoff")
    expected_keys = {"from_phase", "status", "messages", "codes"}
    optional_keys = {"code_origin", "inherited_from"}
    if status == "waiting":
        expected_keys.update(contract["waiting_required_fields"])
    if not expected_keys <= set(value) or set(value) - expected_keys - optional_keys:
        raise ContractError("handoff keys mismatch")
    if "code_origin" in value and value["code_origin"] not in ("emitted", "inherited"):
        raise ContractError("handoff code origin is invalid")
    if "inherited_from" in value:
        if value.get("code_origin") != "inherited":
            raise ContractError("handoff inheritance requires inherited code origin")
        require_non_empty_string(value["inherited_from"], "inherited_from")
    if value["from_phase"] != phase:
        raise ContractError("handoff phase mismatch")
    if status not in contract["handoff_statuses"] or value["status"] != status:
        raise ContractError("handoff status mismatch")
    if not isinstance(value["messages"], list) or not all(
        isinstance(message, str) for message in value["messages"]
    ):
        raise ContractError("handoff messages must be a string array")
    if status == "completed":
        if value["codes"] != []:
            raise ContractError("completed handoff codes must be empty")
    else:
        if phase not in contract["waiting_phases"]:
            raise ContractError("phase cannot wait")
        require_non_empty_string(value["blocker"], "blocker")
        if value["messages"] != []:
            raise ContractError("waiting handoff messages must be empty")
        if value["codes"] != [contract["waiting_code"]]:
            raise ContractError("waiting handoff code mismatch")
    return value


def validate_topology(value: Any, contract: dict[str, Any]) -> dict[str, Any]:
    receipt = require_object(value, "topology")
    require_contract_version(receipt)
    entries = receipt.get("entries")
    if not isinstance(entries, list):
        raise ContractError("entries must be an array")
    scenario = receipt.get("scenario")
    expected_scenario = "zero" if not entries else "one" if len(entries) == 1 else "many"
    if scenario != expected_scenario:
        raise ContractError("scenario does not match entry count")
    if receipt.get("order_invariant") is not True:
        raise ContractError("topology must be order invariant")
    keys: list[str] = []
    for entry_value in entries:
        entry = require_object(entry_value, "repository entry")
        repo_key = require_non_empty_string(entry.get("repo_key"), "repo_key")
        if entry.get("status") not in contract["repository_statuses"]:
            raise ContractError("repository status is not allowed")
        locator = require_object(entry.get("locator"), "locator")
        require_non_empty_string(locator.get("type"), "locator type")
        require_non_empty_string(locator.get("value"), "locator value")
        forbidden_keys = {"authority_index", "authoritative_index", "source_order"}
        if forbidden_keys.intersection(entry):
            raise ContractError("authority cannot be derived from order")
        authority_source = entry.get("authority_source")
        if authority_source in {"index", "order", "first_target"}:
            raise ContractError("authority cannot be derived from order")
        keys.append(repo_key)
    if len(keys) != len(set(keys)):
        raise ContractError("repository keys must be unique")
    return {
        "contract_version": 1,
        "valid": True,
        "scenario": scenario,
        "repository_keys": sorted(keys),
        "order_invariant": True,
    }


def validate_authority(value: Any) -> dict[str, Any]:
    authority = require_object(value, "authority")
    require_contract_version(authority)
    state = authority.get("state")
    if state == "waiting":
        if authority.get("binding") is not None:
            raise ContractError("waiting authority binding must be null")
        request_id = require_non_empty_string(authority.get("request_id"), "request_id")
        return {
            "contract_version": 1,
            "valid": False,
            "state": "waiting",
            "request_id": request_id,
            "errors": [],
        }
    if state != "resolved":
        raise ContractError("authority state must be resolved or waiting")
    binding_value = authority.get("binding")
    if isinstance(binding_value, list):
        if len(binding_value) != 1:
            raise ContractError("authority must contain exactly one binding")
        binding_value = binding_value[0]
    binding = require_object(binding_value, "authority binding")
    if set(binding) != {"repo_key", "publication_root", "source"}:
        raise ContractError("authority binding keys mismatch")
    for key in ("repo_key", "publication_root", "source"):
        require_non_empty_string(binding.get(key), key)
    return {
        "contract_version": 1,
        "valid": True,
        "state": "resolved",
        "binding": binding,
        "errors": [],
    }


def validate_candidate(value: Any, contract: dict[str, Any]) -> dict[str, Any]:
    candidate = require_object(value, "candidate")
    require_contract_version(candidate)
    require_non_empty_string(candidate.get("repo_key"), "repo_key")
    require_non_empty_string(candidate.get("base_revision"), "base_revision")
    files = require_object(candidate.get("files"), "files")
    expected_paths = contract["permanent_paths"]
    if list(files) != expected_paths:
        raise ContractError("candidate destinations must use canonical order")
    if set(files) != set(expected_paths) or len(files) != 4:
        raise ContractError("candidate destinations mismatch")
    if not all(is_sha256(digest) for digest in files.values()):
        raise ContractError("candidate file digest is invalid")
    calculated = aggregate_digest(files)
    if candidate.get("candidate_digest") != calculated:
        raise ContractError("candidate digest mismatch")
    return {
        "contract_version": 1,
        "valid": True,
        "candidate_digest": calculated,
        "paths": expected_paths,
        "errors": [],
    }


def validate_approval(request_value: Any, record_value: Any | None) -> dict[str, Any]:
    request = require_object(request_value, "approval request")
    require_contract_version(request)
    request_id = require_non_empty_string(request.get("request_id"), "request_id")
    for key in ("candidate_identity", "candidate_digest", "base_revision"):
        require_non_empty_string(request.get(key), key)
    authority = require_object(request.get("authority"), "authority")
    if record_value is None:
        return {
            "contract_version": 1,
            "valid": False,
            "state": "waiting",
            "request_id": request_id,
            "errors": [],
        }
    record = require_object(record_value, "approval record")
    require_contract_version(record)
    if record.get("request_id") != request_id:
        raise ContractError("request id mismatch")
    if record.get("candidate_identity") != request["candidate_identity"]:
        raise ContractError("candidate identity mismatch")
    if record.get("candidate_digest") != request["candidate_digest"]:
        raise ContractError("candidate digest mismatch")
    if record.get("authority") != authority:
        raise ContractError("authority mismatch")
    if record.get("base_revision") != request["base_revision"]:
        raise ContractError("base revision mismatch")
    if record.get("decision") != "approved":
        raise ContractError("approval decision must be approved")
    approver = require_non_empty_string(record.get("approver"), "approver")
    return {
        "contract_version": 1,
        "valid": True,
        "state": "approved",
        "request_id": request_id,
        "approved_digest": request["candidate_digest"],
        "approver": approver,
        "errors": [],
    }


def validate_publication(
    request_value: Any, result_value: Any | None, contract: dict[str, Any]
) -> dict[str, Any]:
    request = require_object(request_value, "publication request")
    require_contract_version(request)
    request_id = require_non_empty_string(request.get("request_id"), "request_id")
    for key in ("repo_key", "base_revision", "approved_digest"):
        require_non_empty_string(request.get(key), key)
    if request.get("paths") != contract["permanent_paths"]:
        raise ContractError("unauthorized destination")
    if result_value is None:
        return {
            "contract_version": 1,
            "valid": False,
            "state": "waiting",
            "request_id": request_id,
            "errors": [],
        }
    result = require_object(result_value, "publication result")
    require_contract_version(result)
    if result.get("request_id") != request_id:
        raise ContractError("request id mismatch")
    if result.get("repo_key") != request["repo_key"]:
        raise ContractError("repository key mismatch")
    if result.get("base_revision") != request["base_revision"]:
        raise ContractError("base revision mismatch")
    if result.get("paths") != contract["permanent_paths"]:
        raise ContractError("unauthorized destination")
    if result.get("published_digest") != request["approved_digest"]:
        raise ContractError("published digest mismatch")
    revision = require_non_empty_string(result.get("revision"), "revision")
    return {
        "contract_version": 1,
        "valid": True,
        "state": "published",
        "request_id": request_id,
        "published_digest": result["published_digest"],
        "revision": revision,
        "paths": contract["permanent_paths"],
        "errors": [],
    }


def validate_consumption(value: Any, contract: dict[str, Any]) -> dict[str, Any]:
    receipt = require_object(value, "consumption")
    require_contract_version(receipt)
    digests = [
        require_non_empty_string(receipt.get(key), key)
        for key in (
            "candidate_digest",
            "approved_digest",
            "published_digest",
            "consumed_digest",
        )
    ]
    if len(set(digests)) != 1:
        raise ContractError("digest chain mismatch")
    require_non_empty_string(receipt.get("repo_key"), "repo_key")
    require_non_empty_string(receipt.get("revision"), "revision")
    if receipt.get("paths") != contract["permanent_paths"]:
        raise ContractError("unauthorized destination")
    return {
        "contract_version": 1,
        "valid": True,
        "consumed_digest": digests[0],
        "paths": contract["permanent_paths"],
        "errors": [],
    }


def expect_failure(name: str, action: Callable[[], Any]) -> str:
    try:
        action()
    except ContractError as exc:
        return str(exc)
    raise ContractError(f"self-test negative case accepted: {name}")


def run_self_test(contract: dict[str, Any]) -> dict[str, Any]:
    def topology(entries: list[dict[str, Any]]) -> dict[str, Any]:
        count = len(entries)
        return {
            "contract_version": 1,
            "entries": entries,
            "scenario": "zero" if count == 0 else "one" if count == 1 else "many",
            "order_invariant": True,
        }

    entry_a = {
        "repo_key": "a",
        "status": "active",
        "locator": {"type": "path", "value": "/tmp/a"},
    }
    entry_b = {
        "repo_key": "b",
        "status": "planned",
        "locator": {"type": "url", "value": "https://example.invalid/b"},
    }
    zero = validate_topology(topology([]), contract)
    one = validate_topology(topology([entry_a]), contract)
    many_ab = validate_topology(topology([entry_a, entry_b]), contract)
    many_ba = validate_topology(topology([entry_b, entry_a]), contract)
    if many_ab != many_ba:
        raise ContractError("topology order invariance failed")

    authority = {"repo_key": "a", "publication_root": "/tmp/a", "source": "decision-1"}
    request = {
        "contract_version": 1,
        "request_id": "approval-1",
        "candidate_identity": "candidate-1",
        "candidate_digest": "a" * 64,
        "authority": authority,
        "base_revision": "revision-1",
    }
    record = {
        **request,
        "decision": "approved",
        "approver": "reviewer-1",
    }
    publication_request = {
        "contract_version": 1,
        "request_id": "publication-1",
        "repo_key": "a",
        "base_revision": "revision-1",
        "approved_digest": "a" * 64,
        "paths": contract["permanent_paths"],
    }
    publication_result = {
        **publication_request,
        "published_digest": "a" * 64,
        "revision": "revision-2",
    }

    negative_results = {
        "candidate_changed_after_approval": expect_failure(
            "candidate_changed_after_approval",
            lambda: validate_approval(request, {**record, "candidate_digest": "b" * 64}),
        ),
        "request_id_mismatch": expect_failure(
            "request_id_mismatch",
            lambda: validate_approval(request, {**record, "request_id": "wrong"}),
        ),
        "authority_missing_or_multiple": expect_failure(
            "authority_missing_or_multiple",
            lambda: validate_authority(
                {"contract_version": 1, "state": "resolved", "binding": []}
            ),
        ),
        "base_revision_mismatch": expect_failure(
            "base_revision_mismatch",
            lambda: validate_approval(request, {**record, "base_revision": "wrong"}),
        ),
        "unauthorized_destination": expect_failure(
            "unauthorized_destination",
            lambda: validate_publication(
                publication_request,
                {**publication_result, "paths": contract["permanent_paths"] + ["extra"]},
                contract,
            ),
        ),
    }
    if set(negative_results) != set(contract["negative_cases"]):
        raise ContractError("self-test negative case coverage mismatch")
    return {
        "contract_version": 1,
        "valid": True,
        "topology_scenarios": [zero["scenario"], one["scenario"], many_ab["scenario"]],
        "order_invariant": True,
        "negative_cases": list(negative_results),
    }


def emit(value: dict[str, Any]) -> int:
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="contract_tool.py")
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("self-test")

    handoff = subparsers.add_parser("handoff")
    handoff.add_argument("file", type=Path)
    handoff.add_argument("phase")
    handoff.add_argument("status")

    for command in ("topology", "authority", "candidate", "consumption"):
        child = subparsers.add_parser(command)
        child.add_argument("file", type=Path)

    approval = subparsers.add_parser("approval")
    approval.add_argument("request", type=Path)
    approval.add_argument("record")

    publication = subparsers.add_parser("publication")
    publication.add_argument("request", type=Path)
    publication.add_argument("result")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        contract = load_contract()
        if args.command == "self-test":
            result = run_self_test(contract)
        elif args.command == "handoff":
            result = validate_handoff(
                load_json(args.file, compact=True), args.phase, args.status, contract
            )
        elif args.command == "topology":
            result = validate_topology(load_json(args.file), contract)
        elif args.command == "authority":
            result = validate_authority(load_json(args.file))
        elif args.command == "candidate":
            result = validate_candidate(load_json(args.file), contract)
        elif args.command == "approval":
            record = None if args.record == "-" else load_json(Path(args.record))
            result = validate_approval(load_json(args.request), record)
        elif args.command == "publication":
            publication_result = None if args.result == "-" else load_json(Path(args.result))
            result = validate_publication(load_json(args.request), publication_result, contract)
        else:
            result = validate_consumption(load_json(args.file), contract)
        return emit(result)
    except ContractError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
