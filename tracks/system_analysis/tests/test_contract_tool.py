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

    def run_handoff(self, value, phase="system_baseline", status="completed"):
        with tempfile.TemporaryDirectory() as directory:
            path = self.write_json(directory, "handoff.json", value)
            return self.run_tool("handoff", path, phase, status)

    def handoff(self, **fields):
        return {
            "from_phase": "system_baseline",
            "status": "completed",
            "messages": [],
            "codes": [],
            **fields,
        }

    def test_handoff_accepts_core_and_runtime_provenance(self):
        metadata_cases = (
            {},
            {"code_origin": "emitted"},
            {"code_origin": "inherited"},
            {"code_origin": "inherited", "inherited_from": "source_inventory"},
        )
        for metadata in metadata_cases:
            with self.subTest(metadata=metadata):
                handoff = self.handoff(**metadata)
                result = self.run_handoff(handoff)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(handoff, json.loads(result.stdout))

    def test_handoff_rejects_missing_or_unknown_keys(self):
        for key in ("from_phase", "status", "messages", "codes"):
            with self.subTest(missing=key):
                handoff = self.handoff()
                del handoff[key]
                result = self.run_handoff(handoff)
                self.assertEqual(1, result.returncode)
                self.assertIn("handoff keys mismatch", result.stderr)
        result = self.run_handoff(self.handoff(unknown="value"))
        self.assertEqual(1, result.returncode)
        self.assertIn("handoff keys mismatch", result.stderr)

    def test_handoff_rejects_invalid_provenance(self):
        non_empty_error = "inherited_from must be a non-empty string"
        inheritance_error = "handoff inheritance requires inherited code origin"
        invalid_cases = (
            ({"code_origin": "other"}, "handoff code origin is invalid"),
            ({"code_origin": ""}, "handoff code origin is invalid"),
            ({"code_origin": None}, "handoff code origin is invalid"),
            ({"code_origin": []}, "handoff code origin is invalid"),
            ({"code_origin": "inherited", "inherited_from": ""}, non_empty_error),
            ({"code_origin": "inherited", "inherited_from": "  "}, non_empty_error),
            ({"code_origin": "inherited", "inherited_from": None}, non_empty_error),
            ({"code_origin": "inherited", "inherited_from": 7}, non_empty_error),
            ({"code_origin": "emitted", "inherited_from": "source_inventory"}, inheritance_error),
            ({"inherited_from": "source_inventory"}, inheritance_error),
        )
        for metadata, expected_error in invalid_cases:
            with self.subTest(metadata=metadata):
                result = self.run_handoff(self.handoff(**metadata))
                self.assertEqual(1, result.returncode)
                self.assertIn(expected_error, result.stderr)

    def test_handoff_preserves_core_validation(self):
        invalid_cases = (
            (self.handoff(from_phase="source_inventory"), "handoff phase mismatch"),
            (self.handoff(status="skipped", code_origin="inherited"), "handoff status mismatch"),
            (
                self.handoff(messages=[{"text": "not a string"}]),
                "handoff messages must be a string array",
            ),
            (self.handoff(codes=["WAITING"]), "completed handoff codes must be empty"),
        )
        for handoff, expected_error in invalid_cases:
            with self.subTest(handoff=handoff):
                result = self.run_handoff(handoff)
                self.assertEqual(1, result.returncode)
                self.assertIn(expected_error, result.stderr)

    def test_waiting_handoff_accepts_all_waiting_phases(self):
        for phase in ("authority_resolution", "approval_gate", "publication"):
            with self.subTest(phase=phase):
                handoff = {
                    "from_phase": phase,
                    "status": "waiting",
                    "blocker": f"Aguardando resultado externo para {phase}",
                    "messages": [],
                    "codes": ["WAITING"],
                }
                result = self.run_handoff(handoff, phase, "waiting")
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(handoff, json.loads(result.stdout))

    def test_waiting_handoff_rejects_missing_or_invalid_blocker(self):
        handoff = self.handoff(
            from_phase="authority_resolution",
            status="waiting",
            blocker="Aguardando bootstrap",
            codes=["WAITING"],
        )
        for blocker in (None, "", "  ", 42, []):
            with self.subTest(blocker=blocker):
                invalid = {**handoff, "blocker": blocker}
                if blocker is None:
                    del invalid["blocker"]
                result = self.run_handoff(invalid, "authority_resolution", "waiting")
                self.assertEqual(1, result.returncode)
                self.assertIn(
                    "handoff keys mismatch" if blocker is None else "blocker must be a non-empty string",
                    result.stderr,
                )

    def test_waiting_handoff_preserves_messages_codes_and_phase_rules(self):
        handoff = self.handoff(
            from_phase="authority_resolution",
            status="waiting",
            blocker="Aguardando bootstrap",
            codes=["WAITING"],
        )
        cases = (
            ({"messages": ["request_id=1"]}, "waiting handoff messages must be empty", "authority_resolution"),
            ({"codes": []}, "waiting handoff code mismatch", "authority_resolution"),
            ({"codes": ["WAITING", "OTHER"]}, "waiting handoff code mismatch", "authority_resolution"),
            ({"from_phase": "system_baseline"}, "phase cannot wait", "system_baseline"),
        )
        for fields, expected_error, phase in cases:
            with self.subTest(fields=fields):
                result = self.run_handoff({**handoff, **fields}, phase, "waiting")
                self.assertEqual(1, result.returncode)
                self.assertIn(expected_error, result.stderr)

    def test_contract_file(self):
        contract = json.loads(CONTRACT.read_text(encoding="utf-8"))
        self.assertEqual(1, contract["contract_version"])
        self.assertEqual("system_analysis", contract["track_id"])
        self.assertEqual(PERMANENT_PATHS, contract["permanent_paths"])
        self.assertEqual(5, len(contract["negative_cases"]))
        self.assertEqual(["blocker"], contract["waiting_required_fields"])

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
