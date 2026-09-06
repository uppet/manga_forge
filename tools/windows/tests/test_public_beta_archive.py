#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile


WINDOWS_TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(WINDOWS_TOOLS))
SPEC = importlib.util.spec_from_file_location("host_game", WINDOWS_TOOLS / "host_game.py")
assert SPEC is not None and SPEC.loader is not None
host_game = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(host_game)


class PublicBetaArchiveTest(unittest.TestCase):
    def _fixture(self, root: Path, channel: str = "beta") -> dict[str, object]:
        source = root / "games" / "inkbound_rogue" / "build" / "itch-windows"
        source.mkdir(parents=True)
        (source / "LastInkwarden.exe").write_bytes(b"MZ-public-beta")
        (source / "PRIVACY_NOTICE.txt").write_text("privacy\n", encoding="utf-8")
        (source / "Start-Recorded-Playtest.cmd").write_bytes(b"@echo off\r\nexit /b 0\r\n")
        (source / "THIRD_PARTY_NOTICES.txt").write_text("notice\n", encoding="utf-8")
        (source / "version.json").write_text(
            json.dumps(
                {
                    "product": "Last Inkwarden",
                    "localized_product": "墨卫残章",
                    "version": "0.25.0-beta.1",
                    "channel": channel,
                }
            ),
            encoding="utf-8",
        )
        return {"wsl_runtime_root": str(root)}

    def test_archive_contains_only_public_allowlist_and_safe_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = self._fixture(root)
            metadata = host_game.create_public_beta_archive(
                config,
                "inkbound_rogue",
                {
                    "embedded": True,
                    "environment": "production",
                    "credential_profile": "public_beta",
                    "analytics_project": "Last Inkwarden - Public Beta",
                    "config_fingerprint": "0123456789abcdef",
                },
            )
            output = root / "games" / "inkbound_rogue" / "build" / "public-beta"
            archive_path = output / str(metadata["archive"])
            with zipfile.ZipFile(archive_path, "r") as archive:
                self.assertEqual(set(archive.namelist()), host_game.PUBLIC_BETA_FILES)
            self.assertEqual(host_game.sha256_file(archive_path), metadata["archive_sha256"])
            self.assertTrue(metadata["gameanalytics_embedded"])
            self.assertEqual(metadata["gameanalytics_credential_profile"], "public_beta")
            self.assertEqual(metadata["gameanalytics_project"], "Last Inkwarden - Public Beta")
            self.assertEqual(metadata["channel"], "beta")
            manifest_text = (output / "public-beta-build.json").read_text(encoding="utf-8")
            self.assertNotIn("secret_key", manifest_text.lower())
            self.assertNotIn("game_key", manifest_text.lower())

    def test_archive_rejects_non_beta_channel(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = self._fixture(root, "playtest")
            with self.assertRaisesRegex(ValueError, "channel=beta"):
                host_game.create_public_beta_archive(config, "inkbound_rogue", {"embedded": False})

    def test_archive_rejects_non_beta_analytics_profile(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = self._fixture(root)
            with self.assertRaisesRegex(ValueError, "credential_profile=public_beta"):
                host_game.create_public_beta_archive(
                    config,
                    "inkbound_rogue",
                    {"embedded": True, "credential_profile": "development"},
                )

    def test_archive_rejects_wrong_analytics_project(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = self._fixture(root)
            with self.assertRaisesRegex(ValueError, "Last Inkwarden - Public Beta"):
                host_game.create_public_beta_archive(
                    config,
                    "inkbound_rogue",
                    {
                        "embedded": True,
                        "credential_profile": "public_beta",
                        "analytics_project": "Last Inkwarden - Development",
                    },
                )


if __name__ == "__main__":
    unittest.main()
