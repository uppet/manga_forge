import json
import tempfile
import unittest
from pathlib import Path

from tools.game.release_audit import (
    _windows_numeric_version,
    audit_depot,
    audit_itch_bundle,
    audit_source,
)


class ReleaseAuditTests(unittest.TestCase):
    def test_repository_source_inventory_is_complete(self) -> None:
        repo_root = Path(__file__).resolve().parents[3]
        errors, summary = audit_source(repo_root, repo_root / "games" / "inkbound_rogue")
        self.assertEqual(errors, [])
        self.assertEqual(summary["assets"], 113)
        self.assertEqual(summary["ai_pre_generated"], 49)
        self.assertEqual(summary["procedural"], 64)
        self.assertEqual(summary["live_ai"], 0)

    def test_beta_release_maps_to_windows_numeric_version(self) -> None:
        self.assertEqual(_windows_numeric_version("0.25.0-beta.1"), "0.25.0.1")
        self.assertEqual(_windows_numeric_version("1.0.0-alpha"), "1.0.0.0")
        self.assertEqual(_windows_numeric_version("1.2.3"), "1.2.3.0")
        self.assertIsNone(_windows_numeric_version("1.2"))

    def test_isolated_itch_bundle_accepts_only_the_five_release_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            itch_root = Path(temporary_directory)
            (itch_root / "LastInkwarden.exe").write_bytes(b"MZtest")
            (itch_root / "THIRD_PARTY_NOTICES.txt").write_text("notice", encoding="utf-8")
            (itch_root / "PRIVACY_NOTICE.txt").write_text("privacy", encoding="utf-8")
            (itch_root / "version.json").write_text(
                json.dumps({"version": "0.25.0-beta.1"}), encoding="utf-8"
            )
            (itch_root / "Start-Recorded-Playtest.cmd").write_bytes(b"@echo off\r\nexit /b 0\r\n")

            errors, summary = audit_itch_bundle(itch_root, "0.25.0-beta.1")

            self.assertEqual(errors, [])
            self.assertEqual(summary["itch_files"], 5)

    def test_isolated_depot_accepts_privacy_notice(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            depot_root = Path(temporary_directory)
            (depot_root / "LastInkwarden.exe").write_bytes(b"MZtest")
            (depot_root / "THIRD_PARTY_NOTICES.txt").write_text("notice", encoding="utf-8")
            (depot_root / "PRIVACY_NOTICE.txt").write_text("privacy", encoding="utf-8")
            (depot_root / "version.json").write_text(
                json.dumps({"version": "0.25.0-beta.1"}), encoding="utf-8"
            )

            errors, summary = audit_depot(depot_root, "0.25.0-beta.1")

            self.assertEqual(errors, [])
            self.assertEqual(summary["depot_files"], 4)

    def test_isolated_itch_bundle_rejects_internal_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            itch_root = Path(temporary_directory)
            (itch_root / "LastInkwarden.exe").write_bytes(b"MZtest")
            (itch_root / "THIRD_PARTY_NOTICES.txt").write_text("notice", encoding="utf-8")
            (itch_root / "PRIVACY_NOTICE.txt").write_text("privacy", encoding="utf-8")
            (itch_root / "version.json").write_text(
                json.dumps({"version": "0.25.0-beta.1"}), encoding="utf-8"
            )
            (itch_root / "Start-Recorded-Playtest.cmd").write_bytes(b"@echo off\r\nexit /b 0\r\n")
            (itch_root / "internal-capture.png").write_bytes(b"private")

            errors, _summary = audit_itch_bundle(itch_root, "0.25.0-beta.1")

            self.assertTrue(any("differ from allowlist" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
