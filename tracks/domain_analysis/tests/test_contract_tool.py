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

    def test_contract_and_self_test(self):
        self.assertEqual("domain_analysis", self.contract["track_id"])
        self.assertEqual(["source_inventory", "approval_gate", "publication"], self.contract["waiting_phases"])
        self.assertEqual(4, len(self.paths))
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
