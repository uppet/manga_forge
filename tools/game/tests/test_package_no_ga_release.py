import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.game.package_no_ga_release import BUNDLE_FILES, package_no_ga_release, sha256_file


class NoGameAnalyticsPackageTests(unittest.TestCase):
    def _fixture(self, root: Path, custom_feature: str = "no_gameanalytics") -> tuple[Path, Path]:
        game_root = root / "game"
        scripts = game_root / "scripts"
        release = game_root / "release"
        scripts.mkdir(parents=True)
        release.mkdir(parents=True)
        (scripts / "gameanalytics_credentials.gd").write_text(
            "\n".join(
                (
                    "extends RefCounted",
                    "const EMBEDDED := false",
                    'const GAME_KEY := ""',
                    'const SECRET_KEY := ""',
                    'const ENVIRONMENT := "production"',
                    'const PROFILE := "none"',
                    'const CONFIG_FINGERPRINT := "none"',
                )
            )
            + "\n",
            encoding="utf-8",
        )
        (game_root / "export_presets.cfg").write_text(
            "\n".join(
                (
                    "[preset.0]",
                    "",
                    'name="Windows Desktop No GA"',
                    'platform="Windows Desktop"',
                    f'custom_features="{custom_feature}"',
                )
            )
            + "\n",
            encoding="utf-8",
        )
        (release / "version.json").write_text(
            json.dumps({"product": "Last Inkwarden", "version": "0.25.0-beta.1"}),
            encoding="utf-8",
        )
        (release / "NO_GAMEANALYTICS_BUILD.txt").write_text(
            "No GameAnalytics credentials or remote statistics.\n", encoding="utf-8"
        )
        (release / "PRIVACY_NOTICE_NO_GA.txt").write_text(
            "GameAnalytics is disabled at build time.\n", encoding="utf-8"
        )
        (release / "THIRD_PARTY_NOTICES.txt").write_text("Godot notice.\n", encoding="utf-8")
        (release / "Start-Recorded-Playtest.cmd").write_bytes(b"@echo off\r\nexit /b 0\r\n")
        executable = root / "LastInkwarden.exe"
        executable.write_bytes(b"MZ-no-ga-fixture")
        return game_root, executable

    def test_packages_exact_allowlist_and_safe_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            game_root, executable = self._fixture(root)
            output = root / "output"

            metadata = package_no_ga_release(
                game_root, executable, output, "4.5.2.stable", "a" * 40
            )

            archive_path = output / str(metadata["archive"])
            with zipfile.ZipFile(archive_path) as archive:
                self.assertEqual(set(archive.namelist()), BUNDLE_FILES)
                self.assertIn(
                    b"disabled at build time", archive.read("PRIVACY_NOTICE.txt")
                )
            self.assertFalse(metadata["gameanalytics_available"])
            self.assertFalse(metadata["gameanalytics_embedded"])
            self.assertEqual(metadata["release_profile"], "no_gameanalytics")
            self.assertEqual(sha256_file(archive_path), metadata["archive_sha256"])
            manifest = (output / "no-ga-build.json").read_text(encoding="utf-8")
            self.assertNotIn("secret_key", manifest.lower())
            self.assertNotIn("game_key", manifest.lower())

    def test_archive_is_deterministic_for_identical_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            game_root, executable = self._fixture(root)
            first = package_no_ga_release(
                game_root, executable, root / "one", "4.5.2.stable", "revision"
            )
            second = package_no_ga_release(
                game_root, executable, root / "two", "4.5.2.stable", "revision"
            )
            self.assertEqual(first["archive_sha256"], second["archive_sha256"])

    def test_rejects_preset_without_hard_disable_feature(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            game_root, executable = self._fixture(root, custom_feature="")
            with self.assertRaisesRegex(ValueError, "does not declare no_gameanalytics"):
                package_no_ga_release(
                    game_root, executable, root / "output", "4.5.2.stable", "revision"
                )

    def test_rejects_embedded_credentials_placeholder_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            game_root, executable = self._fixture(root)
            credentials = game_root / "scripts" / "gameanalytics_credentials.gd"
            credentials.write_text(
                credentials.read_text(encoding="utf-8").replace(
                    "const EMBEDDED := false", "const EMBEDDED := true"
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(ValueError, "placeholder is unsafe"):
                package_no_ga_release(
                    game_root, executable, root / "output", "4.5.2.stable", "revision"
                )


if __name__ == "__main__":
    unittest.main()
