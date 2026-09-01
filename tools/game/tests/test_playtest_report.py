from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "playtest_report.py"
SPEC = importlib.util.spec_from_file_location("playtest_report", MODULE_PATH)
assert SPEC and SPEC.loader
playtest_report = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(playtest_report)


class PlaytestReportTest(unittest.TestCase):
    def test_aggregate_complete_and_incomplete_sessions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "sessions"
            complete = root / "PT-001"
            incomplete = root / "PT-002"
            complete.mkdir(parents=True)
            incomplete.mkdir(parents=True)
            (complete / "session.json").write_text(
                json.dumps({"session_id": "PT-001", "participant_code": "P-01"}), encoding="utf-8"
            )
            (complete / "summary.json").write_text(
                json.dumps(
                    {
                        "duration_seconds": 600,
                        "event_counts": {"attack": 12},
                        "marker_counts": {"confusing": 1},
                        "last_game_state": {"wave": 6, "input": "gamepad"},
                        "performance": {"minimum_reported_fps": 55.0, "peak_memory_mb": 72.0, "maximum_frame_ms": 24.0},
                    }
                ),
                encoding="utf-8",
            )
            (complete / "survey.json").write_text(
                json.dumps({"ratings": {"controls": 4, "readability": 2}, "would_replay": True}), encoding="utf-8"
            )
            (complete / "events.jsonl").write_text(
                "\n".join(
                    (
                        json.dumps({"kind": "run_started", "data": {"starting_weapon": "greatbrush"}}),
                        json.dumps({"kind": "player_damaged", "data": {"fatal": True, "source": "projectile:scribe"}}),
                    )
                ),
                encoding="utf-8",
            )
            (complete / "markers.jsonl").write_text(
                json.dumps({"category": "confusing"}) + "\n", encoding="utf-8"
            )
            (incomplete / "session.json").write_text(
                json.dumps({"session_id": "PT-002", "participant_code": "P-02"}), encoding="utf-8"
            )
            (incomplete / "incomplete.flag").write_text("unfinished", encoding="utf-8")
            (incomplete / "events.jsonl").write_text(
                json.dumps({"kind": "attack", "data": {"hits": 1}}) + "\n", encoding="utf-8"
            )
            (incomplete / "markers.jsonl").write_text(
                json.dumps({"category": "bug"}) + "\n", encoding="utf-8"
            )
            (incomplete / "performance.jsonl").write_text(
                json.dumps({"fps": 48.0, "memory_mb": 90.0, "frame_max_ms": 31.0, "game": {"wave": 3, "input": "keyboard_mouse"}}) + "\n",
                encoding="utf-8",
            )

            report = playtest_report.aggregate_sessions(root)
            self.assertEqual(report["sessions"], 2)
            self.assertEqual(report["complete_sessions"], 1)
            self.assertEqual(report["incomplete_sessions"], 1)
            self.assertEqual(report["fatal_damage_sources"], {"projectile:scribe": 1})
            self.assertEqual(report["marker_counts"], {"confusing": 1, "bug": 1})
            self.assertEqual(report["starting_weapons"], {"greatbrush": 1})
            self.assertEqual(report["rating_averages"]["controls"], 4)
            self.assertEqual(report["would_replay_ratio"], 1.0)
            self.assertEqual(report["median_furthest_wave"], 4.5)
            self.assertEqual(report["minimum_reported_fps"], 48.0)
            self.assertEqual(report["peak_memory_mb"], 90.0)
            self.assertEqual(report["maximum_frame_ms"], 31.0)
            self.assertEqual(report["input_modes"], {"gamepad": 1, "keyboard_mouse": 1})

            output = Path(temporary) / "reports"
            json_path, markdown_path = playtest_report.write_report(report, output)
            self.assertTrue(json_path.is_file())
            self.assertIn("Fatal damage sources", markdown_path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
