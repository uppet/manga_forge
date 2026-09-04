#!/usr/bin/env python3
"""Sync, test, export, and launch Manga Forge games on the Windows host."""

from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

from delegate_client import DelegateClient, DelegateConfig


REPO_ROOT = Path(__file__).resolve().parents[2]
CONFIG_DIR = Path(__file__).resolve().parent
DEFAULT_GAME = "inkbound_rogue"
GAMEANALYTICS_LOCAL_CONFIG = CONFIG_DIR / "gameanalytics.local.json"


def load_config() -> dict[str, Any]:
    configured = CONFIG_DIR / "host_config.json"
    path = configured if configured.exists() else CONFIG_DIR / "host_config.example.json"
    return json.loads(path.read_text(encoding="utf-8"))


def load_gameanalytics_build_credentials(game: str, path: Path = GAMEANALYTICS_LOCAL_CONFIG) -> dict[str, str] | None:
    if not path.exists():
        return None
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"invalid GameAnalytics local config: {path}") from exc
    if not isinstance(document, dict) or not isinstance(document.get(game), dict):
        raise ValueError(f"GameAnalytics local config has no object for game: {game}")
    entry = document[game]
    game_key = str(entry.get("game_key", "")).strip().lower()
    secret_key = str(entry.get("secret_key", "")).strip().lower()
    environment = str(entry.get("environment", "production")).strip().lower()
    if re.fullmatch(r"[a-f0-9]{32}", game_key) is None:
        raise ValueError("GameAnalytics game_key must be exactly 32 hexadecimal characters")
    if re.fullmatch(r"[a-f0-9]{40}", secret_key) is None:
        raise ValueError("GameAnalytics secret_key must be exactly 40 hexadecimal characters")
    if environment not in {"sandbox", "production"}:
        raise ValueError("GameAnalytics environment must be sandbox or production")
    fingerprint = hashlib.sha256(f"{environment}:{game_key}:{secret_key}".encode("ascii")).hexdigest()[:16]
    return {
        "game_key": game_key,
        "secret_key": secret_key,
        "environment": environment,
        "fingerprint": fingerprint,
    }


def render_gameanalytics_credentials(credentials: dict[str, str] | None) -> str:
    if credentials is None:
        embedded = "false"
        game_key = ""
        secret_key = ""
        environment = "production"
        fingerprint = "none"
    else:
        embedded = "true"
        game_key = credentials["game_key"]
        secret_key = credentials["secret_key"]
        environment = credentials["environment"]
        fingerprint = credentials["fingerprint"]
    return "\n".join(
        [
            "extends RefCounted",
            "",
            "# Generated in the Windows runtime by tools/windows/host_game.py.",
            "# Never copy this generated file back into the Git source tree.",
            f"const EMBEDDED := {embedded}",
            f"const GAME_KEY := {json.dumps(game_key)}",
            f"const SECRET_KEY := {json.dumps(secret_key)}",
            f"const ENVIRONMENT := {json.dumps(environment)}",
            f"const CONFIG_FINGERPRINT := {json.dumps(fingerprint)}",
            "",
        ]
    )


def inject_gameanalytics_build_credentials(
    config: dict[str, Any],
    game: str,
    credentials_path: Path = GAMEANALYTICS_LOCAL_CONFIG,
) -> dict[str, Any]:
    credentials = load_gameanalytics_build_credentials(game, credentials_path)
    destination = Path(config["wsl_runtime_root"]) / "games" / game
    generated_path = destination / "scripts" / "gameanalytics_credentials.gd"
    generated_path.parent.mkdir(parents=True, exist_ok=True)
    generated_path.write_text(render_gameanalytics_credentials(credentials), encoding="utf-8", newline="\n")
    metadata: dict[str, Any] = {
        "embedded": credentials is not None,
        "environment": credentials["environment"] if credentials is not None else "none",
        "config_fingerprint": credentials["fingerprint"] if credentials is not None else "none",
        "source": "tools/windows/gameanalytics.local.json",
    }
    build_root = destination / "build" / "windows"
    build_root.mkdir(parents=True, exist_ok=True)
    (build_root / "gameanalytics-build.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(
        "gameanalytics_build_credentials="
        + (f"embedded environment={metadata['environment']} fingerprint={metadata['config_fingerprint']}" if metadata["embedded"] else "not_embedded")
    )
    return metadata


def scrub_gameanalytics_runtime_credentials(config: dict[str, Any], game: str) -> None:
    generated_path = Path(config["wsl_runtime_root"]) / "games" / game / "scripts" / "gameanalytics_credentials.gd"
    if generated_path.parent.is_dir():
        generated_path.write_text(render_gameanalytics_credentials(None), encoding="utf-8", newline="\n")
        print("gameanalytics_runtime_credentials=scrubbed")


def posix_game_root(config: dict[str, Any], game: str) -> str:
    return config["windows_runtime_root"].replace("\\", "/").replace("S:", "/s") + f"/games/{game}"


def godot_resolver(config: dict[str, Any]) -> str:
    quoted = " ".join(f"'{candidate}'" for candidate in config["godot_candidates"])
    return f"""
resolve_godot() {{
  for candidate in {quoted}; do
    if [ -x \"$candidate\" ]; then printf '%s' \"$candidate\"; return 0; fi
  done
  candidate=$(find /c/Users/Joyer/AppData/Local/Microsoft/WinGet/Packages -maxdepth 4 -type f -iname 'Godot*_win64.exe' 2>/dev/null | sort -Vr | head -1)
  if [ -n \"$candidate\" ]; then printf '%s' \"$candidate\"; return 0; fi
  return 1
}}
GODOT=$(resolve_godot) || {{ echo 'Godot executable not found' >&2; exit 12; }}
timeout() {{ command timeout --kill-after=10s "$@"; }}
""".strip()


def make_client(config: dict[str, Any]) -> DelegateClient:
    return DelegateClient(
        DelegateConfig(
            mcp_url=config["mcp_url"],
            proxy=config.get("proxy"),
            windows_shell=config["windows_shell"],
        )
    )


def generate_assets() -> None:
    subprocess.run(
        [sys.executable, str(REPO_ROOT / "tools" / "game" / "generate_validation_assets.py")],
        check=True,
        cwd=REPO_ROOT,
    )


def sync(config: dict[str, Any], game: str) -> None:
    generate_assets()
    source = REPO_ROOT / "games" / game
    if not source.is_dir():
        raise FileNotFoundError(f"game project does not exist: {source}")
    runtime_root = Path(config["wsl_runtime_root"])
    destination = runtime_root / "games" / game
    destination.parent.mkdir(parents=True, exist_ok=True)
    pruned = 0
    if destination.exists():
        # Mirror source material without touching imported cache, exported
        # builds, captures, or local playtest sessions. This prevents a deleted
        # source resource lingering in a later all-resources export.
        for target in sorted(destination.rglob("*"), key=lambda path: len(path.parts), reverse=True):
            relative = target.relative_to(destination)
            if not relative.parts or relative.parts[0] in {".godot", "build"}:
                continue
            if target.name.endswith(".import"):
                source_resource = source / Path(str(relative)[: -len(".import")])
                if source_resource.exists():
                    continue
            source_target = source / relative
            if (target.is_file() or target.is_symlink()) and not source_target.exists():
                target.unlink()
                pruned += 1
            elif target.is_dir() and not source_target.exists():
                try:
                    target.rmdir()
                except OSError:
                    pass
    shutil.copytree(
        source,
        destination,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns(".godot", "build", "*.log"),
    )
    print(f"synced {source} -> {destination} (pruned_stale_source_files={pruned})")
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
IMPORT_STATUS=0
timeout 180s "$GODOT" --headless --path "$GAME" --import || IMPORT_STATUS=$?
test "$IMPORT_STATUS" -eq 0 -o "$IMPORT_STATUS" -eq 1
SOURCE_COUNT=$(find "$GAME/assets" -type f \( -name '*.png' -o -name '*.wav' -o -name '*.ogg' \) | wc -l)
IMPORT_COUNT=$(find "$GAME/assets" -type f -name '*.import' | wc -l)
test "$IMPORT_COUNT" -eq "$SOURCE_COUNT"
echo "godot_import_status=$IMPORT_STATUS imported_resources=$IMPORT_COUNT"
"""
    remote(config, command, 240)


def remote(config: dict[str, Any], command: str, timeout: int, cwd: str | None = None) -> None:
    client = make_client(config)
    try:
        result = client.run(command, cwd or config["windows_runtime_root"], timeout=timeout)
    finally:
        client.close()
    output = result.get("rendered_output", "")
    if output:
        print(output)
    print(f"task={result.get('task_id')} status={result.get('status')} exit={result.get('exit_code')}")
    if result.get("status") != "completed" or result.get("exit_code") not in (0, None):
        raise SystemExit(int(result.get("exit_code") or 1))


def probe(config: dict[str, Any]) -> None:
    command = godot_resolver(config) + "\n\"$GODOT\" --version\nprintf '\\ngodot=%s\\n' \"$GODOT\""
    drive = config["windows_runtime_root"].split("\\", 1)[0] + "\\"
    remote(config, command, 120, cwd=drive)


def process_status(config: dict[str, Any]) -> None:
    command = r"""
powershell.exe -NoProfile -Command '$now = Get-Date; $items = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "InkboundRogue.exe" -or $_.Name -like "Godot*.exe" } | ForEach-Object { [pscustomobject]@{ ProcessId = $_.ProcessId; Name = $_.Name; ElapsedSeconds = [math]::Round(($now - $_.CreationDate).TotalSeconds, 1); CpuSeconds = [math]::Round(($_.KernelModeTime + $_.UserModeTime) / 10000000, 1); WorkingSetMB = [math]::Round($_.WorkingSetSize / 1MB, 1); CommandLine = $_.CommandLine } }); [pscustomobject]@{ count = $items.Count; processes = $items } | ConvertTo-Json -Depth 4 -Compress'
""".strip()
    drive = config["windows_runtime_root"].split("\\", 1)[0] + "\\"
    remote(config, command, 120, cwd=drive)


def cleanup_tests(config: dict[str, Any], game: str) -> None:
    project_token = safe_token(game, DEFAULT_GAME)
    command = rf"""
powershell.exe -NoProfile -Command '$items = @(Get-CimInstance Win32_Process | Where-Object {{ $_.Name -like "Godot*.exe" -and $_.CommandLine -like "*{project_token}*" -and $_.CommandLine -like "*--script res://tests/*" }}); foreach ($item in $items) {{ Stop-Process -Id $item.ProcessId -ErrorAction SilentlyContinue }}; Start-Sleep -Milliseconds 500; $remaining = @(Get-CimInstance Win32_Process | Where-Object {{ $_.Name -like "Godot*.exe" -and $_.CommandLine -like "*{project_token}*" -and $_.CommandLine -like "*--script res://tests/*" }}); [pscustomobject]@{{ stopped = $items.Count; remaining = $remaining.Count }} | ConvertTo-Json -Compress; if ($remaining.Count -gt 0) {{ exit 18 }}'
""".strip()
    drive = config["windows_runtime_root"].split("\\", 1)[0] + "\\"
    remote(config, command, 120, cwd=drive)


def ensure_game_not_running(config: dict[str, Any]) -> None:
    command = r"""
powershell.exe -NoProfile -Command '$count = @(Get-Process -Name "InkboundRogue" -ErrorAction SilentlyContinue).Count; if ($count -gt 0) { Write-Error "InkboundRogue is already running; close it before preparing a playtest build"; exit 19 }'
""".strip()
    drive = config["windows_runtime_root"].split("\\", 1)[0] + "\\"
    remote(config, command, 120, cwd=drive)


def test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 90s \"$GODOT\" --headless --path \"$GAME\" --script res://tests/smoke_test.gd
"""
    remote(config, command, 600)


def soak(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 180s "$GODOT" --headless --path "$GAME" --script res://tests/soak_test.gd
"""
    remote(config, command, 240)


def recorded_soak(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
OUTPUT="$GAME/build/playtest/perf-audit"
mkdir -p "$OUTPUT"
OUTPUT_WIN=$(cygpath -w "$OUTPUT")
export INKBOUND_PLAYTEST=1
export INKBOUND_PLAYTEST_SESSION='PERF-SOAK'
export INKBOUND_PLAYTEST_PARTICIPANT='automated'
export INKBOUND_PLAYTEST_DIR="$OUTPUT_WIN"
export INKBOUND_BUILD_ID='recorded-soak'
export INKBOUND_GIT_COMMIT='automated'
timeout 180s "$GODOT" --headless --path "$GAME" --script res://tests/soak_test.gd
test -s "$OUTPUT/PERF-SOAK/summary.json"
test -s "$OUTPUT/PERF-SOAK/performance.json"
test ! -e "$OUTPUT/PERF-SOAK/incomplete.flag"
"""
    remote(config, command, 240)


def p1_suite(config: dict[str, Any], game: str) -> None:
    gameanalytics_build_test()
    sync(config, game)
    game_root = posix_game_root(config, game)
    gates = [
        ("smoke", "smoke_test.gd", "headless", 120),
        ("pause", "pause_state_test.gd", "headless", 120),
        ("quit", "quit_flow_test.gd", "headless", 120),
        ("defeat", "defeat_flow_test.gd", "headless", 120),
        ("save", "save_recovery_test.gd", "headless", 120),
        ("session", "session_flow_test.gd", "headless", 180),
        ("supply", "supply_drop_test.gd", "headless", 120),
        ("ink-art", "ink_art_test.gd", "headless", 120),
        ("encounters", "encounter_director_test.gd", "headless", 180),
        ("hazards", "route_hazard_test.gd", "headless", 120),
        ("loadout", "starting_loadout_test.gd", "headless", 120),
        ("relics", "relic_draft_test.gd", "headless", 120),
        ("cutscenes", "cutscene_animation_test.gd", "headless", 120),
        ("manual", "field_manual_test.gd", "window", 120),
        ("localization", "localization_test.gd", "window", 120),
        ("cast", "combat_cast_test.gd", "headless", 120),
        ("audio", "audio_system_test.gd", "headless", 120),
        ("combat-feel", "combat_feel_test.gd", "headless", 120),
        ("accessibility", "accessibility_test.gd", "headless", 120),
        ("restoration", "restoration_board_test.gd", "headless", 120),
        ("proof", "proof_depth_test.gd", "headless", 120),
        ("daily", "daily_chronicle_test.gd", "headless", 120),
        ("progression", "progression_test.gd", "headless", 120),
        ("routes", "route_system_test.gd", "headless", 120),
        ("balance", "balance_matrix_test.gd", "headless", 180),
        ("personas", "player_persona_test.gd", "headless", 240),
        ("recorder", "playtest_recorder_test.gd", "headless", 120),
        ("gameanalytics", "gameanalytics_test.gd", "headless", 120),
        ("soak", "soak_test.gd", "headless", 180),
    ]
    invocations = "\n".join(
        f"run_gate '{label}' '{mode}' '{script}' '{limit}s'"
        for label, script, mode, limit in gates
    )
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
RUN_ID=$(date -u +'%Y%m%dT%H%M%SZ')
REPORT_ROOT="$GAME/build/p1-suite"
REPORT_DIR="$REPORT_ROOT/$RUN_ID"
SUMMARY="$REPORT_DIR/summary.log"
mkdir -p "$REPORT_DIR"
printf '%s\n' "$RUN_ID" > "$REPORT_ROOT/latest.txt"
unset INKBOUND_PLAYTEST INKBOUND_PLAYTEST_SESSION INKBOUND_PLAYTEST_PARTICIPANT INKBOUND_PLAYTEST_DIR INKBOUND_BUILD_ID INKBOUND_GIT_COMMIT INKBOUND_BOOT_SMOKE INKBOUND_GA_GAME_KEY INKBOUND_GA_SECRET_KEY INKBOUND_GA_ENVIRONMENT INKBOUND_GA_ENABLED INKBOUND_GA_DEBUG
run_gate() {{
  LABEL="$1"
  MODE="$2"
  SCRIPT="$3"
  LIMIT="$4"
  LOG="$REPORT_DIR/$LABEL.log"
  printf 'P1_GATE_BEGIN %s\n' "$LABEL" | tee -a "$SUMMARY"
  if [ "$MODE" = 'window' ]; then
    if timeout "$LIMIT" "$GODOT" --path "$GAME" --script "res://tests/$SCRIPT" > "$LOG" 2>&1; then
      STATUS=0
    else
      STATUS=$?
    fi
  else
    if timeout "$LIMIT" "$GODOT" --headless --path "$GAME" --script "res://tests/$SCRIPT" > "$LOG" 2>&1; then
      STATUS=0
    else
      STATUS=$?
    fi
  fi
  if [ "$STATUS" -ne 0 ]; then
    printf 'P1_GATE_FAIL %s exit=%s log=%s\n' "$LABEL" "$STATUS" "$LOG" | tee -a "$SUMMARY"
    tail -n 80 "$LOG"
    exit "$STATUS"
  fi
  printf 'P1_GATE_PASS %s\n' "$LABEL" | tee -a "$SUMMARY"
}}
{invocations}
printf 'INKBOUND_P1_SUITE_OK gates={len(gates)} mode=serial report=%s\n' "$REPORT_DIR" | tee -a "$SUMMARY"
"""
    remote(config, command, 1800)
    process_status(config)


def save_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 90s "$GODOT" --headless --path "$GAME" --script res://tests/save_recovery_test.gd
"""
    remote(config, command, 180)


def pause_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 90s "$GODOT" --headless --path "$GAME" --script res://tests/pause_state_test.gd
"""
    remote(config, command, 180)


def quit_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 90s "$GODOT" --headless --path "$GAME" --script res://tests/quit_flow_test.gd
"""
    remote(config, command, 180)


def defeat_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 90s "$GODOT" --headless --path "$GAME" --script res://tests/defeat_flow_test.gd
"""
    remote(config, command, 180)


def session_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/session_flow_test.gd
"""
    remote(config, command, 180)


def supply_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/supply_drop_test.gd
"""
    remote(config, command, 180)


def art_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/ink_art_test.gd
"""
    remote(config, command, 180)


def encounter_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 180s "$GODOT" --headless --path "$GAME" --import
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/encounter_director_test.gd
"""
    remote(config, command, 180)


def hazard_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/route_hazard_test.gd
"""
    remote(config, command, 180)


def loadout_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/starting_loadout_test.gd
"""
    remote(config, command, 180)


def relic_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/relic_draft_test.gd
"""
    remote(config, command, 180)


def cutscene_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --editor --quit
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/cutscene_animation_test.gd
"""
    remote(config, command, 180)


def manual_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
# RichTextLabel reports different glyph metrics through Godot's dummy headless
# renderer. Run this layout-sensitive regression through the real Windows
# renderer, matching the shipped game and the screenshot harness.
timeout 120s "$GODOT" --path "$GAME" --script res://tests/field_manual_test.gd
"""
    remote(config, command, 180)


def localization_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
# CJK font resolution and glyph metrics must match the shipped Windows renderer.
timeout 120s "$GODOT" --path "$GAME" --script res://tests/localization_test.gd
"""
    remote(config, command, 180)


def cast_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 180s "$GODOT" --headless --path "$GAME" --import
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/combat_cast_test.gd
"""
    remote(config, command, 180)


def audio_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 180s "$GODOT" --headless --path "$GAME" --import
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/audio_system_test.gd
"""
    remote(config, command, 180)


def combat_feel_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/combat_feel_test.gd
"""
    remote(config, command, 180)


def accessibility_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/accessibility_test.gd
"""
    remote(config, command, 180)


def restoration_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/restoration_board_test.gd
"""
    remote(config, command, 180)


def proof_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/proof_depth_test.gd
"""
    remote(config, command, 180)


def daily_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/daily_chronicle_test.gd
"""
    remote(config, command, 180)


def capture_session(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --path "$GAME" --script res://tests/capture_session_ui.gd
"""
    remote(config, command, 180)


def capture_ink_art(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --path "$GAME" --script res://tests/capture_ink_art_cinematics.gd
"""
    remote(config, command, 180)


def capture_upgrades(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 60s "$GODOT" --path "$GAME" --script res://tests/capture_upgrade_ui.gd
"""
    remote(config, command, 120)


def capture_restoration(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 60s "$GODOT" --path "$GAME" --script res://tests/capture_restoration_ui.gd
"""
    remote(config, command, 120)


def capture_proof(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 60s "$GODOT" --path "$GAME" --script res://tests/capture_proof_ledger.gd
"""
    remote(config, command, 120)


def capture_daily(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 60s "$GODOT" --path "$GAME" --script res://tests/capture_daily_chronicle.gd
"""
    remote(config, command, 120)


def capture_cutscenes(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --editor --quit
timeout 120s "$GODOT" --path "$GAME" --script res://tests/capture_cutscene_gallery.gd
"""
    remote(config, command, 180)


def capture_manual(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --path "$GAME" --script res://tests/capture_manual_ui.gd
"""
    remote(config, command, 180)


def capture_localization(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --path "$GAME" --script res://tests/capture_localization_ui.gd
"""
    remote(config, command, 180)


def balance(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 180s "$GODOT" --headless --path "$GAME" --script res://tests/balance_matrix_test.gd
"""
    remote(config, command, 240)


def persona_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 240s "$GODOT" --headless --path "$GAME" --script res://tests/player_persona_test.gd
"""
    remote(config, command, 300)


def gameanalytics_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
unset INKBOUND_GA_GAME_KEY INKBOUND_GA_SECRET_KEY INKBOUND_GA_ENVIRONMENT INKBOUND_GA_ENABLED INKBOUND_GA_DEBUG
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/gameanalytics_test.gd
"""
    remote(config, command, 180)


def gameanalytics_build_test() -> None:
    subprocess.run(
        [sys.executable, str(CONFIG_DIR / "tests" / "test_gameanalytics_build.py")],
        check=True,
        cwd=REPO_ROOT,
    )


def progression(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/progression_test.gd
"""
    remote(config, command, 180)


def routes(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/route_system_test.gd
"""
    remote(config, command, 180)


def export(config: dict[str, Any], game: str) -> None:
    sync(config, game)
    analytics_build = inject_gameanalytics_build_credentials(config, game)
    expected_analytics_embedded = "true" if analytics_build["embedded"] else "false"
    expected_analytics_fingerprint = analytics_build["config_fingerprint"]
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
mkdir -p \"$GAME/build/windows\"
rm -f \"$GAME/build/windows/InkboundRogue.exe\" \"$GAME/build/windows/InkboundRogue.tmp\" \"$GAME/build/windows/Start-GameAnalytics.local.cmd.example\"
\"$GODOT\" --headless --path \"$GAME\" --export-release 'Windows Desktop' \"$GAME/build/windows/InkboundRogue.exe\"
test -s \"$GAME/build/windows/InkboundRogue.exe\"
cp \"$GAME/release/THIRD_PARTY_NOTICES.txt\" \"$GAME/build/windows/THIRD_PARTY_NOTICES.txt\"
cp \"$GAME/release/version.json\" \"$GAME/build/windows/version.json\"
cp \"$GAME/release/Start-Recorded-Playtest.cmd\" \"$GAME/build/windows/Start-Recorded-Playtest.cmd\"
test \"$(tr -cd '\\r' < \"$GAME/build/windows/Start-Recorded-Playtest.cmd\" | wc -c)\" -gt 20
ITCH=\"$GAME/build/itch-windows\"
mkdir -p \"$ITCH\"
cp \"$GAME/build/windows/InkboundRogue.exe\" \"$ITCH/InkboundRogue.exe\"
cp \"$GAME/build/windows/THIRD_PARTY_NOTICES.txt\" \"$ITCH/THIRD_PARTY_NOTICES.txt\"
cp \"$GAME/build/windows/version.json\" \"$ITCH/version.json\"
cp \"$GAME/build/windows/Start-Recorded-Playtest.cmd\" \"$ITCH/Start-Recorded-Playtest.cmd\"
test \"$(find \"$ITCH\" -mindepth 1 -maxdepth 1 | wc -l)\" -eq 4
DEPOT=\"$GAME/build/steam-depot\"
mkdir -p \"$DEPOT\"
rm -f \"$DEPOT/InkboundRogue.exe\" \"$DEPOT/THIRD_PARTY_NOTICES.txt\" \"$DEPOT/version.json\"
cp \"$GAME/build/windows/InkboundRogue.exe\" \"$DEPOT/InkboundRogue.exe\"
cp \"$GAME/build/windows/THIRD_PARTY_NOTICES.txt\" \"$DEPOT/THIRD_PARTY_NOTICES.txt\"
cp \"$GAME/build/windows/version.json\" \"$DEPOT/version.json\"
test \"$(find \"$DEPOT\" -mindepth 1 -maxdepth 1 | wc -l)\" -eq 3
BOOT_STATUS=0
export INKBOUND_BOOT_SMOKE=1
export INKBOUND_GA_ENABLED=0
BOOT_LOG=\"$GAME/build/windows/export-boot.log\"
timeout 30s \"$GAME/build/windows/InkboundRogue.exe\" > \"$BOOT_LOG\" 2>&1 || BOOT_STATUS=$?
cat \"$BOOT_LOG\"
echo "export_boot_status=$BOOT_STATUS"
test "$BOOT_STATUS" -eq 0
grep -F \"analytics_embedded={expected_analytics_embedded} analytics_config={expected_analytics_fingerprint}\" \"$BOOT_LOG\"
"""
    try:
        remote(config, command, 1200)
    finally:
        scrub_gameanalytics_runtime_credentials(config, game)
    depot_root = Path(config["wsl_runtime_root"]) / "games" / game / "build" / "steam-depot"
    itch_root = Path(config["wsl_runtime_root"]) / "games" / game / "build" / "itch-windows"
    subprocess.run(
        [
            sys.executable,
            str(REPO_ROOT / "tools" / "game" / "release_audit.py"),
            "--game-root",
            str(REPO_ROOT / "games" / game),
            "--depot-root",
            str(depot_root),
            "--itch-root",
            str(itch_root),
        ],
        check=True,
        cwd=REPO_ROOT,
    )


def release_audit(config: dict[str, Any], game: str) -> None:
    subprocess.run(
        [sys.executable, str(REPO_ROOT / "tools" / "game" / "generate_validation_assets.py"), "--check"],
        check=True,
        cwd=REPO_ROOT,
    )
    depot_root = Path(config["wsl_runtime_root"]) / "games" / game / "build" / "steam-depot"
    itch_root = Path(config["wsl_runtime_root"]) / "games" / game / "build" / "itch-windows"
    command = [
        sys.executable,
        str(REPO_ROOT / "tools" / "game" / "release_audit.py"),
        "--game-root",
        str(REPO_ROOT / "games" / game),
    ]
    if depot_root.is_dir():
        command.extend(["--depot-root", str(depot_root)])
    if itch_root.is_dir():
        command.extend(["--itch-root", str(itch_root)])
    subprocess.run(command, check=True, cwd=REPO_ROOT)


def export_smoke(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
TARGET="$GAME/build/windows/InkboundRogue.exe"
test -s "$TARGET"
BOOT_STATUS=0
export INKBOUND_BOOT_SMOKE=1
timeout 30s "$TARGET" || BOOT_STATUS=$?
echo "export_boot_status=$BOOT_STATUS"
test "$BOOT_STATUS" -eq 0
"""
    remote(config, command, 120)


def run(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
GAME='{game_root}'
if [ -f \"$GAME/build/windows/InkboundRogue.exe\" ]; then
  TARGET=\"$GAME/build/windows/InkboundRogue.exe\"
  EXISTING=$(powershell.exe -NoProfile -Command '(Get-Process -Name "InkboundRogue" -ErrorAction SilentlyContinue | Measure-Object).Count' | tr -d '\r[:space:]')
  if [ \"${{EXISTING:-0}}\" -gt 0 ]; then
    echo \"already running: InkboundRogue.exe instances=$EXISTING\"
    exit 0
  fi
  TARGET_WIN=$(cygpath -w \"$TARGET\")
  powershell.exe -NoProfile -Command \"Start-Process -FilePath '$TARGET_WIN' -ErrorAction Stop\"
else
  TARGET=\"$GODOT\"
  TARGET_WIN=$(cygpath -w \"$TARGET\")
  GAME_WIN=$(cygpath -w \"$GAME\")
  powershell.exe -NoProfile -Command \"Start-Process -FilePath '$TARGET_WIN' -ArgumentList '--path','$GAME_WIN' -ErrorAction Stop\"
fi
echo \"launched $TARGET\"
"""
    remote(config, command, 120)


def safe_token(value: str, fallback: str = "anonymous", maximum: int = 48) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_-]+", "-", value.strip()).strip("-")
    return (cleaned or fallback)[:maximum]


def build_identity(game: str) -> tuple[str, str]:
    commit = subprocess.check_output(
        ["git", "rev-parse", "--short=12", "HEAD"], cwd=REPO_ROOT, text=True
    ).strip()
    dirty = bool(
        subprocess.check_output(
            ["git", "status", "--porcelain", "--untracked-files=normal"], cwd=REPO_ROOT, text=True
        ).strip()
    )
    version_path = REPO_ROOT / "games" / game / "release" / "version.json"
    version = str(json.loads(version_path.read_text(encoding="utf-8")).get("version", "dev"))
    return commit + ("-dirty" if dirty else ""), safe_token(f"{version}-{commit}{'-dirty' if dirty else ''}", "dev", 80)


def playtest(config: dict[str, Any], game: str, participant: str, reuse_build: bool = False) -> None:
    ensure_game_not_running(config)
    if not reuse_build:
        export(config, game)
    game_root = posix_game_root(config, game)
    commit, build_id = build_identity(game)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")[:-3]
    session_id = safe_token(f"PT-{timestamp}-{participant}", "PT-session", 48)
    participant_code = safe_token(participant)
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
TARGET="$GAME/build/windows/InkboundRogue.exe"
test -s "$TARGET"
SESSION_ROOT="$GAME/build/playtest/sessions"
mkdir -p "$SESSION_ROOT"
TARGET_WIN=$(cygpath -w "$TARGET")
WORK_WIN=$(cygpath -w "$GAME/build/windows")
SESSION_ROOT_WIN=$(cygpath -w "$SESSION_ROOT")
export INKBOUND_PLAYTEST=1
export INKBOUND_PLAYTEST_SESSION='{session_id}'
export INKBOUND_PLAYTEST_PARTICIPANT='{participant_code}'
export INKBOUND_PLAYTEST_DIR="$SESSION_ROOT_WIN"
export INKBOUND_BUILD_ID='{build_id}'
export INKBOUND_GIT_COMMIT='{commit}'
powershell.exe -NoProfile -Command "Start-Process -FilePath '$TARGET_WIN' -WorkingDirectory '$WORK_WIN' -ErrorAction Stop"
echo "playtest_session={session_id}"
echo "playtest_build={build_id}"
echo "playtest_output=$SESSION_ROOT"
"""
    remote(config, command, 180)


def recorded_launcher_test(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = f"""
set -e
GAME='{game_root}'
LAUNCHER="$GAME/build/itch-windows/Start-Recorded-Playtest.cmd"
TARGET="$GAME/build/itch-windows/InkboundRogue.exe"
RUN_ID=$(date -u +'%Y%m%dT%H%M%SZ')
OUTPUT="$GAME/build/playtest/launcher-audit/$RUN_ID"
test -s "$TARGET"
test -s "$LAUNCHER"
mkdir -p "$OUTPUT"
export INKBOUND_LAUNCHER_PATH=$(cygpath -w "$LAUNCHER")
export INKBOUND_PLAYTEST_DIR=$(cygpath -w "$OUTPUT")
export INKBOUND_BOOT_SMOKE=1
export INKBOUND_LAUNCHER_ACCEPT=1
export INKBOUND_LAUNCHER_NO_PAUSE=1
export INKBOUND_LAUNCHER_NO_OPEN=1
powershell.exe -NoProfile -Command '& $env:INKBOUND_LAUNCHER_PATH automated; exit $LASTEXITCODE'
test "$(find "$OUTPUT" -mindepth 2 -maxdepth 2 -type f -name 'summary.json' | wc -l)" -eq 1
test "$(find "$OUTPUT" -mindepth 2 -maxdepth 2 -type f -name 'session.json' | wc -l)" -eq 1
test "$(find "$OUTPUT" -mindepth 2 -maxdepth 2 -type f -name 'incomplete.flag' | wc -l)" -eq 0
grep -Eq '"participant_code"[[:space:]]*:[[:space:]]*"automated"' "$OUTPUT"/*/summary.json
grep -Eq '"complete"[[:space:]]*:[[:space:]]*true' "$OUTPUT"/*/summary.json
echo "INKBOUND_RECORDED_LAUNCHER_OK output=$OUTPUT"
"""
    remote(config, command, 240)
    process_status(config)


def playtest_report(config: dict[str, Any], game: str) -> None:
    game_root = Path(config["wsl_runtime_root"]) / "games" / game
    sessions = game_root / "build" / "playtest" / "sessions"
    output_dir = game_root / "build" / "playtest" / "reports"
    subprocess.run(
        [
            sys.executable,
            str(REPO_ROOT / "tools" / "game" / "playtest_report.py"),
            "--sessions",
            str(sessions),
            "--output-dir",
            str(output_dir),
        ],
        check=True,
        cwd=REPO_ROOT,
    )


def restart(config: dict[str, Any], game: str) -> None:
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
TARGET="$GAME/build/windows/InkboundRogue.exe"
test -s "$TARGET"
powershell.exe -NoProfile -Command '$items = @(Get-Process -Name "InkboundRogue" -ErrorAction SilentlyContinue); foreach ($item in $items) {{ $null = $item.CloseMainWindow() }}; $deadline = (Get-Date).AddSeconds(8); do {{ Start-Sleep -Milliseconds 200; $remaining = @(Get-Process -Name "InkboundRogue" -ErrorAction SilentlyContinue) }} while ($remaining.Count -gt 0 -and (Get-Date) -lt $deadline); if ($remaining.Count -gt 0) {{ Write-Error "InkboundRogue did not close gracefully; refusing to force-stop it"; exit 17 }}'
TARGET_WIN=$(cygpath -w "$TARGET")
powershell.exe -NoProfile -Command "Start-Process -FilePath '$TARGET_WIN' -ErrorAction Stop"
echo "gracefully restarted $TARGET"
"""
    remote(config, command, 180)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("probe", "process-status", "cleanup-tests", "sync", "p1-suite", "test", "save-test", "pause-test", "quit-test", "defeat-test", "session-test", "supply-test", "art-test", "encounter-test", "hazard-test", "loadout-test", "relic-test", "cutscene-test", "manual-test", "localization-test", "cast-test", "audio-test", "combat-feel-test", "accessibility-test", "restoration-test", "proof-test", "daily-test", "persona-test", "playtest-recorder-test", "gameanalytics-test", "gameanalytics-build-test", "recorded-launcher-test", "capture-session", "capture-ink-art", "capture-upgrades", "capture-restoration", "capture-proof", "capture-daily", "capture-cutscenes", "capture-manual", "capture-localization", "balance", "progression", "routes", "soak", "recorded-soak", "release-audit", "export-smoke", "export", "playtest", "playtest-report", "restart", "run"))
    parser.add_argument("--game", default=DEFAULT_GAME)
    parser.add_argument("--participant", default="anonymous", help="anonymous facilitator-assigned playtest code")
    parser.add_argument("--reuse-build", action="store_true", help="launch the existing exported build without sync/export")
    args = parser.parse_args()
    config = load_config()
    if args.command == "sync":
        sync(config, args.game)
    elif args.command == "p1-suite":
        p1_suite(config, args.game)
    elif args.command == "probe":
        probe(config)
    elif args.command == "process-status":
        process_status(config)
    elif args.command == "cleanup-tests":
        cleanup_tests(config, args.game)
    elif args.command == "test":
        test(config, args.game)
    elif args.command == "save-test":
        save_test(config, args.game)
    elif args.command == "pause-test":
        pause_test(config, args.game)
    elif args.command == "quit-test":
        quit_test(config, args.game)
    elif args.command == "defeat-test":
        defeat_test(config, args.game)
    elif args.command == "session-test":
        session_test(config, args.game)
    elif args.command == "supply-test":
        supply_test(config, args.game)
    elif args.command == "art-test":
        art_test(config, args.game)
    elif args.command == "encounter-test":
        encounter_test(config, args.game)
    elif args.command == "hazard-test":
        hazard_test(config, args.game)
    elif args.command == "loadout-test":
        loadout_test(config, args.game)
    elif args.command == "relic-test":
        relic_test(config, args.game)
    elif args.command == "cutscene-test":
        cutscene_test(config, args.game)
    elif args.command == "manual-test":
        manual_test(config, args.game)
    elif args.command == "localization-test":
        localization_test(config, args.game)
    elif args.command == "cast-test":
        cast_test(config, args.game)
    elif args.command == "audio-test":
        audio_test(config, args.game)
    elif args.command == "combat-feel-test":
        combat_feel_test(config, args.game)
    elif args.command == "accessibility-test":
        accessibility_test(config, args.game)
    elif args.command == "restoration-test":
        restoration_test(config, args.game)
    elif args.command == "proof-test":
        proof_test(config, args.game)
    elif args.command == "daily-test":
        daily_test(config, args.game)
    elif args.command == "persona-test":
        persona_test(config, args.game)
    elif args.command == "gameanalytics-test":
        gameanalytics_test(config, args.game)
    elif args.command == "gameanalytics-build-test":
        gameanalytics_build_test()
    elif args.command == "playtest-recorder-test":
        game_root = posix_game_root(config, args.game)
        command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/playtest_recorder_test.gd
"""
        remote(config, command, 180)
    elif args.command == "recorded-launcher-test":
        recorded_launcher_test(config, args.game)
    elif args.command == "capture-session":
        capture_session(config, args.game)
    elif args.command == "capture-ink-art":
        capture_ink_art(config, args.game)
    elif args.command == "capture-upgrades":
        capture_upgrades(config, args.game)
    elif args.command == "capture-restoration":
        capture_restoration(config, args.game)
    elif args.command == "capture-proof":
        capture_proof(config, args.game)
    elif args.command == "capture-daily":
        capture_daily(config, args.game)
    elif args.command == "capture-cutscenes":
        capture_cutscenes(config, args.game)
    elif args.command == "capture-manual":
        capture_manual(config, args.game)
    elif args.command == "capture-localization":
        capture_localization(config, args.game)
    elif args.command == "balance":
        balance(config, args.game)
    elif args.command == "progression":
        progression(config, args.game)
    elif args.command == "routes":
        routes(config, args.game)
    elif args.command == "soak":
        soak(config, args.game)
    elif args.command == "recorded-soak":
        recorded_soak(config, args.game)
    elif args.command == "release-audit":
        release_audit(config, args.game)
    elif args.command == "export-smoke":
        export_smoke(config, args.game)
    elif args.command == "export":
        export(config, args.game)
    elif args.command == "playtest":
        playtest(config, args.game, args.participant, args.reuse_build)
    elif args.command == "playtest-report":
        playtest_report(config, args.game)
    elif args.command == "restart":
        restart(config, args.game)
    else:
        run(config, args.game)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
