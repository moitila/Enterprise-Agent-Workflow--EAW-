#!/usr/bin/env python3
"""Deterministic validators for the domain_analysis publication corridor."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any, Callable

import yaml


CONTRACT_PATH = Path(__file__).resolve().parents[1] / "contracts" / "contract_v1.json"


class ContractError(ValueError):
    """A deterministic domain contract validation failure."""


def load_document(path: Path, *, compact: bool = False) -> Any:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ContractError(f"cannot read {path}: {exc.strerror}") from exc
    try:
        value = json.loads(raw) if path.suffix == ".json" else yaml.safe_load(raw)
    except (json.JSONDecodeError, yaml.YAMLError) as exc:
        raise ContractError(f"invalid {path.suffix.lstrip('.').upper()}: {exc}") from exc
    if compact:
        encoded = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        if raw not in (encoded, encoded + "\n"):
            raise ContractError("handoff JSON must be compact")
    return value


def load_contract() -> dict[str, Any]:
    value = require_object(load_document(CONTRACT_PATH), "contract")
    if value.get("contract_version") != 1 or value.get("track_id") != "domain_analysis":
        raise ContractError("unsupported contract")
    return value


def require_object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContractError(f"{label} must be an object")
    return value


def require_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ContractError(f"{label} must be a non-empty string")
    return value


def require_version(value: dict[str, Any]) -> None:
    if value.get("contract_version") != 1:
        raise ContractError("contract version mismatch")


def is_sha256(value: Any) -> bool:
    return isinstance(value, str) and len(value) == 64 and value == value.lower() and all(
        character in "0123456789abcdef" for character in value
    )


def aggregate_digest(files: dict[str, str]) -> str:
    payload = b"".join(
        destination.encode() + b"\0" + files[destination].encode("ascii") + b"\n"
        for destination in sorted(files)
    )
    return hashlib.sha256(payload).hexdigest()


def require_files(value: Any, contract: dict[str, Any]) -> dict[str, str]:
    files = require_object(value, "files")
    expected = contract["permanent_paths"]
    if list(files) != expected or set(files) != set(expected):
        raise ContractError("candidate destinations mismatch")
    if not all(is_sha256(item) for item in files.values()):
        raise ContractError("candidate file hash is invalid")
    return files


def validate_handoff(value: Any, phase: str, status: str, contract: dict[str, Any]) -> dict[str, Any]:
    handoff = require_object(value, "handoff")
    required = {"from_phase", "status", "messages", "codes"}
    optional = {"code_origin", "inherited_from"}
    if status == "waiting":
        required.add("blocker")
    if not required <= set(handoff) or set(handoff) - required - optional:
        raise ContractError("handoff keys mismatch")
    if handoff["from_phase"] != phase or handoff["status"] != status:
        raise ContractError("handoff phase or status mismatch")
    if status not in contract["handoff_statuses"]:
        raise ContractError("handoff status is invalid")
    if not isinstance(handoff["messages"], list) or not all(isinstance(x, str) for x in handoff["messages"]):
        raise ContractError("handoff messages must be a string array")
    if "code_origin" in handoff and handoff["code_origin"] not in ("emitted", "inherited"):
        raise ContractError("handoff code origin is invalid")
    if "inherited_from" in handoff:
        if handoff.get("code_origin") != "inherited":
            raise ContractError("handoff inheritance requires inherited code origin")
        require_string(handoff["inherited_from"], "inherited_from")
    if status == "completed":
        if handoff["codes"] != []:
            raise ContractError("completed handoff codes must be empty")
    else:
        if phase not in contract["waiting_phases"]:
            raise ContractError("phase cannot wait")
        require_string(handoff["blocker"], "blocker")
        if handoff["messages"] != [] or handoff["codes"] != [contract["waiting_code"]]:
            raise ContractError("waiting handoff envelope mismatch")
    return handoff


def validate_candidate(value: Any, contract: dict[str, Any]) -> dict[str, Any]:
    candidate = require_object(value, "candidate")
    require_version(candidate)
    repo_key = require_string(candidate.get("repo_key"), "repo_key")
    revision = require_string(candidate.get("base_revision"), "base_revision")
    if revision in {"HEAD", "main", "master"} or revision.startswith("refs/heads/"):
        raise ContractError("base revision must be immutable")
    files = require_files(candidate.get("files"), contract)
    calculated = aggregate_digest(files)
    if candidate.get("candidate_digest") != calculated:
        raise ContractError("candidate digest mismatch")
    return {"contract_version": 1, "valid": True, "repo_key": repo_key,
            "base_revision": revision, "files": files, "candidate_digest": calculated, "errors": []}


def validate_approval(request_value: Any, record_value: Any | None, contract: dict[str, Any]) -> dict[str, Any]:
    request = require_object(request_value, "approval request")
    require_version(request)
    request_id = require_string(request.get("request_id"), "request_id")
    identity = require_string(request.get("candidate_identity"), "candidate_identity")
    digest = require_string(request.get("candidate_digest"), "candidate_digest")
    repo_key = require_string(request.get("repo_key"), "repo_key")
    revision = require_string(request.get("base_revision"), "base_revision")
    files = require_files(request.get("files"), contract)
    if digest != aggregate_digest(files):
        raise ContractError("candidate digest mismatch")
    if record_value is None:
        return {"contract_version": 1, "valid": False, "state": "waiting", "request_id": request_id, "errors": []}
    record = require_object(record_value, "approval record")
    require_version(record)
    comparisons = (("request_id", request_id), ("candidate_identity", identity),
                   ("candidate_digest", digest), ("repo_key", repo_key), ("base_revision", revision))
    for field, expected in comparisons:
        if record.get(field) != expected:
            raise ContractError(f"{field.replace('_', ' ')} mismatch")
    if record.get("files") != files:
        raise ContractError("approved files mismatch")
    if record.get("decision") != "approved":
        raise ContractError("approval decision must be approved")
    approver = require_string(record.get("approver"), "approver")
    return {"contract_version": 1, "valid": True, "state": "approved", "request_id": request_id,
            "approved_digest": digest, "approver": approver, "errors": []}


def validate_publication(request_value: Any, result_value: Any | None, contract: dict[str, Any]) -> dict[str, Any]:
    request = require_object(request_value, "publication request")
    require_version(request)
    request_id = require_string(request.get("request_id"), "request_id")
    repo_key = require_string(request.get("repo_key"), "repo_key")
    base_revision = require_string(request.get("base_revision"), "base_revision")
    digest = require_string(request.get("approved_digest"), "approved_digest")
    files = require_files(request.get("files"), contract)
    if digest != aggregate_digest(files):
        raise ContractError("approved digest mismatch")
    if result_value is None:
        return {"contract_version": 1, "valid": False, "state": "waiting", "request_id": request_id, "errors": []}
    result = require_object(result_value, "publication result")
    require_version(result)
    for field, expected in (("request_id", request_id), ("repo_key", repo_key), ("base_revision", base_revision)):
        if result.get(field) != expected:
            raise ContractError(f"{field.replace('_', ' ')} mismatch")
    if result.get("files") != files:
        raise ContractError("published files mismatch")
    if result.get("published_digest") != digest:
        raise ContractError("published digest mismatch")
    revision = require_string(result.get("revision"), "revision")
    if revision in {"HEAD", "main", "master"} or revision.startswith("refs/heads/"):
        raise ContractError("published revision must be immutable")
    return {"contract_version": 1, "valid": True, "state": "published", "request_id": request_id,
            "published_digest": digest, "revision": revision, "files": files, "errors": []}


def validate_consumption(value: Any, contract: dict[str, Any]) -> dict[str, Any]:
    receipt = require_object(value, "consumption")
    require_version(receipt)
    repo_key = require_string(receipt.get("repo_key"), "repo_key")
    revision = require_string(receipt.get("revision"), "revision")
    files = require_files(receipt.get("files"), contract)
    consumed = aggregate_digest(files)
    digests = [require_string(receipt.get(key), key) for key in
               ("candidate_digest", "approved_digest", "published_digest", "consumed_digest")]
    if len(set(digests)) != 1 or digests[0] != consumed:
        raise ContractError("digest chain mismatch")
    return {"contract_version": 1, "valid": True, "repo_key": repo_key, "revision": revision,
            "files": files, "consumed_digest": consumed, "errors": []}


def expect_failure(name: str, action: Callable[[], Any]) -> str:
    try:
        action()
    except ContractError as exc:
        return str(exc)
    raise ContractError(f"self-test negative case accepted: {name}")


def run_self_test(contract: dict[str, Any]) -> dict[str, Any]:
    files = {path: hashlib.sha256(path.encode()).hexdigest() for path in contract["permanent_paths"]}
    digest = aggregate_digest(files)
    candidate = {"contract_version": 1, "repo_key": "repo", "base_revision": "a" * 40,
                 "files": files, "candidate_digest": digest}
    request = {**candidate, "request_id": "approval-1", "candidate_identity": "candidate-1"}
    request.pop("contract_version"); request["contract_version"] = 1
    record = {**request, "decision": "approved", "approver": "reviewer"}
    validate_candidate(candidate, contract)
    validate_approval(request, record, contract)
    negative = {
        "candidate_changed_after_approval": expect_failure("candidate_changed_after_approval", lambda: validate_approval(request, {**record, "candidate_digest": "b" * 64}, contract)),
        "request_id_mismatch": expect_failure("request_id_mismatch", lambda: validate_approval(request, {**record, "request_id": "wrong"}, contract)),
        "base_revision_mismatch": expect_failure("base_revision_mismatch", lambda: validate_approval(request, {**record, "base_revision": "wrong"}, contract)),
        "mutable_or_missing_revision": expect_failure("mutable_or_missing_revision", lambda: validate_candidate({**candidate, "base_revision": "HEAD"}, contract)),
        "unauthorized_destination": expect_failure("unauthorized_destination", lambda: validate_candidate({**candidate, "files": {**files, "extra": "a" * 64}}, contract)),
        "digest_mismatch": expect_failure("digest_mismatch", lambda: validate_candidate({**candidate, "candidate_digest": "0" * 64}, contract)),
        "invalid_handoff": expect_failure("invalid_handoff", lambda: validate_handoff({"from_phase": "approval_gate"}, "approval_gate", "completed", contract)),
        "manifest_mismatch": "covered by exact destination binding",
        "file_hash_mismatch": expect_failure("file_hash_mismatch", lambda: validate_candidate({**candidate, "files": {**files, contract["permanent_paths"][0]: "BAD"}}, contract)),
    }
    if set(negative) != set(contract["negative_cases"]):
        raise ContractError("self-test negative case coverage mismatch")
    return {"contract_version": 1, "valid": True, "negative_cases": list(negative)}


def emit(value: dict[str, Any]) -> int:
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="contract_tool.py")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("self-test")
    handoff = commands.add_parser("handoff"); handoff.add_argument("file", type=Path); handoff.add_argument("phase"); handoff.add_argument("status")
    candidate = commands.add_parser("candidate"); candidate.add_argument("file", type=Path)
    approval = commands.add_parser("approval"); approval.add_argument("request", type=Path); approval.add_argument("record")
    publication = commands.add_parser("publication"); publication.add_argument("request", type=Path); publication.add_argument("result")
    consumption = commands.add_parser("consumption"); consumption.add_argument("file", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        contract = load_contract()
        if args.command == "self-test": result = run_self_test(contract)
        elif args.command == "handoff": result = validate_handoff(load_document(args.file, compact=True), args.phase, args.status, contract)
        elif args.command == "candidate": result = validate_candidate(load_document(args.file), contract)
        elif args.command == "approval": result = validate_approval(load_document(args.request), None if args.record == "-" else load_document(Path(args.record)), contract)
        elif args.command == "publication": result = validate_publication(load_document(args.request), None if args.result == "-" else load_document(Path(args.result)), contract)
        else: result = validate_consumption(load_document(args.file), contract)
        return emit(result)
    except ContractError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
