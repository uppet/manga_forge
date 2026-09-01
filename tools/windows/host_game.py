#!/usr/bin/env python3
"""Sync, test, export, and launch Manga Forge games on the Windows host."""

from __future__ import annotations

import argparse
from datetime import datetime
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


def load_config() -> dict[str, Any]:
    configured = CONFIG_DIR / "host_config.json"
    path = configured if configured.exists() else CONFIG_DIR / "host_config.example.json"
    return json.loads(path.read_text(encoding="utf-8"))


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
    shutil.copytree(
        source,
        destination,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns(".godot", "build", "*.log"),
    )
    print(f"synced {source} -> {destination}")


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
powershell.exe -NoProfile -Command '$items = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "InkboundRogue.exe" -or $_.Name -like "Godot*.exe" } | Select-Object ProcessId, Name, CreationDate, CommandLine); [pscustomobject]@{ count = $items.Count; processes = $items } | ConvertTo-Json -Depth 4 -Compress'
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
    game_root = posix_game_root(config, game)
    command = godot_resolver(config) + f"""
set -e
GAME='{game_root}'
mkdir -p \"$GAME/build/windows\"
rm -f \"$GAME/build/windows/InkboundRogue.exe\" \"$GAME/build/windows/InkboundRogue.tmp\"
\"$GODOT\" --headless --path \"$GAME\" --export-release 'Windows Desktop' \"$GAME/build/windows/InkboundRogue.exe\"
test -s \"$GAME/build/windows/InkboundRogue.exe\"
cp \"$GAME/release/THIRD_PARTY_NOTICES.txt\" \"$GAME/build/windows/THIRD_PARTY_NOTICES.txt\"
cp \"$GAME/release/version.json\" \"$GAME/build/windows/version.json\"
DEPOT=\"$GAME/build/steam-depot\"
mkdir -p \"$DEPOT\"
rm -f \"$DEPOT/InkboundRogue.exe\" \"$DEPOT/THIRD_PARTY_NOTICES.txt\" \"$DEPOT/version.json\"
cp \"$GAME/build/windows/InkboundRogue.exe\" \"$DEPOT/InkboundRogue.exe\"
cp \"$GAME/build/windows/THIRD_PARTY_NOTICES.txt\" \"$DEPOT/THIRD_PARTY_NOTICES.txt\"
cp \"$GAME/build/windows/version.json\" \"$DEPOT/version.json\"
test \"$(find \"$DEPOT\" -mindepth 1 -maxdepth 1 | wc -l)\" -eq 3
"""
    remote(config, command, 1200)


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
        sync(config, game)
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
    parser.add_argument("command", choices=("probe", "process-status", "sync", "test", "save-test", "pause-test", "session-test", "supply-test", "art-test", "encounter-test", "hazard-test", "loadout-test", "relic-test", "cutscene-test", "manual-test", "localization-test", "cast-test", "audio-test", "combat-feel-test", "accessibility-test", "restoration-test", "proof-test", "daily-test", "persona-test", "playtest-recorder-test", "capture-session", "capture-upgrades", "capture-restoration", "capture-proof", "capture-daily", "capture-cutscenes", "capture-manual", "capture-localization", "balance", "progression", "routes", "soak", "export", "playtest", "playtest-report", "restart", "run"))
    parser.add_argument("--game", default=DEFAULT_GAME)
    parser.add_argument("--participant", default="anonymous", help="anonymous facilitator-assigned playtest code")
    parser.add_argument("--reuse-build", action="store_true", help="launch the existing exported build without sync/export")
    args = parser.parse_args()
    config = load_config()
    if args.command == "sync":
        sync(config, args.game)
    elif args.command == "probe":
        probe(config)
    elif args.command == "process-status":
        process_status(config)
    elif args.command == "test":
        test(config, args.game)
    elif args.command == "save-test":
        save_test(config, args.game)
    elif args.command == "pause-test":
        pause_test(config, args.game)
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
    elif args.command == "playtest-recorder-test":
        game_root = posix_game_root(config, args.game)
        command = godot_resolver(config) + f"""
GAME='{game_root}'
timeout 120s "$GODOT" --headless --path "$GAME" --script res://tests/playtest_recorder_test.gd
"""
        remote(config, command, 180)
    elif args.command == "capture-session":
        capture_session(config, args.game)
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
