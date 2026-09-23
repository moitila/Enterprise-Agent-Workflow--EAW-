import json
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOL = ROOT / "tools" / "contract_tool.py"
CONTRACT = ROOT / "contracts" / "contract_v1.json"
PERMANENT_PATHS = [
    "docs/system/repository-topology.md",
    "docs/system/repositories.yaml",
    "docs/system/system-analysis.manifest.json",
    "docs/system/system-analysis.md",
]
CANDIDATE_DIGEST = "67874a0f50baeb0a5004d7c5fd6d78095d577e5720ea7d0d6c03b6496efd46ca"


class ContractToolTests(unittest.TestCase):
    def run_tool(self, *arguments):
        return subprocess.run(
            ["python3", str(TOOL), *map(str, arguments)],
            text=True,
            capture_output=True,
            check=False,
        )

    def write_json(self, directory, name, value):
        path = Path(directory) / name
        path.write_text(json.dumps(value, separators=(",", ":")), encoding="utf-8")
        return path

    def topology(self, entries):
        count = len(entries)
        return {
            "contract_version": 1,
            "entries": entries,
            "scenario": "zero" if count == 0 else "one" if count == 1 else "many",
            "order_invariant": True,
        }

    def entry(self, key, status="active"):
        return {
            "repo_key": key,
            "status": status,
            "locator": {"type": "path", "value": f"/tmp/{key}"},
        }

    def approval_pair(self):
        request = {
            "contract_version": 1,
            "request_id": "approval-1",
            "candidate_identity": "candidate-1",
            "candidate_digest": CANDIDATE_DIGEST,
            "authority": {
                "repo_key": "repo-a",
                "publication_root": "/tmp/repo-a",
                "source": "decision-1",
            },
            "base_revision": "revision-1",
        }
        record = {
            **request,
            "decision": "approved",
            "approver": "reviewer-1",
        }
        return request, record

    def test_contract_file(self):
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.assertEqual(1, contract["contract_version"])
        self.assertEqual("system_analysis", contract["track_id"])
        self.assertEqual(PERMANENT_PATHS, contract["permanent_paths"])
        self.assertEqual(5, len(contract["negative_cases"]))

    def test_self_test(self):
        result = self.run_tool("self-test")
        self.assertEqual(0, result.returncode, result.stderr)
        payload = json.loads(result.stdout)
        self.assertTrue(payload["valid"])
        self.assertEqual(["zero", "one", "many"], payload["topology_scenarios"])

    def test_topology_zero(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_json(directory, "topology.json", self.topology([]))
            result = self.run_tool("topology", path)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("zero", json.loads(result.stdout)["scenario"])

    def test_topology_one(self):
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_json(directory, "topology.json", self.topology([self.entry("a")]))
            result = self.run_tool("topology", path)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual(["a"], json.loads(result.stdout)["repository_keys"])

    def test_topology_many_order_invariant(self):
        entries = [self.entry("a"), self.entry("b", "planned")]
        with tempfile.TemporaryDirectory() as directory:
            first = self.write_json(directory, "ab.json", self.topology(entries))
            second = self.write_json(directory, "ba.json", self.topology(list(reversed(entries))))
            result_ab = self.run_tool("topology", first)
            result_ba = self.run_tool("topology", second)
        self.assertEqual(0, result_ab.returncode, result_ab.stderr)
        self.assertEqual(0, result_ba.returncode, result_ba.stderr)
        self.assertEqual(json.loads(result_ab.stdout), json.loads(result_ba.stdout))

    def test_candidate_changed_after_approval(self):
        request, record = self.approval_pair()
        record["candidate_digest"] = "b" * 64
        with tempfile.TemporaryDirectory() as directory:
            request_path = self.write_json(directory, "request.json", request)
            record_path = self.write_json(directory, "record.json", record)
            result = self.run_tool("approval", request_path, record_path)
        self.assertEqual(1, result.returncode)
        self.assertIn("candidate digest mismatch", result.stderr)

    def test_request_id_mismatch(self):
        request, record = self.approval_pair()
        record["request_id"] = "wrong"
        with tempfile.TemporaryDirectory() as directory:
            request_path = self.write_json(directory, "request.json", request)
            record_path = self.write_json(directory, "record.json", record)
            result = self.run_tool("approval", request_path, record_path)
        self.assertEqual(1, result.returncode)
        self.assertIn("request id mismatch", result.stderr)

    def test_authority_missing_or_multiple(self):
        authority = {"contract_version": 1, "state": "resolved", "binding": []}
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_json(directory, "authority.json", authority)
            result = self.run_tool("authority", path)
        self.assertEqual(1, result.returncode)
        self.assertIn("authority must contain exactly one binding", result.stderr)

    def test_base_revision_mismatch(self):
        request, record = self.approval_pair()
        record["base_revision"] = "wrong"
        with tempfile.TemporaryDirectory() as directory:
            request_path = self.write_json(directory, "request.json", request)
            record_path = self.write_json(directory, "record.json", record)
            result = self.run_tool("approval", request_path, record_path)
        self.assertEqual(1, result.returncode)
        self.assertIn("base revision mismatch", result.stderr)

    def test_unauthorized_destination(self):
        request = {
            "contract_version": 1,
            "request_id": "publication-1",
            "repo_key": "repo-a",
            "base_revision": "revision-1",
            "approved_digest": CANDIDATE_DIGEST,
            "paths": PERMANENT_PATHS,
        }
        result_value = {
            **request,
            "paths": PERMANENT_PATHS + ["docs/system/extra.md"],
            "published_digest": CANDIDATE_DIGEST,
            "revision": "revision-2",
        }
        with tempfile.TemporaryDirectory() as directory:
            request_path = self.write_json(directory, "request.json", request)
            result_path = self.write_json(directory, "result.json", result_value)
            result = self.run_tool("publication", request_path, result_path)
        self.assertEqual(1, result.returncode)
        self.assertIn("unauthorized destination", result.stderr)

    def test_digest_chain_success(self):
        files = {path: str(index) * 64 for index, path in enumerate(PERMANENT_PATHS, 1)}
        candidate = {
            "contract_version": 1,
            "repo_key": "repo-a",
            "base_revision": "revision-1",
            "files": files,
            "candidate_digest": CANDIDATE_DIGEST,
        }
        approval_request, approval_record = self.approval_pair()
        publication_request = {
            "contract_version": 1,
            "request_id": "publication-1",
            "repo_key": "repo-a",
            "base_revision": "revision-1",
            "approved_digest": CANDIDATE_DIGEST,
            "paths": PERMANENT_PATHS,
        }
        publication_result = {
            **publication_request,
            "published_digest": CANDIDATE_DIGEST,
            "revision": "revision-2",
        }
        consumption = {
            "contract_version": 1,
            "candidate_digest": CANDIDATE_DIGEST,
            "approved_digest": CANDIDATE_DIGEST,
            "published_digest": CANDIDATE_DIGEST,
            "consumed_digest": CANDIDATE_DIGEST,
            "repo_key": "repo-a",
            "revision": "revision-2",
            "paths": PERMANENT_PATHS,
        }
        with tempfile.TemporaryDirectory() as directory:
            candidate_path = self.write_json(directory, "candidate.json", candidate)
            approval_request_path = self.write_json(directory, "approval-request.json", approval_request)
            approval_record_path = self.write_json(directory, "approval-record.json", approval_record)
            publication_request_path = self.write_json(
                directory, "publication-request.json", publication_request
            )
            publication_result_path = self.write_json(
                directory, "publication-result.json", publication_result
            )
            consumption_path = self.write_json(directory, "consumption.json", consumption)
            results = [
                self.run_tool("candidate", candidate_path),
                self.run_tool("approval", approval_request_path, approval_record_path),
                self.run_tool("publication", publication_request_path, publication_result_path),
                self.run_tool("consumption", consumption_path),
            ]
        for result in results:
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertTrue(json.loads(result.stdout)["valid"])


if __name__ == "__main__":
    unittest.main()
