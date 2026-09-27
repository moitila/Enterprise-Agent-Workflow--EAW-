import json
import subprocess
import tempfile
import unittest
from pathlib import Path


TOOL = Path(__file__).resolve().parents[1] / "tools" / "analysis_quality.py"


class AnalysisQualityTests(unittest.TestCase):
    def run_check(self, ledger, dispositions):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            left, right = root / "ledger.json", root / "dispositions.json"
            left.write_text(json.dumps(ledger), encoding="utf-8")
            right.write_text(json.dumps(dispositions), encoding="utf-8")
            return subprocess.run(["python3", str(TOOL), "coverage", str(left), str(right)],
                                  text=True, capture_output=True, check=False)

    def test_complete_coverage(self):
        result = self.run_check({"candidates": [{"candidate_id": "x"}]},
                                {"dispositions": [{"candidate_id": "x", "disposition": "TBD"}]})
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertTrue(json.loads(result.stdout)["valid"])

    def test_missing_disposition_is_detected(self):
        result = self.run_check({"candidates": [{"candidate_id": "x"}]}, {"dispositions": []})
        self.assertEqual(1, result.returncode)
        self.assertFalse(json.loads(result.stdout)["valid"])


if __name__ == "__main__":
    unittest.main()
