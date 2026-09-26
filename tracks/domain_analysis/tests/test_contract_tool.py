import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "contract_tool.py"
CONTRACT = ROOT / "contracts" / "contract_v1.json"


class ContractToolTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        cls.paths = cls.contract["permanent_paths"]

    def run_tool(self, *args):
        return subprocess.run(["python3", str(TOOL), *map(str, args)], text=True,
                              capture_output=True, check=False)

    def write(self, directory, name, value):
        path = Path(directory) / name
        if path.suffix == ".json":
            path.write_text(json.dumps(value, separators=(",", ":")), encoding="utf-8")
        else:
            path.write_text(yaml.safe_dump(value, sort_keys=False), encoding="utf-8")
        return path

    def fixtures(self):
        files = {path: hashlib.sha256(path.encode()).hexdigest() for path in self.paths}
        payload = b"".join(path.encode() + b"\0" + files[path].encode() + b"\n" for path in sorted(files))
        digest = hashlib.sha256(payload).hexdigest()
        candidate = {"contract_version": 1, "repo_key": "authoritative", "base_revision": "a" * 40,
                     "files": files, "candidate_digest": digest}
        approval_request = {**candidate, "request_id": "approval-1", "candidate_identity": "candidate-1"}
        approval_record = {**approval_request, "decision": "approved", "approver": "reviewer-1"}
        publication_request = {"contract_version": 1, "request_id": "publication-1",
                               "repo_key": candidate["repo_key"], "base_revision": candidate["base_revision"],
                               "approved_digest": digest, "files": files}
        publication_result = {**publication_request, "published_digest": digest, "revision": "b" * 40}
        consumption = {"contract_version": 1, "repo_key": candidate["repo_key"], "revision": "b" * 40,
                       "files": files, "candidate_digest": digest, "approved_digest": digest,
                       "published_digest": digest, "consumed_digest": digest}
        return candidate, approval_request, approval_record, publication_request, publication_result, consumption

    def invoke_pair(self, command, left, right):
        with tempfile.TemporaryDirectory() as directory:
            left_path = self.write(directory, "left.json", left)
            right_path = self.write(directory, "right.json", right)
            return self.run_tool(command, left_path, right_path)

    def semantic_files(self, directory, *, narrative=None, concepts=None, capabilities=None, applicable=None):
        if narrative is None:
            narrative = [{"concept_id": "concept.alpha", "type": "entity"}]
        if concepts is None:
            concepts = [{"concept_id": "concept.alpha", "type": "entity", "term": "Alpha",
                         "definition": "Synthetic concept", "source_id": "source.synthetic",
                         "certainty": "confirmed", "canonicalization": {"status": "canonical"}}]
        if capabilities is None:
            capabilities = [{"capability_id": "cap.alpha", "concept_ids": ["concept.alpha"]}]
        markdown = Path(directory) / "model.md"
        markdown.write_text("\n".join(f'<!-- concept: {json.dumps(item, separators=(",", ":"))} -->' for item in narrative), encoding="utf-8")
        glossary = self.write(directory, "glossary.yaml", {"contract_version": 1, "concepts": concepts})
        capability_path = self.write(directory, "capabilities.yaml", {"contract_version": 1, "capabilities": capabilities,
                                                                        "applicable_concept_ids": applicable or ["concept.alpha"]})
        return markdown, glossary, capability_path

    def test_contract_and_self_test(self):
        self.assertEqual("domain_analysis", self.contract["track_id"])
        self.assertEqual(["source_inventory", "approval_gate", "publication"], self.contract["waiting_phases"])
        self.assertEqual(5, len(self.paths))
        self.assertEqual(self.contract["authoritative_consumer_track_ids"],
                         [item["track_id"] for item in self.contract["authoritative_consumers"]])
        self.assertTrue(all(item["authoritative"] and not item["installed"]
                            for item in self.contract["authoritative_consumers"]))
        result = self.run_tool("self-test")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertTrue(json.loads(result.stdout)["valid"])

    def test_complete_chain(self):
        candidate, request, record, pub_request, pub_result, consumption = self.fixtures()
        with tempfile.TemporaryDirectory() as directory:
            values = [("candidate", candidate), ("request", request), ("record", record),
                      ("pub_request", pub_request), ("pub_result", pub_result), ("consumption", consumption)]
            paths = {name: self.write(directory, f"{name}.json", value) for name, value in values}
            results = [self.run_tool("candidate", paths["candidate"]),
                       self.run_tool("approval", paths["request"], paths["record"]),
                       self.run_tool("publication", paths["pub_request"], paths["pub_result"]),
                       self.run_tool("consumption", paths["consumption"])]
        for result in results:
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertTrue(json.loads(result.stdout)["valid"])

    def test_semantic_parity_and_candidate_preservation(self):
        candidate, *_ = self.fixtures()
        with tempfile.TemporaryDirectory() as directory:
            semantic = self.semantic_files(directory)
            result = self.run_tool("semantic", *semantic)
            self.assertEqual(0, result.returncode, result.stderr)
            payload = json.loads(result.stdout)
            self.assertTrue(payload["valid"])
            candidate_path = self.write(directory, "candidate.json", candidate)
            result = self.run_tool("candidate", candidate_path, *semantic)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertTrue(json.loads(result.stdout)["semantic_validation"]["valid"])

    def test_semantic_rejections_are_structured(self):
        base = {"concept_id": "concept.alpha", "type": "entity", "term": "Alpha",
                "definition": "Synthetic", "source_id": "source.synthetic", "certainty": "confirmed",
                "canonicalization": {"status": "canonical"}}
        cases = [
            ([{"concept_id": "concept.missing", "type": "entity"}], [base], None, "narrative_without_glossary"),
            ([], [base], None, "orphan_glossary_concept"),
            ([{"concept_id": "concept.alpha", "type": "entity"}] * 2, [base], None, "duplicate_concept_id"),
            ([{"concept_id": "concept.alpha", "type": "value_object"}], [base], None, "concept_type_mismatch"),
            ([{"concept_id": "concept.alpha", "type": "entity"}], [{**base, "canonicalization": {"status": "hypothesis"}}], None, "missing_justification"),
            ([{"concept_id": "concept.alpha", "type": "entity"}], [base], [{"capability_id": "cap", "concept_ids": ["concept.unknown"]}], "unknown_capability_concept"),
            ([{"concept_id": "concept.alpha", "type": "entity"}], [base], [{"capability_id": "cap", "concept_ids": []}], "missing_applicable_coverage"),
        ]
        for narrative, concepts, capabilities, code in cases:
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                paths = self.semantic_files(directory, narrative=narrative, concepts=concepts,
                                            capabilities=capabilities, applicable=["concept.alpha"])
                result = self.run_tool("semantic", *paths)
                self.assertEqual(1, result.returncode, result.stderr)
                payload = json.loads(result.stdout)
                self.assertFalse(payload["valid"])
                self.assertIn(code, {item["code"] for item in payload["errors"]})

    def test_coverage_valid_snapshot_and_negative_cases(self):
        candidate = {"candidate_id": "candidate.alpha", "observed_term": "Alpha", "candidate_category": "concept",
                     "source_id": "source.synthetic", "locator": "section 1", "evidence": "Alpha appears",
                     "qualification": "observed", "upstream_status": "CONFIRMED"}
        disposition = {"candidate_id": "candidate.alpha", "disposition": "CANONICAL", "canonical_concept_id": "concept.alpha", "upstream_status": "CONFIRMED"}
        with tempfile.TemporaryDirectory() as directory:
            semantic = self.semantic_files(directory)
            ledger = self.write(directory, "ledger.yaml", {"candidates": [candidate]})
            dispositions = self.write(directory, "dispositions.yaml", {"dispositions": [disposition]})
            snapshot = self.write(directory, "snapshot.yaml", {"contract_version": 1, "candidates": [candidate], "dispositions": [disposition]})
            args = ["coverage", ledger, dispositions, semantic[0], semantic[1]]
            result = self.run_tool(*args, "--snapshot", snapshot)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertTrue(json.loads(result.stdout)["valid"])

        cases = [
            ([candidate], [], "candidate_without_disposition"),
            ([candidate], [{**disposition, "canonical_concept_id": "missing"}], "canonical_missing_from_model_or_glossary"),
            ([candidate], [{"candidate_id": "candidate.alpha", "disposition": "DEFERRED", "rationale": "Later", "upstream_status": "CONFIRMED"}], "missing_deferred_destination"),
            ([candidate], [{"candidate_id": "candidate.alpha", "disposition": "NON_CANONICAL", "upstream_status": "CONFIRMED"}], "missing_disposition_rationale"),
            ([{**candidate, "upstream_status": "PROPOSED"}], [disposition], "upstream_status_promoted"),
            ([candidate, candidate], [disposition], "duplicate_candidate_id"),
            ([candidate], [{**disposition, "disposition": "UNKNOWN"}], "invalid_disposition"),
        ]
        for candidates, disposition_values, code in cases:
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                semantic = self.semantic_files(directory)
                ledger = self.write(directory, "ledger.yaml", {"candidates": candidates})
                dispositions = self.write(directory, "dispositions.yaml", {"dispositions": disposition_values})
                result = self.run_tool("coverage", ledger, dispositions, semantic[0], semantic[1])
                self.assertEqual(1, result.returncode, result.stderr)
                self.assertIn(code, {item["code"] for item in json.loads(result.stdout)["errors"]})

    def test_manifest_future_permission_and_installed_state_are_separate(self):
        with tempfile.TemporaryDirectory() as directory:
            manifest = self.write(directory, "manifest.yaml", {"authoritative_consumers": [
                {"track_id": track_id, "authoritative": True}
                for track_id in self.contract["authoritative_consumer_track_ids"]],
                "informational_categories": [{"category_id": "reporting", "authoritative": False}]})
            registry = self.write(directory, "registry.yaml", {"tracks": [{"track_id": "domain_analysis", "status": "installed"}]})
            result = self.run_tool("manifest", manifest, registry)
        self.assertEqual(0, result.returncode, result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["valid"])
        self.assertTrue(all(item["contractually_allowed"] and not item["installed"] for item in payload["consumer_installation"]))

    def test_manifest_rejects_free_ids_and_category_routing(self):
        cases = [
            ({"authoritative_consumers": [{"track_id": "free_name", "authoritative": True}], "informational_categories": []}, "consumer_not_allowed"),
            ({"authoritative_consumers": [{"track_id": "business_rules_analysis", "authoritative": False}], "informational_categories": []}, "consumer_not_authoritative"),
            ({"authoritative_consumers": [], "informational_categories": [{"category_id": "reporting"}]}, "category_not_informational"),
            ({"authoritative_consumers": [], "informational_categories": [{"category_id": "reporting", "authoritative": False, "route": "free"}]}, "category_routing_forbidden"),
        ]
        for manifest_value, code in cases:
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                manifest = self.write(directory, "manifest.yaml", manifest_value)
                registry = self.write(directory, "registry.yaml", {"tracks": []})
                result = self.run_tool("manifest", manifest, registry)
                self.assertEqual(1, result.returncode, result.stderr)
                payload = json.loads(result.stdout)
                self.assertFalse(payload["valid"])
                self.assertIn(code, {item["code"] for item in payload["errors"]})

    def test_yaml_candidate_uses_parser(self):
        candidate, *_ = self.fixtures()
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_tool("candidate", self.write(directory, "candidate.yaml", candidate))
        self.assertEqual(0, result.returncode, result.stderr)

    def test_permanent_locator_does_not_require_consumption_provenance(self):
        candidate, *_ = self.fixtures()
        self.assertNotIn("consumption_provenance", candidate)
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_tool("candidate", self.write(directory, "candidate.json", candidate))
        self.assertEqual(0, result.returncode, result.stderr)

    def test_candidate_changed_after_approval(self):
        _, request, record, *_ = self.fixtures()
        result = self.invoke_pair("approval", request, {**record, "candidate_digest": "0" * 64})
        self.assertEqual(1, result.returncode)
        self.assertIn("candidate digest mismatch", result.stderr)

    def test_request_mismatch(self):
        _, request, record, *_ = self.fixtures()
        result = self.invoke_pair("approval", request, {**record, "request_id": "wrong"})
        self.assertEqual(1, result.returncode)
        self.assertIn("request id mismatch", result.stderr)

    def test_revision_mismatch(self):
        _, request, record, *_ = self.fixtures()
        result = self.invoke_pair("approval", request, {**record, "base_revision": "c" * 40})
        self.assertEqual(1, result.returncode)
        self.assertIn("base revision mismatch", result.stderr)

    def test_mutable_or_missing_revision(self):
        candidate, *_ = self.fixtures()
        for revision in ("HEAD", "main", "refs/heads/release", ""):
            with self.subTest(revision=revision), tempfile.TemporaryDirectory() as directory:
                result = self.run_tool("candidate", self.write(directory, "candidate.json", {**candidate, "base_revision": revision}))
                self.assertEqual(1, result.returncode)

    def test_extra_destination_and_manifest_mismatch(self):
        candidate, *_ = self.fixtures()
        cases = ({**candidate, "files": {**candidate["files"], "docs/domain/extra.md": "0" * 64}},
                 {**candidate, "files": dict(list(candidate["files"].items())[:-1])})
        for value in cases:
            with tempfile.TemporaryDirectory() as directory:
                result = self.run_tool("candidate", self.write(directory, "candidate.json", value))
            self.assertEqual(1, result.returncode)
            self.assertIn("destinations mismatch", result.stderr)

    def test_digest_and_hash_mismatch(self):
        candidate, *_ = self.fixtures()
        cases = ({**candidate, "candidate_digest": "0" * 64},
                 {**candidate, "files": {**candidate["files"], self.paths[0]: "INVALID"}})
        for value in cases:
            with tempfile.TemporaryDirectory() as directory:
                result = self.run_tool("candidate", self.write(directory, "candidate.json", value))
            self.assertEqual(1, result.returncode)

    def test_publication_rejects_divergent_result(self):
        *_, request, result, _ = self.fixtures()
        for changed in ({**result, "request_id": "wrong"}, {**result, "published_digest": "0" * 64},
                        {**result, "files": {**result["files"], self.paths[0]: "0" * 64}}):
            observed = self.invoke_pair("publication", request, changed)
            self.assertEqual(1, observed.returncode)

    def test_consumption_rejects_digest_chain(self):
        *_, receipt = self.fixtures()
        with tempfile.TemporaryDirectory() as directory:
            result = self.run_tool("consumption", self.write(directory, "receipt.json", {**receipt, "consumed_digest": "0" * 64}))
        self.assertEqual(1, result.returncode)
        self.assertIn("digest chain mismatch", result.stderr)

    def test_handoff_completed_and_waiting(self):
        cases = (("candidate_freeze", "completed", {"from_phase": "candidate_freeze", "status": "completed", "messages": [], "codes": []}),
                 ("approval_gate", "waiting", {"from_phase": "approval_gate", "status": "waiting", "blocker": "record absent", "messages": [], "codes": ["WAITING"]}))
        for phase, status, value in cases:
            with tempfile.TemporaryDirectory() as directory:
                result = self.run_tool("handoff", self.write(directory, "handoff.json", value), phase, status)
            self.assertEqual(0, result.returncode, result.stderr)

    def test_handoff_rejects_invalid_or_noncompact(self):
        with tempfile.TemporaryDirectory() as directory:
            invalid = self.write(directory, "invalid.json", {"from_phase": "approval_gate"})
            result = self.run_tool("handoff", invalid, "approval_gate", "completed")
            self.assertEqual(1, result.returncode)
            pretty = Path(directory) / "pretty.json"
            pretty.write_text(json.dumps({"from_phase": "approval_gate", "status": "completed", "messages": [], "codes": []}, indent=2), encoding="utf-8")
            result = self.run_tool("handoff", pretty, "approval_gate", "completed")
            self.assertEqual(1, result.returncode)
            self.assertIn("compact", result.stderr)


if __name__ == "__main__":
    unittest.main()
