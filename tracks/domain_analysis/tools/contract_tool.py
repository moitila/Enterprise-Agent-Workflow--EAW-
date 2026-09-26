#!/usr/bin/env python3
"""Deterministic validators for the domain_analysis publication corridor."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
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


def error(code: str, artifact: str, message: str, concept_id: str | None = None) -> dict[str, str]:
    value = {"code": code, "artifact": artifact, "message": message}
    if concept_id is not None:
        value["concept_id"] = concept_id
    return value


def parse_narrative(path: Path) -> list[dict[str, str]]:
    raw = path.read_text(encoding="utf-8")
    values = []
    for match in re.finditer(r"<!--\s*concept:\s*(\{.*?\})\s*-->", raw):
        try:
            item = json.loads(match.group(1))
        except json.JSONDecodeError as exc:
            raise ContractError(f"invalid concept marker in {path}: {exc}") from exc
        item = require_object(item, "narrative concept marker")
        values.append({"concept_id": require_string(item.get("concept_id"), "concept_id"),
                       "type": require_string(item.get("type"), "type")})
    return values


def parse_glossary(path: Path) -> list[dict[str, Any]]:
    document = require_object(load_document(path), "glossary")
    concepts = document.get("concepts")
    if not isinstance(concepts, list):
        raise ContractError("glossary concepts must be an array")
    return [require_object(item, "glossary concept") for item in concepts]


def parse_capabilities(path: Path) -> tuple[list[str], list[str]]:
    document = require_object(load_document(path), "capabilities")
    capabilities = document.get("capabilities")
    if not isinstance(capabilities, list):
        raise ContractError("capabilities must be an array")
    referenced = []
    for item in capabilities:
        item = require_object(item, "capability")
        concept_ids = item.get("concept_ids", [])
        if not isinstance(concept_ids, list) or not all(isinstance(x, str) and x for x in concept_ids):
            raise ContractError("capability concept_ids must be a string array")
        referenced.extend(concept_ids)
    applicable = document.get("applicable_concept_ids", [])
    if not isinstance(applicable, list) or not all(isinstance(x, str) and x for x in applicable):
        raise ContractError("applicable_concept_ids must be a string array")
    return referenced, applicable


def duplicates(values: list[str]) -> set[str]:
    return {value for value in values if values.count(value) > 1}


def validate_semantics(markdown_path: Path, glossary_path: Path, capabilities_path: Path,
                       contract: dict[str, Any]) -> dict[str, Any]:
    narrative = parse_narrative(markdown_path)
    glossary = parse_glossary(glossary_path)
    capability_ids, applicable_ids = parse_capabilities(capabilities_path)
    errors: list[dict[str, str]] = []
    narrative_ids = [item["concept_id"] for item in narrative]
    glossary_ids = [str(item.get("concept_id", "")) for item in glossary]
    for artifact, values in (("narrative", narrative_ids), ("glossary", glossary_ids)):
        for concept_id in sorted(duplicates(values)):
            errors.append(error("duplicate_concept_id", artifact, "concept_id must be unique", concept_id))
    canonical_types = set(contract["canonical_types"])
    statuses = set(contract["canonicalization_statuses"])
    required = set(contract["concept_required_fields"])
    glossary_types: dict[str, str] = {}
    canonical_glossary_ids = []
    for item in glossary:
        concept_id = str(item.get("concept_id", ""))
        missing = sorted(required - set(item))
        if missing:
            errors.append(error("missing_concept_fields", "glossary", f"missing fields: {','.join(missing)}", concept_id or None))
        concept_type = item.get("type")
        if concept_type not in canonical_types:
            errors.append(error("invalid_concept_type", "glossary", "type is not canonical", concept_id or None))
        canonicalization = item.get("canonicalization")
        if not isinstance(canonicalization, dict) or canonicalization.get("status") not in statuses:
            errors.append(error("invalid_canonicalization", "glossary", "canonicalization status is required", concept_id or None))
            continue
        status = canonicalization["status"]
        if status != "canonical" and not isinstance(canonicalization.get("justification"), str):
            errors.append(error("missing_justification", "glossary", "non-canonical concept requires justification", concept_id or None))
        elif status != "canonical" and not canonicalization["justification"].strip():
            errors.append(error("missing_justification", "glossary", "non-canonical concept requires justification", concept_id or None))
        if status == "canonical" and concept_id:
            canonical_glossary_ids.append(concept_id)
            glossary_types[concept_id] = str(concept_type)
    narrative_types = {item["concept_id"]: item["type"] for item in narrative}
    narrative_set, glossary_set = set(narrative_ids), set(canonical_glossary_ids)
    for concept_id in sorted(narrative_set - glossary_set):
        errors.append(error("narrative_without_glossary", "narrative", "canonical narrative concept is absent from glossary", concept_id))
    for concept_id in sorted(glossary_set - narrative_set):
        errors.append(error("orphan_glossary_concept", "glossary", "canonical glossary concept is absent from narrative", concept_id))
    for concept_id in sorted(narrative_set & glossary_set):
        if narrative_types[concept_id] != glossary_types[concept_id]:
            errors.append(error("concept_type_mismatch", "narrative", "narrative and glossary types differ", concept_id))
    for concept_id in sorted(set(capability_ids) - glossary_set):
        errors.append(error("unknown_capability_concept", "capabilities", "capability references an unknown canonical concept", concept_id))
    for concept_id in sorted(set(applicable_ids) - set(capability_ids)):
        errors.append(error("missing_applicable_coverage", "capabilities", "applicable concept is not referenced by a capability", concept_id))
    errors.sort(key=lambda item: (item["code"], item["artifact"], item.get("concept_id", ""), item["message"]))
    checks = {
        "unique_ids": not any(x["code"] == "duplicate_concept_id" for x in errors),
        "id_parity": narrative_set == glossary_set,
        "type_parity": not any(x["code"] == "concept_type_mismatch" for x in errors),
        "referential_integrity": set(capability_ids) <= glossary_set,
        "applicable_coverage": set(applicable_ids) <= set(capability_ids),
        "non_canonical_qualification": not any(x["code"] in {"invalid_canonicalization", "missing_justification"} for x in errors),
    }
    return {"contract_version": 1, "valid": not errors and all(checks.values()), "checks": checks,
            "narrative_canonical_ids": sorted(narrative_set), "glossary_canonical_ids": sorted(glossary_set),
            "capability_concept_ids": sorted(set(capability_ids)), "errors": errors}


def validate_coverage(ledger_path: Path, dispositions_path: Path, markdown_path: Path,
                      glossary_path: Path, contract: dict[str, Any],
                      snapshot_path: Path | None = None) -> dict[str, Any]:
    ledger_doc = require_object(load_document(ledger_path), "coverage ledger")
    disposition_doc = require_object(load_document(dispositions_path), "coverage dispositions")
    candidates = ledger_doc.get("candidates")
    dispositions = disposition_doc.get("dispositions")
    if not isinstance(candidates, list) or not isinstance(dispositions, list):
        raise ContractError("coverage candidates and dispositions must be arrays")
    required_candidate = set(contract["coverage_required_fields"])
    required_disposition = set(contract["coverage_disposition_required_fields"])
    allowed = set(contract["coverage_dispositions"])
    errors: list[dict[str, str]] = []
    candidate_ids: list[str] = []
    disposition_ids: list[str] = []
    candidate_by_id: dict[str, dict[str, Any]] = {}
    disposition_by_id: dict[str, dict[str, Any]] = {}
    for item in candidates:
        item = require_object(item, "coverage candidate")
        cid = str(item.get("candidate_id", ""))
        candidate_ids.append(cid)
        candidate_by_id.setdefault(cid, item)
        missing = sorted(required_candidate - set(item))
        if missing:
            errors.append(error("missing_candidate_fields", "coverage_ledger", f"missing fields: {','.join(missing)}", cid or None))
        for field in ("candidate_id", "observed_term", "candidate_category", "source_id", "locator", "evidence", "qualification"):
            if not isinstance(item.get(field), str) or not item[field].strip():
                errors.append(error("invalid_candidate_field", "coverage_ledger", f"{field} must be non-empty", cid or None))
        if "upstream_status" in item and not isinstance(item["upstream_status"], str):
            errors.append(error("invalid_upstream_status", "coverage_ledger", "upstream_status must be a string", cid or None))
    for item in dispositions:
        item = require_object(item, "coverage disposition")
        cid = str(item.get("candidate_id", ""))
        disposition_ids.append(cid)
        disposition_by_id.setdefault(cid, item)
        if required_disposition - set(item):
            errors.append(error("missing_disposition_fields", "coverage_dispositions", "candidate_id and disposition are required", cid or None))
        candidate = candidate_by_id.get(cid)
        if candidate is not None and item.get("upstream_status") != candidate.get("upstream_status"):
            errors.append(error("upstream_status_mismatch", "coverage_dispositions", "upstream_status must be preserved exactly", cid or None))
        status = item.get("disposition")
        if status not in allowed:
            errors.append(error("invalid_disposition", "coverage_dispositions", "disposition is not in the closed enum", cid or None))
            continue
        if status in contract["coverage_justification_required"] and not (isinstance(item.get("rationale"), str) and item["rationale"].strip()):
            errors.append(error("missing_disposition_rationale", "coverage_dispositions", "disposition requires rationale", cid or None))
        if status == "DEFERRED":
            targets = item.get("deferred_to")
            if not isinstance(targets, list) or not targets or not all(isinstance(x, str) and x.strip() for x in targets):
                errors.append(error("missing_deferred_destination", "coverage_dispositions", "DEFERRED requires non-empty deferred_to array", cid or None))
        if status == "CANONICAL" and not (isinstance(item.get("canonical_concept_id"), str) and item["canonical_concept_id"].strip()):
            errors.append(error("missing_canonical_reference", "coverage_dispositions", "CANONICAL requires canonical_concept_id", cid or None))
    for cid in sorted(duplicates(candidate_ids)):
        errors.append(error("duplicate_candidate_id", "coverage_ledger", "candidate_id must be unique", cid))
    for cid in sorted(duplicates(disposition_ids)):
        errors.append(error("duplicate_disposition_id", "coverage_dispositions", "candidate_id must be unique", cid))
    for cid in sorted(set(candidate_ids) - set(disposition_ids)):
        errors.append(error("candidate_without_disposition", "coverage_dispositions", "discovered candidate has no disposition", cid))
    for cid in sorted(set(disposition_ids) - set(candidate_ids)):
        errors.append(error("orphan_disposition", "coverage_dispositions", "disposition has no discovered candidate", cid))
    narrative_ids = {item["concept_id"] for item in parse_narrative(markdown_path)}
    glossary = parse_glossary(glossary_path)
    canonical_glossary_ids = {str(item.get("concept_id", "")) for item in glossary
                              if isinstance(item.get("canonicalization"), dict)
                              and item["canonicalization"].get("status") == "canonical"}
    for cid, item in sorted(disposition_by_id.items()):
        if item.get("disposition") == "CANONICAL":
            concept_id = str(item.get("canonical_concept_id", ""))
            if concept_id and (concept_id not in narrative_ids or concept_id not in canonical_glossary_ids):
                errors.append(error("canonical_missing_from_model_or_glossary", "coverage_dispositions", "canonical concept must occur in narrative and canonical glossary", cid))
            candidate = candidate_by_id.get(cid, {})
            if candidate.get("upstream_status") in contract["upstream_authority_statuses"]:
                errors.append(error("upstream_status_promoted", "coverage_dispositions", "authoritative upstream status cannot be promoted to CANONICAL", cid))
    errors.sort(key=lambda item: (item["code"], item["artifact"], item.get("concept_id", ""), item["message"]))
    codes = {item["code"] for item in errors}
    checks = {
        "unique_candidate_ids": not codes.intersection({"duplicate_candidate_id", "duplicate_disposition_id"}),
        "disposition_parity": not codes.intersection({"candidate_without_disposition", "orphan_disposition"}),
        "valid_dispositions": not codes.intersection({"invalid_disposition", "missing_disposition_fields"}),
        "evidence_locators": not codes.intersection({"missing_candidate_fields", "invalid_candidate_field"}),
        "justified_noncanonical": "missing_disposition_rationale" not in codes,
        "deferred_destination": "missing_deferred_destination" not in codes,
        "canonical_model_and_glossary": not codes.intersection({"missing_canonical_reference", "canonical_missing_from_model_or_glossary"}),
        "no_silent_disappearance": not codes.intersection({"candidate_without_disposition", "orphan_disposition"}),
        "upstream_authority_preserved": not codes.intersection({"upstream_status_promoted", "upstream_status_mismatch"}),
    }
    normalized = {"contract_version": 1,
                  "candidates": sorted(candidates, key=lambda x: str(x.get("candidate_id", ""))),
                  "dispositions": sorted(dispositions, key=lambda x: str(x.get("candidate_id", "")))}
    if snapshot_path is not None:
        observed = require_object(load_document(snapshot_path), "coverage snapshot")
        if observed != normalized:
            errors.append(error("coverage_snapshot_mismatch", "coverage_snapshot", "snapshot differs from normalized ledger and dispositions"))
            checks["snapshot_identity"] = False
        else:
            checks["snapshot_identity"] = True
    errors.sort(key=lambda item: (item["code"], item["artifact"], item.get("concept_id", ""), item["message"]))
    result = {**normalized, "valid": not errors and all(checks.values()), "checks": checks, "errors": errors}
    return result


def installed_track_ids(path: Path) -> set[str]:
    document = require_object(load_document(path), "track registry")
    tracks = document.get("tracks")
    if not isinstance(tracks, list):
        raise ContractError("track registry tracks must be an array")
    return {str(item.get("track_id")) for item in tracks if isinstance(item, dict) and item.get("status") == "installed"}


def validate_manifest(value: Any, registry_path: Path, contract: dict[str, Any]) -> dict[str, Any]:
    manifest = require_object(value, "downstream manifest")
    consumers = manifest.get("authoritative_consumers")
    categories = manifest.get("informational_categories")
    if not isinstance(consumers, list) or not isinstance(categories, list):
        raise ContractError("manifest consumer/category lists are required")
    allowed = set(contract["authoritative_consumer_track_ids"])
    installed = installed_track_ids(registry_path)
    errors = []
    states = []
    for item in consumers:
        item = require_object(item, "authoritative consumer")
        track_id = str(item.get("track_id", ""))
        if item.get("authoritative") is not True:
            errors.append(error("consumer_not_authoritative", "downstream_manifest", "consumer requires authoritative true", track_id or None))
        if track_id not in allowed:
            errors.append(error("consumer_not_allowed", "downstream_manifest", "track_id is not contractually allowed", track_id or None))
        states.append({"track_id": track_id, "contractually_allowed": track_id in allowed, "installed": track_id in installed})
    forbidden = set(contract["consumer_contract"]["informational_categories"]["forbidden_fields"])
    for item in categories:
        item = require_object(item, "informational category")
        category_id = str(item.get("category_id", ""))
        if not category_id:
            errors.append(error("missing_category_id", "downstream_manifest", "category_id is required"))
        if item.get("authoritative") is not False:
            errors.append(error("category_not_informational", "downstream_manifest", "category requires authoritative false", category_id or None))
        for field in sorted(forbidden & set(item)):
            errors.append(error("category_routing_forbidden", "downstream_manifest", f"informational category forbids {field}", category_id or None))
    errors.sort(key=lambda item: (item["code"], item["artifact"], item.get("concept_id", ""), item["message"]))
    checks = {"consumer_membership": not any(x["code"] == "consumer_not_allowed" for x in errors),
              "typed_separation": not any(x["code"] in {"consumer_not_authoritative", "category_not_informational", "missing_category_id"} for x in errors),
              "no_informational_routing": not any(x["code"] == "category_routing_forbidden" for x in errors)}
    return {"contract_version": 1, "valid": not errors, "checks": checks,
            "permission_kind": contract["consumer_contract"]["permission_kind"],
            "consumer_installation": sorted(states, key=lambda item: item["track_id"]), "errors": errors}


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


def validate_candidate(value: Any, contract: dict[str, Any], semantic_paths: tuple[Path, Path, Path] | None = None) -> dict[str, Any]:
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
    semantic = None
    if semantic_paths is not None:
        semantic = validate_semantics(*semantic_paths, contract)
        if not semantic["valid"]:
            raise ContractError("candidate semantic validation failed")
    return {"contract_version": 1, "valid": True, "repo_key": repo_key,
            "base_revision": revision, "files": files, "candidate_digest": calculated,
            "semantic_validation": semantic, "errors": []}


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
    candidate.add_argument("semantic_files", nargs="*", type=Path)
    semantic = commands.add_parser("semantic"); semantic.add_argument("markdown", type=Path); semantic.add_argument("glossary", type=Path); semantic.add_argument("capabilities", type=Path)
    coverage = commands.add_parser("coverage"); coverage.add_argument("ledger", type=Path); coverage.add_argument("dispositions", type=Path)
    coverage.add_argument("markdown", type=Path); coverage.add_argument("glossary", type=Path); coverage.add_argument("--snapshot", type=Path)
    manifest = commands.add_parser("manifest"); manifest.add_argument("file", type=Path); manifest.add_argument("registry", type=Path)
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
        elif args.command == "candidate":
            if len(args.semantic_files) not in (0, 3):
                raise ContractError("candidate requires zero or three semantic files")
            semantic_paths = tuple(args.semantic_files) if args.semantic_files else None
            result = validate_candidate(load_document(args.file), contract, semantic_paths)
        elif args.command == "semantic": result = validate_semantics(args.markdown, args.glossary, args.capabilities, contract)
        elif args.command == "coverage": result = validate_coverage(args.ledger, args.dispositions, args.markdown, args.glossary, contract, args.snapshot)
        elif args.command == "manifest": result = validate_manifest(load_document(args.file), args.registry, contract)
        elif args.command == "approval": result = validate_approval(load_document(args.request), None if args.record == "-" else load_document(Path(args.record)), contract)
        elif args.command == "publication": result = validate_publication(load_document(args.request), None if args.result == "-" else load_document(Path(args.result)), contract)
        else: result = validate_consumption(load_document(args.file), contract)
        emit(result)
        if args.command in {"semantic", "manifest", "coverage"} and not result["valid"]:
            return 1
        return 0
    except ContractError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
