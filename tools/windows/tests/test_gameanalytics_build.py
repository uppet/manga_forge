#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest


WINDOWS_TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(WINDOWS_TOOLS))
SPEC = importlib.util.spec_from_file_location("host_game", WINDOWS_TOOLS / "host_game.py")
assert SPEC is not None and SPEC.loader is not None
host_game = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(host_game)


class GameAnalyticsBuildCredentialsTest(unittest.TestCase):
    def test_missing_config_renders_disabled_placeholder(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            missing = Path(temporary) / "missing.local.json"
            self.assertIsNone(host_game.load_gameanalytics_build_credentials("inkbound_rogue", missing))
            rendered = host_game.render_gameanalytics_credentials(None)
            self.assertIn("const EMBEDDED := false", rendered)
            self.assertIn('const CONFIG_FINGERPRINT := "none"', rendered)

    def test_valid_config_is_injected_only_into_runtime(self) -> None:
        game_key = "a" * 32
        secret_key = "b" * 40
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config_path = root / "gameanalytics.local.json"
            config_path.write_text(
                json.dumps(
                    {
                        "inkbound_rogue": {
                            "game_key": game_key,
                            "secret_key": secret_key,
                            "environment": "production",
                        }
                    }
                ),
                encoding="utf-8",
            )
            metadata = host_game.inject_gameanalytics_build_credentials(
                {"wsl_runtime_root": str(root / "runtime")},
                "inkbound_rogue",
                config_path,
            )
            generated = root / "runtime" / "games" / "inkbound_rogue" / "scripts" / "gameanalytics_credentials.gd"
            manifest = root / "runtime" / "games" / "inkbound_rogue" / "build" / "windows" / "gameanalytics-build.json"
            self.assertTrue(metadata["embedded"])
            self.assertEqual(metadata["environment"], "production")
            self.assertEqual(len(metadata["config_fingerprint"]), 16)
            self.assertIn(game_key, generated.read_text(encoding="utf-8"))
            self.assertIn(secret_key, generated.read_text(encoding="utf-8"))
            safe_manifest = manifest.read_text(encoding="utf-8")
            self.assertNotIn(game_key, safe_manifest)
            self.assertNotIn(secret_key, safe_manifest)

            host_game.scrub_gameanalytics_runtime_credentials(
                {"wsl_runtime_root": str(root / "runtime")},
                "inkbound_rogue",
            )
            scrubbed = generated.read_text(encoding="utf-8")
            self.assertIn("const EMBEDDED := false", scrubbed)
            self.assertNotIn(game_key, scrubbed)
            self.assertNotIn(secret_key, scrubbed)

    def test_invalid_secret_is_rejected_without_echoing_it(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            config_path = Path(temporary) / "gameanalytics.local.json"
            config_path.write_text(
                json.dumps(
                    {
                        "inkbound_rogue": {
                            "game_key": "a" * 32,
                            "secret_key": "do-not-echo-this-value",
                            "environment": "production",
                        }
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "secret_key must be exactly 40 hexadecimal characters") as raised:
                host_game.load_gameanalytics_build_credentials("inkbound_rogue", config_path)
            self.assertNotIn("do-not-echo-this-value", str(raised.exception))


if __name__ == "__main__":
    unittest.main()
