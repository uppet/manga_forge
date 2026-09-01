#!/usr/bin/env python3
"""Aggregate privacy-preserving Inkbound playtest sessions into JSON and Markdown."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Iterable


RATING_IDS = ("controls", "readability", "fairness", "build_clarity", "sound", "music_fatigue")


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def read_events(path: Path) -> Iterable[dict[str, Any]]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    events: list[dict[str, Any]] = []
    for line in lines:
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, dict):
            events.append(value)
    return events


def aggregate_sessions(root: Path) -> dict[str, Any]:
    event_counts: Counter[str] = Counter()
    marker_counts: Counter[str] = Counter()
    death_sources: Counter[str] = Counter()
    weapon_starts: Counter[str] = Counter()
    input_modes: Counter[str] = Counter()
    rating_totals: defaultdict[str, float] = defaultdict(float)
    rating_counts: Counter[str] = Counter()
    complete = 0
    incomplete = 0
    surveyed = 0
    would_replay = 0
    duration_total = 0.0
    furthest_waves: list[int] = []
    minimum_fps_values: list[float] = []
    peak_memory_mb = 0.0
    maximum_frame_ms = 0.0
    sessions: list[dict[str, Any]] = []

    for session_dir in sorted(path for path in root.iterdir() if path.is_dir()) if root.is_dir() else []:
        summary = read_json(session_dir / "summary.json")
        metadata = read_json(session_dir / "session.json")
        is_incomplete = (session_dir / "incomplete.flag").exists() or not summary
        incomplete += int(is_incomplete)
        complete += int(not is_incomplete)
        duration = float(summary.get("duration_seconds", 0.0))
        duration_total += max(0.0, duration)
        events = list(read_events(session_dir / "events.jsonl"))
        if events:
            event_counts.update(str(event.get("kind", "unknown")) for event in events)
        else:
            for key, value in summary.get("event_counts", {}).items():
                event_counts[str(key)] += max(0, int(value))

        markers = list(read_events(session_dir / "markers.jsonl"))
        if markers:
            marker_counts.update(str(marker.get("category", "unknown")) for marker in markers)
        else:
            for key, value in summary.get("marker_counts", {}).items():
                marker_counts[str(key)] += max(0, int(value))

        last_state = summary.get("last_game_state", {})
        performance_samples = list(read_events(session_dir / "performance.jsonl"))
        if (not isinstance(last_state, dict) or not last_state) and performance_samples:
            last_state = performance_samples[-1].get("game", {})
        if isinstance(last_state, dict) and last_state:
            furthest_waves.append(max(0, int(last_state.get("wave", 0))))
            mode = str(last_state.get("input", "unknown"))
            input_modes[mode] += 1

        survey = read_json(session_dir / "survey.json")
        ratings = survey.get("ratings", {}) if survey else {}
        if isinstance(ratings, dict) and ratings:
            surveyed += 1
            would_replay += int(bool(survey.get("would_replay", False)))
            for metric in RATING_IDS:
                if metric in ratings:
                    rating_totals[metric] += min(5, max(1, int(ratings[metric])))
                    rating_counts[metric] += 1

        for event in events:
            kind = str(event.get("kind", ""))
            data = event.get("data", {})
            if not isinstance(data, dict):
                continue
            if kind == "player_damaged" and bool(data.get("fatal", False)):
                death_sources[str(data.get("source", "unknown"))] += 1
            elif kind == "run_started":
                weapon_starts[str(data.get("starting_weapon", "unknown"))] += 1

        performance = summary.get("performance", {})
        if not isinstance(performance, dict) or not performance:
            performance = read_json(session_dir / "performance.json")
        minimum_fps = float(performance.get("minimum_reported_fps", 0.0)) if performance else 0.0
        if minimum_fps <= 0.0 and performance_samples:
            positive_fps = [float(sample.get("fps", 0.0)) for sample in performance_samples if float(sample.get("fps", 0.0)) > 0.0]
            minimum_fps = min(positive_fps, default=0.0)
        if minimum_fps > 0.0:
            minimum_fps_values.append(minimum_fps)
        sample_peak_memory = max((float(sample.get("memory_mb", 0.0)) for sample in performance_samples), default=0.0)
        sample_max_frame = max((float(sample.get("frame_max_ms", 0.0)) for sample in performance_samples), default=0.0)
        peak_memory_mb = max(peak_memory_mb, float(performance.get("peak_memory_mb", 0.0)) if performance else 0.0, sample_peak_memory)
        maximum_frame_ms = max(maximum_frame_ms, float(performance.get("maximum_frame_ms", 0.0)) if performance else 0.0, sample_max_frame)

        sessions.append(
            {
                "session_id": str(metadata.get("session_id", session_dir.name)),
                "participant_code": str(metadata.get("participant_code", "anonymous")),
                "complete": not is_incomplete,
                "duration_seconds": duration,
                "furthest_wave": int(last_state.get("wave", 0)) if isinstance(last_state, dict) else 0,
                "surveyed": bool(survey),
                "minimum_fps": minimum_fps,
            }
        )

    session_count = complete + incomplete
    return {
        "schema": 1,
        "sessions": session_count,
        "complete_sessions": complete,
        "incomplete_sessions": incomplete,
        "surveyed_sessions": surveyed,
        "would_replay_ratio": would_replay / surveyed if surveyed else 0.0,
        "average_duration_seconds": duration_total / session_count if session_count else 0.0,
        "median_furthest_wave": _median(furthest_waves),
        "minimum_reported_fps": min(minimum_fps_values, default=0.0),
        "average_session_minimum_fps": sum(minimum_fps_values) / len(minimum_fps_values) if minimum_fps_values else 0.0,
        "peak_memory_mb": peak_memory_mb,
        "maximum_frame_ms": maximum_frame_ms,
        "event_counts": dict(event_counts.most_common()),
        "marker_counts": dict(marker_counts.most_common()),
        "fatal_damage_sources": dict(death_sources.most_common()),
        "starting_weapons": dict(weapon_starts.most_common()),
        "input_modes": dict(input_modes.most_common()),
        "rating_averages": {
            metric: rating_totals[metric] / rating_counts[metric]
            for metric in RATING_IDS
            if rating_counts[metric]
        },
        "session_rows": sessions,
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# Inkbound playtest report",
        "",
        f"- Sessions: {report['sessions']} ({report['complete_sessions']} complete, {report['incomplete_sessions']} incomplete)",
        f"- Survey coverage: {report['surveyed_sessions']}/{report['sessions']}",
        f"- Would replay: {report['would_replay_ratio']:.0%}",
        f"- Average duration: {report['average_duration_seconds'] / 60.0:.1f} minutes",
        f"- Median furthest page: {report['median_furthest_wave']:.1f}",
        f"- Worst reported FPS: {report['minimum_reported_fps']:.1f}",
        f"- Peak memory: {report['peak_memory_mb']:.1f} MB",
        f"- Longest sampled frame: {report['maximum_frame_ms']:.1f} ms",
        "",
        "## Ratings",
        "",
    ]
    ratings = report.get("rating_averages", {})
    lines.extend(
        f"- {metric}{' (lower is better)' if metric == 'music_fatigue' else ''}: {float(value):.2f}/5"
        for metric, value in ratings.items()
    )
    if not ratings:
        lines.append("- No submitted surveys yet.")
    for title, key in (
        ("Moment markers", "marker_counts"),
        ("Fatal damage sources", "fatal_damage_sources"),
        ("Starting weapons", "starting_weapons"),
        ("Input modes", "input_modes"),
    ):
        lines.extend(("", f"## {title}", ""))
        values = report.get(key, {})
        lines.extend(f"- {name}: {count}" for name, count in values.items())
        if not values:
            lines.append("- None recorded.")
    lines.extend(("", "## Sessions", "", "| Session | Participant | Complete | Minutes | Furthest page | Min FPS | Survey |", "| --- | --- | ---: | ---: | ---: | ---: | ---: |"))
    for row in report.get("session_rows", []):
        lines.append(
            f"| {row['session_id']} | {row['participant_code']} | {'yes' if row['complete'] else 'no'} | "
            f"{float(row['duration_seconds']) / 60.0:.1f} | {row['furthest_wave']} | {float(row['minimum_fps']):.1f} | {'yes' if row['surveyed'] else 'no'} |"
        )
    return "\n".join(lines) + "\n"


def write_report(report: dict[str, Any], output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "playtest-report.json"
    markdown_path = output_dir / "playtest-report.md"
    _atomic_write(json_path, json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    _atomic_write(markdown_path, render_markdown(report))
    return json_path, markdown_path


def _atomic_write(path: Path, text: str) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(text, encoding="utf-8")
    temporary.replace(path)


def _median(values: list[int]) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return float(ordered[middle])
    return (ordered[middle - 1] + ordered[middle]) / 2.0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sessions", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    output_dir = args.output_dir or args.sessions.parent / "reports"
    report = aggregate_sessions(args.sessions)
    json_path, markdown_path = write_report(report, output_dir)
    print(
        f"INKBOUND_PLAYTEST_REPORT_OK sessions={report['sessions']} complete={report['complete_sessions']} "
        f"incomplete={report['incomplete_sessions']} json={json_path} markdown={markdown_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
