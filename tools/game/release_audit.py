#!/usr/bin/env python3
"""Audit Inkbound source provenance and an optional isolated Windows depot."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GAME_ROOT = REPO_ROOT / "games" / "inkbound_rogue"
RUNTIME_SUFFIXES = {".png", ".wav", ".ogg"}
DEPOT_ALLOWLIST = {"InkboundRogue.exe", "THIRD_PARTY_NOTICES.txt", "version.json"}
ITCH_ALLOWLIST = DEPOT_ALLOWLIST | {"Start-Recorded-Playtest.cmd"}
REQUIRED_ASSET_FIELDS = {
    "id",
    "runtime_path",
    "sha256",
    "media_type",
    "origin",
    "creation_method",
    "generative_ai",
    "live_generation",
    "provenance_record",
    "prompt_record_status",
    "derivation",
    "human_review_status",
    "rights_review_status",
}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_json(path: Path, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"cannot read valid JSON {path}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"JSON root is not an object: {path}")
        return {}
    return value


def audit_source(repo_root: Path, game_root: Path) -> tuple[list[str], dict[str, Any]]:
    errors: list[str] = []
    manifest = _read_json(game_root / "asset-manifest.json", errors)
    entries = manifest.get("assets", [])
    if manifest.get("schema_version") != 3:
        errors.append("asset manifest must use provenance schema 3")
    if not isinstance(entries, list):
        errors.append("asset manifest assets must be a list")
        entries = []
    if manifest.get("asset_count") != len(entries):
        errors.append("asset_count does not match the manifest entry count")

    runtime_assets = {
        "res://" + path.relative_to(game_root).as_posix()
        for path in (game_root / "assets").rglob("*")
        if path.is_file() and path.suffix.lower() in RUNTIME_SUFFIXES
    }
    seen_ids: set[str] = set()
    seen_paths: set[str] = set()
    ai_count = 0
    live_ai_count = 0
    for index, raw_entry in enumerate(entries):
        if not isinstance(raw_entry, dict):
            errors.append(f"asset entry {index} is not an object")
            continue
        missing = REQUIRED_ASSET_FIELDS - raw_entry.keys()
        if missing:
            errors.append(f"asset entry {index} is missing fields: {', '.join(sorted(missing))}")
            continue
        asset_id = str(raw_entry["id"])
        runtime_path = str(raw_entry["runtime_path"])
        if asset_id in seen_ids:
            errors.append(f"duplicate asset id: {asset_id}")
        if runtime_path in seen_paths:
            errors.append(f"duplicate runtime path: {runtime_path}")
        seen_ids.add(asset_id)
        seen_paths.add(runtime_path)
        if not runtime_path.startswith("res://assets/"):
            errors.append(f"asset leaves the runtime asset root: {runtime_path}")
            continue
        asset_path = game_root / runtime_path.removeprefix("res://")
        if not asset_path.is_file():
            errors.append(f"manifest asset is missing: {runtime_path}")
        elif _sha256(asset_path) != str(raw_entry["sha256"]):
            errors.append(f"asset hash drifted: {runtime_path}")
        provenance_path = repo_root / str(raw_entry["provenance_record"])
        if not provenance_path.is_file():
            errors.append(f"provenance record is missing for {asset_id}: {provenance_path}")
        is_ai = raw_entry["generative_ai"] is True
        is_live = raw_entry["live_generation"] is True
        ai_count += int(is_ai)
        live_ai_count += int(is_live)
        if is_live:
            errors.append(f"runtime asset unexpectedly declares live AI generation: {asset_id}")
        if is_ai and raw_entry["creation_method"] != "pre-generated-ai-assisted":
            errors.append(f"AI asset has an ambiguous creation method: {asset_id}")
        if not is_ai and raw_entry["creation_method"] != "deterministic-procedural-generation":
            errors.append(f"non-AI asset is not reproducibly classified: {asset_id}")

    missing_assets = runtime_assets - seen_paths
    extra_assets = seen_paths - runtime_assets
    if missing_assets:
        errors.append("runtime assets missing from manifest: " + ", ".join(sorted(missing_assets)))
    if extra_assets:
        errors.append("manifest paths absent from runtime assets: " + ", ".join(sorted(extra_assets)))

    project_text = (game_root / "project.godot").read_text(encoding="utf-8")
    export_text = (game_root / "export_presets.cfg").read_text(encoding="utf-8")
    if 'renderer/rendering_method="gl_compatibility"' not in project_text:
        errors.append("Windows baseline is not pinned to the GL Compatibility renderer")
    if 'config/features=PackedStringArray("4.2", "GL Compatibility")' not in project_text:
        errors.append("project feature identity does not declare GL Compatibility")
    for exclusion in ("build/**", "tests/**", "design/**", "release/**", "asset-manifest.json", "assets/**/*.md"):
        if exclusion not in export_text:
            errors.append(f"export preset does not exclude development material: {exclusion}")

    version_data = _read_json(game_root / "release" / "version.json", errors)
    version = str(version_data.get("version", ""))
    project_match = re.search(r'^config/version="([^"]+)"$', project_text, re.MULTILINE)
    product_match = re.search(r'^application/product_version="([^"]+)"$', export_text, re.MULTILINE)
    file_match = re.search(r'^application/file_version="([^"]+)"$', export_text, re.MULTILINE)
    if not project_match or project_match.group(1) != version:
        errors.append("project.godot version does not match release/version.json")
    if not product_match or product_match.group(1) != version:
        errors.append("Windows product version does not match release/version.json")
    numeric_version = version.removesuffix("-alpha") + ".0"
    if not file_match or file_match.group(1) != numeric_version:
        errors.append("Windows numeric file version does not match the alpha version")

    app_vdf = (game_root / "release" / "steam_app_build.vdf.example").read_text(encoding="utf-8")
    depot_vdf = (game_root / "release" / "steam_depot_build.vdf.example").read_text(encoding="utf-8")
    if version not in app_vdf or '"setlive" ""' not in app_vdf or '"preview" "0"' not in app_vdf:
        errors.append("Steam app template version/safety defaults drifted")
    if "REPLACE_WITH_STEAM_APP_ID" not in app_vdf or "REPLACE_WITH_WINDOWS_DEPOT_ID" not in app_vdf + depot_vdf:
        errors.append("repository Steam templates contain a live or ambiguous ID")
    if list(game_root.rglob("steam_appid.txt")):
        errors.append("steam_appid.txt must not be committed inside the game project")
    if not (game_root / "release" / "ai-content-disclosure.md").is_file():
        errors.append("AI content disclosure worksheet is missing")
    if not (game_root / "release" / "p1-compatibility-matrix.md").is_file():
        errors.append("P1 compatibility matrix is missing")
    launcher_path = game_root / "release" / "Start-Recorded-Playtest.cmd"
    if not launcher_path.is_file():
        errors.append("recorded-playtest Windows launcher is missing")
    else:
        launcher_text = launcher_path.read_text(encoding="utf-8")
        for required in (
            "INKBOUND_PLAYTEST=1",
            "INKBOUND_PLAYTEST_SESSION=",
            "INKBOUND_PLAYTEST_PARTICIPANT=",
            "INKBOUND_PLAYTEST_DIR=",
            "INKBOUND_LAUNCHER_ACCEPT",
        ):
            if required not in launcher_text:
                errors.append(f"recorded-playtest launcher is missing: {required}")

    summary = {
        "assets": len(entries),
        "ai_pre_generated": ai_count,
        "procedural": len(entries) - ai_count,
        "live_ai": live_ai_count,
        "version": version,
        "renderer": "gl_compatibility",
    }
    return errors, summary


def audit_depot(depot_root: Path, expected_version: str) -> tuple[list[str], dict[str, Any]]:
    errors: list[str] = []
    if not depot_root.is_dir():
        return [f"depot directory does not exist: {depot_root}"], {}
    depot_files = {path.name for path in depot_root.iterdir() if path.is_file()}
    depot_dirs = [path.name for path in depot_root.iterdir() if path.is_dir()]
    if depot_files != DEPOT_ALLOWLIST or depot_dirs:
        errors.append(
            "isolated depot contents differ from allowlist: "
            f"files={sorted(depot_files)} dirs={sorted(depot_dirs)}"
        )
    for name in DEPOT_ALLOWLIST:
        path = depot_root / name
        if not path.is_file() or path.stat().st_size <= 0:
            errors.append(f"depot payload is missing or empty: {name}")
    executable = depot_root / "InkboundRogue.exe"
    if executable.is_file():
        with executable.open("rb") as handle:
            if handle.read(2) != b"MZ":
                errors.append("depot executable does not have a Windows PE signature")
    depot_version = _read_json(depot_root / "version.json", errors)
    if depot_version.get("version") != expected_version:
        errors.append("depot version.json does not match source release identity")
    summary = {
        "depot_files": len(depot_files),
        "depot_bytes": sum((depot_root / name).stat().st_size for name in depot_files),
        "exe_sha256": _sha256(executable) if executable.is_file() else "",
    }
    return errors, summary


def audit_itch_bundle(itch_root: Path, expected_version: str) -> tuple[list[str], dict[str, Any]]:
    errors: list[str] = []
    if not itch_root.is_dir():
        return [f"itch bundle directory does not exist: {itch_root}"], {}
    itch_files = {path.name for path in itch_root.iterdir() if path.is_file()}
    itch_dirs = [path.name for path in itch_root.iterdir() if path.is_dir()]
    if itch_files != ITCH_ALLOWLIST or itch_dirs:
        errors.append(
            "isolated itch bundle contents differ from allowlist: "
            f"files={sorted(itch_files)} dirs={sorted(itch_dirs)}"
        )
    for name in ITCH_ALLOWLIST:
        path = itch_root / name
        if not path.is_file() or path.stat().st_size <= 0:
            errors.append(f"itch payload is missing or empty: {name}")
    executable = itch_root / "InkboundRogue.exe"
    if executable.is_file():
        with executable.open("rb") as handle:
            if handle.read(2) != b"MZ":
                errors.append("itch executable does not have a Windows PE signature")
    itch_version = _read_json(itch_root / "version.json", errors)
    if itch_version.get("version") != expected_version:
        errors.append("itch version.json does not match source release identity")
    launcher = itch_root / "Start-Recorded-Playtest.cmd"
    if launcher.is_file() and b"\r\n" not in launcher.read_bytes():
        errors.append("itch recorded-playtest launcher does not use Windows CRLF lines")
    summary = {
        "itch_files": len(itch_files),
        "itch_bytes": sum((itch_root / name).stat().st_size for name in itch_files),
    }
    return errors, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--game-root", type=Path, default=DEFAULT_GAME_ROOT)
    parser.add_argument("--depot-root", type=Path)
    parser.add_argument("--itch-root", type=Path)
    args = parser.parse_args()
    game_root = args.game_root.resolve()
    errors, summary = audit_source(REPO_ROOT, game_root)
    if args.depot_root is not None:
        depot_errors, depot_summary = audit_depot(args.depot_root.resolve(), str(summary.get("version", "")))
        errors.extend(depot_errors)
        summary.update(depot_summary)
    if args.itch_root is not None:
        itch_errors, itch_summary = audit_itch_bundle(args.itch_root.resolve(), str(summary.get("version", "")))
        errors.extend(itch_errors)
        summary.update(itch_summary)
    if errors:
        print("INKBOUND_RELEASE_AUDIT_FAIL")
        for error in errors:
            print(f"- {error}")
        return 1
    print("INKBOUND_RELEASE_AUDIT_OK " + " ".join(f"{key}={value}" for key, value in summary.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
