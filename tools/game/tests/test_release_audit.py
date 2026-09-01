from pathlib import Path
import unittest

from tools.game.release_audit import audit_source


class ReleaseAuditTests(unittest.TestCase):
    def test_repository_source_inventory_is_complete(self) -> None:
        repo_root = Path(__file__).resolve().parents[3]
        errors, summary = audit_source(repo_root, repo_root / "games" / "inkbound_rogue")
        self.assertEqual(errors, [])
        self.assertEqual(summary["assets"], 68)
        self.assertEqual(summary["ai_pre_generated"], 9)
        self.assertEqual(summary["procedural"], 59)
        self.assertEqual(summary["live_ai"], 0)


if __name__ == "__main__":
    unittest.main()
