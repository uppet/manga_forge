#!/usr/bin/env python3
"""Create and verify the public Windows package with GameAnalytics disabled."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import zipfile


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GAME_ROOT = REPO_ROOT / "games" / "inkbound_rogue"
BUNDLE_FILES = {
    "LastInkwarden.exe",
    "NO_GAMEANALYTICS_BUILD.txt",
    "PRIVACY_NOTICE.txt",
    "Start-Recorded-Playtest.cmd",
    "THIRD_PARTY_NOTICES.txt",
    "version.json",
}
ZIP_TIMESTAMP = (2026, 1, 1, 0, 0, 0)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _assert_no_ga_source(game_root: Path) -> None:
    credentials = (game_root / "scripts" / "gameanalytics_credentials.gd").read_text(
        encoding="utf-8"
    )
    required = (
        "const EMBEDDED := false",
        'const GAME_KEY := ""',
        'const SECRET_KEY := ""',
        'const PROFILE := "none"',
        'const CONFIG_FINGERPRINT := "none"',
    )
    for marker in required:
        if marker not in credentials:
            raise ValueError(f"tracked analytics placeholder is unsafe or drifted: {marker}")
    preset = (game_root / "export_presets.cfg").read_text(encoding="utf-8")
    no_ga_block = re.search(
        r'\[preset\.\d+\]\s*name="Windows Desktop No GA"(?P<body>.*?)(?=\n\[preset\.|\Z)',
        preset,
        re.DOTALL,
    )
    if no_ga_block is None:
        raise ValueError("Windows Desktop No GA export preset is missing")
    if 'custom_features="no_gameanalytics"' not in no_ga_block.group("body"):
        raise ValueError("no-GA export preset does not declare no_gameanalytics")


def _copy_bundle(game_root: Path, executable: Path, bundle_root: Path) -> None:
    if not executable.is_file() or executable.stat().st_size <= 2:
        raise ValueError(f"exported executable is missing or empty: {executable}")
    if executable.read_bytes()[:2] != b"MZ":
        raise ValueError("exported executable does not have a Windows PE signature")
    if bundle_root.exists():
        shutil.rmtree(bundle_root)
    bundle_root.mkdir(parents=True)
    release_root = game_root / "release"
    sources = {
        "LastInkwarden.exe": executable,
        "NO_GAMEANALYTICS_BUILD.txt": release_root / "NO_GAMEANALYTICS_BUILD.txt",
        "PRIVACY_NOTICE.txt": release_root / "PRIVACY_NOTICE_NO_GA.txt",
        "Start-Recorded-Playtest.cmd": release_root / "Start-Recorded-Playtest.cmd",
        "THIRD_PARTY_NOTICES.txt": release_root / "THIRD_PARTY_NOTICES.txt",
        "version.json": release_root / "version.json",
    }
    for name, source in sources.items():
        if not source.is_file():
            raise ValueError(f"release input is missing: {source}")
        shutil.copyfile(source, bundle_root / name)
    if b"\r\n" not in (bundle_root / "Start-Recorded-Playtest.cmd").read_bytes():
        raise ValueError("recorded-playtest launcher must retain Windows CRLF lines")


def _write_deterministic_zip(bundle_root: Path, archive_path: Path) -> None:
    with zipfile.ZipFile(
        archive_path,
        "w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
        strict_timestamps=True,
    ) as archive:
        for name in sorted(BUNDLE_FILES):
            source = bundle_root / name
            info = zipfile.ZipInfo(name, ZIP_TIMESTAMP)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(info, source.read_bytes(), compresslevel=9)


def package_no_ga_release(
    game_root: Path,
    executable: Path,
    output_root: Path,
    godot_version: str,
    source_revision: str,
) -> dict[str, object]:
    game_root = game_root.resolve()
    executable = executable.resolve()
    output_root = output_root.resolve()
    _assert_no_ga_source(game_root)
    version_data = json.loads((game_root / "release" / "version.json").read_text(encoding="utf-8"))
    version = str(version_data.get("version", "")).strip()
    if not version:
        raise ValueError("release/version.json has no version")
    output_root.mkdir(parents=True, exist_ok=True)
    bundle_root = output_root / "bundle"
    _copy_bundle(game_root, executable, bundle_root)
    if {path.name for path in bundle_root.iterdir()} != BUNDLE_FILES:
        raise ValueError("no-GA bundle differs from its exact allowlist")

    archive_name = f"LastInkwarden-{version}-windows-no-ga.zip"
    archive_path = output_root / archive_name
    temporary_archive = output_root / f".{archive_name}.tmp"
    if temporary_archive.exists():
        temporary_archive.unlink()
    _write_deterministic_zip(bundle_root, temporary_archive)
    os.replace(temporary_archive, archive_path)
    archive_hash = sha256_file(archive_path)
    checksum_path = output_root / f"{archive_name}.sha256"
    checksum_path.write_text(f"{archive_hash}  {archive_name}\n", encoding="ascii")

    metadata: dict[str, object] = {
        "product": str(version_data.get("product", "Last Inkwarden")),
        "version": version,
        "platform": "windows-x86_64",
        "release_profile": "no_gameanalytics",
        "gameanalytics_available": False,
        "gameanalytics_embedded": False,
        "godot_version": godot_version,
        "source_revision": source_revision,
        "archive": archive_name,
        "archive_sha256": archive_hash,
        "files": {
            name: {"bytes": (bundle_root / name).stat().st_size, "sha256": sha256_file(bundle_root / name)}
            for name in sorted(BUNDLE_FILES)
        },
    }
    (output_root / "no-ga-build.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return metadata


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--game-root", type=Path, default=DEFAULT_GAME_ROOT)
    parser.add_argument("--executable", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--godot-version", default="unknown")
    parser.add_argument("--source-revision", default=os.environ.get("GITHUB_SHA", "local"))
    args = parser.parse_args()
    metadata = package_no_ga_release(
        args.game_root,
        args.executable,
        args.output_root,
        args.godot_version,
        args.source_revision,
    )
    print(
        "INKBOUND_NO_GA_PACKAGE_OK "
        f"version={metadata['version']} files={len(metadata['files'])} "
        f"archive={metadata['archive']} sha256={metadata['archive_sha256']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
