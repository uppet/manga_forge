#!/usr/bin/env python3
"""Generate deterministic, dependency-free pixel art and audio for Inkbound Rogue."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import struct
import wave
import zlib
from pathlib import Path
from typing import Callable


REPO_ROOT = Path(__file__).resolve().parents[2]
GAME_ROOT = REPO_ROOT / "games" / "inkbound_rogue"
IMAGE_ROOT = GAME_ROOT / "assets" / "generated"
AUDIO_ROOT = GAME_ROOT / "assets" / "audio"
AI_ASSISTED_ASSETS = {
    GAME_ROOT / "assets" / "characters" / "combat-cast-atlas-v1.png": {
        "id": "combat-cast-atlas-v1",
        "provenance_record": "games/inkbound_rogue/assets/characters/combat-cast-atlas-v1.provenance.md",
        "prompt_record_status": "not-retained",
        "derivation": "original combat-cast atlas",
    },
    GAME_ROOT / "assets" / "characters" / "nara-slash-atlas-v1.png": {
        "id": "nara-slash-atlas-v1",
        "provenance_record": "games/inkbound_rogue/assets/characters/nara-slash-atlas-v1.prompt.md",
        "prompt_record_status": "complete",
        "derivation": "identity-reference edit from combat-cast-atlas-v1",
    },
    GAME_ROOT / "assets" / "audio" / "music_menu_hai_mian.ogg": {
        "id": "music-menu-hai-mian",
        "origin": "hai-mian-music-aigc",
        "provenance_record": "games/inkbound_rogue/assets/audio/hai-mian-music.provenance.md",
        "prompt_record_status": "production-brief-retained-in-project-conversation",
        "derivation": "user-provided Hai Mian Music AIGC MP3; silence-trimmed and 1.5-second seam-crossfaded into a runtime Ogg Vorbis loop",
        "human_review_status": "technical-integration-reviewed-demo-owner-approval-recorded",
        "rights_review_status": "project-owner-approved-for-demo-platform-commercial-review-pending",
        "source_commit": "not-applicable-user-supplied",
    },
    GAME_ROOT / "assets" / "audio" / "music_battle_hai_mian.ogg": {
        "id": "music-battle-hai-mian",
        "origin": "hai-mian-music-aigc",
        "provenance_record": "games/inkbound_rogue/assets/audio/hai-mian-music.provenance.md",
        "prompt_record_status": "production-brief-retained-in-project-conversation",
        "derivation": "user-provided Hai Mian Music AIGC MP3; silence-trimmed and 1.5-second seam-crossfaded into a runtime Ogg Vorbis loop",
        "human_review_status": "technical-integration-reviewed-demo-owner-approval-recorded",
        "rights_review_status": "project-owner-approved-for-demo-platform-commercial-review-pending",
        "source_commit": "not-applicable-user-supplied",
    },
    GAME_ROOT / "assets" / "audio" / "music_story_hai_mian.ogg": {
        "id": "music-story-hai-mian",
        "origin": "hai-mian-music-aigc",
        "provenance_record": "games/inkbound_rogue/assets/audio/hai-mian-music.provenance.md",
        "prompt_record_status": "production-brief-retained-in-project-conversation",
        "derivation": "user-provided Hai Mian Music AIGC MP3; silence-trimmed and transcoded into a linear runtime Ogg Vorbis cue",
        "human_review_status": "technical-integration-reviewed-demo-owner-approval-recorded",
        "rights_review_status": "project-owner-approved-for-demo-platform-commercial-review-pending",
        "source_commit": "not-applicable-user-supplied",
    },
    GAME_ROOT / "assets" / "audio" / "music_ending_keep_hai_mian.ogg": {
        "id": "music-ending-keep-hai-mian",
        "origin": "hai-mian-music-aigc",
        "provenance_record": "games/inkbound_rogue/assets/audio/hai-mian-music.provenance.md",
        "prompt_record_status": "production-brief-retained-in-project-conversation",
        "derivation": "user-provided Hai Mian Music AIGC M4A; trailing silence trimmed and transcoded into a linear runtime Ogg Vorbis cue",
        "human_review_status": "technical-integration-reviewed-demo-owner-approval-recorded",
        "rights_review_status": "project-owner-approved-for-demo-platform-commercial-review-pending",
        "source_commit": "not-applicable-user-supplied",
    },
    GAME_ROOT / "assets" / "audio" / "music_ending_rewrite_hai_mian.ogg": {
        "id": "music-ending-rewrite-hai-mian",
        "origin": "hai-mian-music-aigc",
        "provenance_record": "games/inkbound_rogue/assets/audio/hai-mian-music.provenance.md",
        "prompt_record_status": "production-brief-retained-in-project-conversation",
        "derivation": "user-provided Hai Mian Music AIGC MP3; silence-trimmed and transcoded into a linear runtime Ogg Vorbis cue",
        "human_review_status": "technical-integration-reviewed-demo-owner-approval-recorded",
        "rights_review_status": "project-owner-approved-for-demo-platform-commercial-review-pending",
        "source_commit": "not-applicable-user-supplied",
    },
    **{
        GAME_ROOT / "assets" / "audio" / "voice" / filename: {
            "id": "voice-" + Path(filename).stem.replace("_", "-"),
            "origin": "openai-realtime-audio-generation",
            "provenance_record": "games/inkbound_rogue/assets/audio/nara-ink-art-japanese.provenance.md",
            "prompt_record_status": "production-brief-retained-in-project-conversation",
            "derivation": "owner-approved OpenAI Realtime Japanese performance; runtime EQ/peak match, long dramatic silences capped at 160 ms, and pitch-preserving 2.0x tempo",
            "human_review_status": "runtime-and-regression-reviewed-demo-owner-approval-recorded",
            "rights_review_status": "publisher-confirmation-required-before-commercial-release",
            "source_commit": "not-applicable-generated-in-project-conversation",
        }
        for filename in (
            "nara_ink_art_marginalia_jp.wav",
            "nara_ink_art_greatbrush_jp.wav",
            "nara_ink_art_needlepoint_jp.wav",
            "nara_ink_art_seal_caster_jp.wav",
            "nara_ink_art_twin_stroke_jp.wav",
        )
    },
    **{
        GAME_ROOT / "assets" / "cutscenes" / filename: {
            "id": Path(filename).stem,
            "provenance_record": "games/inkbound_rogue/assets/cutscenes/README.md",
            "prompt_record_status": "shared-constraints-only",
            "derivation": "project-directed narrative illustration",
        }
        for filename in (
            "prologue.png",
            "act1-mask-memory-v2.png",
            "revelation.png",
            "finale.png",
            "ending-choice-v2.png",
            "ending-keep-v2.png",
            "ending-rewrite-v2.png",
        )
    },
    **{
        GAME_ROOT / "assets" / "ink_art" / filename: {
            "id": "ink-art-" + Path(filename).stem,
            "origin": "openai-image-generation",
            "provenance_record": "games/inkbound_rogue/assets/ink_art/README.md",
            "prompt_record_status": "shared-constraints-and-weapon-brief-retained",
            "derivation": "runtime-sized derivative of the approved weapon-specific Ink Art preview source",
            "human_review_status": "preview-approved-runtime-integration-review-pending",
            "rights_review_status": "publisher-confirmation-required-before-commercial-release",
            "source_commit": "not-applicable-generated-in-project-conversation",
        }
        for filename in (
            "marginalia-cutin.png",
            "marginalia-startup.png",
            "greatbrush-cutin.png",
            "greatbrush-startup.png",
            "needlepoint-cutin.png",
            "needlepoint-startup.png",
            "seal-caster-cutin.png",
            "seal-caster-startup.png",
            "twin-stroke-cutin.png",
            "twin-stroke-startup.png",
        )
    },
}

INK = (20, 18, 24, 255)
DEEP_INK = (8, 7, 11, 255)
PAPER = (239, 226, 196, 255)
WHITE = (255, 248, 224, 255)
CRIMSON = (211, 48, 55, 255)
DARK_RED = (112, 24, 32, 255)
STEEL = (150, 170, 176, 255)
GOLD = (242, 179, 68, 255)
DANGER_BLUE = (53, 91, 190, 255)
DANGER_CYAN = (91, 225, 245, 255)
TRANSPARENT = (0, 0, 0, 0)


class Canvas:
    def __init__(self, width: int, height: int, fill: tuple[int, int, int, int] = TRANSPARENT) -> None:
        self.width = width
        self.height = height
        self.pixels = [fill] * (width * height)

    def pixel(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y * self.width + x] = color

    def rect(self, x: int, y: int, width: int, height: int, color: tuple[int, int, int, int]) -> None:
        for py in range(y, y + height):
            for px in range(x, x + width):
                self.pixel(px, py, color)

    def hline(self, x: int, y: int, width: int, color: tuple[int, int, int, int]) -> None:
        self.rect(x, y, width, 1, color)

    def vline(self, x: int, y: int, height: int, color: tuple[int, int, int, int]) -> None:
        self.rect(x, y, 1, height, color)

    def png_bytes(self) -> bytes:
        raw = bytearray()
        for y in range(self.height):
            raw.append(0)
            for pixel in self.pixels[y * self.width : (y + 1) * self.width]:
                raw.extend(pixel)
        signature = b"\x89PNG\r\n\x1a\n"

        def chunk(kind: bytes, data: bytes) -> bytes:
            payload = kind + data
            return struct.pack(">I", len(data)) + payload + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF)

        header = struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0)
        return signature + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")


def player_sprite() -> Canvas:
    c = Canvas(16, 16)
    c.rect(5, 2, 6, 2, INK)
    c.rect(4, 4, 8, 4, PAPER)
    c.pixel(5, 5, INK)
    c.pixel(10, 5, INK)
    c.hline(6, 7, 4, DARK_RED)
    c.rect(4, 8, 8, 5, INK)
    c.rect(5, 9, 6, 3, WHITE)
    c.rect(4, 9, 2, 2, CRIMSON)
    c.rect(10, 11, 4, 1, STEEL)
    c.pixel(14, 10, WHITE)
    c.rect(4, 13, 3, 2, INK)
    c.rect(9, 13, 3, 2, INK)
    return c


def enemy_sprite(accent: tuple[int, int, int, int] = PAPER) -> Canvas:
    c = Canvas(16, 16)
    c.rect(4, 2, 8, 2, INK)
    c.rect(3, 4, 10, 7, accent)
    c.rect(4, 5, 2, 2, DEEP_INK)
    c.rect(10, 5, 2, 2, DEEP_INK)
    c.hline(6, 9, 4, DEEP_INK)
    c.rect(4, 11, 8, 3, DARK_RED)
    c.rect(3, 13, 4, 2, INK)
    c.rect(9, 13, 4, 2, INK)
    return c


def brute_sprite() -> Canvas:
    c = Canvas(20, 20)
    c.rect(4, 2, 12, 3, INK)
    c.rect(3, 5, 14, 9, PAPER)
    c.rect(5, 7, 3, 2, DEEP_INK)
    c.rect(12, 7, 3, 2, DEEP_INK)
    c.rect(6, 11, 8, 2, DARK_RED)
    c.rect(2, 13, 16, 4, INK)
    c.rect(0, 13, 3, 4, CRIMSON)
    c.rect(17, 13, 3, 4, CRIMSON)
    c.rect(4, 17, 5, 3, INK)
    c.rect(11, 17, 5, 3, INK)
    return c


def scribe_sprite() -> Canvas:
    c = enemy_sprite(GOLD)
    c.rect(1, 1, 9, 2, INK)
    c.rect(10, 0, 1, 6, WHITE)
    c.pixel(11, 0, CRIMSON)
    c.rect(12, 10, 4, 1, GOLD)
    return c


def splitter_sprite() -> Canvas:
    c = enemy_sprite(STEEL)
    for x, y in ((7, 4), (8, 5), (7, 6), (8, 7), (6, 8), (5, 9)):
        c.pixel(x, y, CRIMSON)
    c.rect(1, 11, 3, 2, PAPER)
    c.rect(12, 11, 3, 2, PAPER)
    return c


def leech_sprite() -> Canvas:
    c = Canvas(16, 16)
    c.rect(3, 3, 10, 9, DARK_RED)
    c.rect(5, 2, 6, 2, INK)
    c.rect(4, 5, 8, 5, CRIMSON)
    c.rect(5, 6, 2, 2, WHITE)
    c.rect(9, 6, 2, 2, WHITE)
    c.hline(6, 10, 4, DEEP_INK)
    c.pixel(6, 11, WHITE)
    c.pixel(9, 11, WHITE)
    c.rect(2, 12, 4, 2, INK)
    c.rect(10, 12, 4, 2, INK)
    return c


def warden_sprite() -> Canvas:
    c = Canvas(24, 24)
    c.rect(6, 2, 12, 3, INK)
    c.rect(4, 5, 16, 12, STEEL)
    c.rect(6, 7, 4, 3, DEEP_INK)
    c.rect(14, 7, 4, 3, DEEP_INK)
    c.rect(8, 13, 8, 2, CRIMSON)
    c.rect(2, 10, 4, 9, INK)
    c.rect(18, 10, 4, 9, INK)
    c.rect(0, 9, 3, 3, GOLD)
    c.rect(21, 9, 3, 3, GOLD)
    c.rect(5, 17, 14, 4, DARK_RED)
    c.rect(5, 21, 5, 3, INK)
    c.rect(14, 21, 5, 3, INK)
    return c


def censor_sprite() -> Canvas:
    c = Canvas(20, 20)
    c.rect(5, 2, 10, 3, INK)
    c.rect(4, 5, 12, 10, PAPER)
    c.rect(6, 7, 3, 2, DEEP_INK)
    c.rect(12, 7, 3, 2, DEEP_INK)
    c.rect(7, 12, 7, 2, DARK_RED)
    c.rect(1, 4, 4, 13, STEEL)
    c.rect(0, 7, 2, 7, WHITE)
    c.rect(5, 15, 11, 3, INK)
    c.rect(5, 18, 4, 2, DEEP_INK)
    c.rect(12, 18, 4, 2, DEEP_INK)
    return c


def errata_sprite() -> Canvas:
    c = Canvas(16, 16)
    c.rect(5, 1, 6, 3, STEEL)
    c.rect(3, 4, 10, 7, DEEP_INK)
    c.rect(4, 5, 8, 5, (92, 70, 112, 255))
    c.pixel(5, 6, WHITE)
    c.pixel(10, 6, WHITE)
    c.rect(6, 9, 4, 1, CRIMSON)
    c.rect(2, 11, 12, 2, INK)
    c.rect(1, 13, 4, 1, STEEL)
    c.rect(6, 14, 4, 1, STEEL)
    c.rect(11, 12, 4, 1, STEEL)
    return c


def archivist_sprite() -> Canvas:
    c = Canvas(20, 20)
    c.rect(5, 2, 10, 3, GOLD)
    c.rect(4, 5, 12, 9, PAPER)
    c.rect(6, 7, 3, 2, DEEP_INK)
    c.rect(12, 7, 3, 2, DEEP_INK)
    c.rect(7, 11, 6, 2, GOLD)
    c.rect(2, 8, 3, 9, INK)
    c.rect(15, 8, 3, 9, INK)
    c.rect(0, 6, 4, 3, WHITE)
    c.rect(16, 6, 4, 3, WHITE)
    c.vline(2, 5, 10, CRIMSON)
    c.vline(17, 5, 10, CRIMSON)
    c.rect(5, 14, 10, 4, INK)
    c.rect(5, 18, 4, 2, DEEP_INK)
    c.rect(11, 18, 4, 2, DEEP_INK)
    return c


def blot_sprite() -> Canvas:
    c = Canvas(20, 20)
    c.rect(6, 3, 8, 2, DARK_RED)
    c.rect(4, 5, 12, 10, INK)
    c.rect(2, 8, 16, 6, DARK_RED)
    c.rect(5, 6, 10, 8, CRIMSON)
    c.rect(7, 8, 2, 2, WHITE)
    c.rect(12, 8, 2, 2, WHITE)
    c.rect(8, 12, 5, 1, DEEP_INK)
    for x, y in ((1, 15), (5, 17), (10, 16), (15, 18), (18, 14)):
        c.rect(x, y, 2, 2, DARK_RED)
    return c


def duelist_sprite() -> Canvas:
    c = Canvas(16, 16)
    c.rect(5, 1, 6, 2, INK)
    c.rect(4, 3, 8, 6, PAPER)
    c.pixel(5, 5, DEEP_INK)
    c.pixel(10, 5, DEEP_INK)
    c.rect(6, 8, 4, 1, CRIMSON)
    c.rect(5, 9, 6, 5, INK)
    c.vline(13, 2, 11, STEEL)
    c.pixel(14, 1, WHITE)
    c.hline(11, 12, 4, GOLD)
    c.rect(3, 14, 4, 2, DEEP_INK)
    c.rect(9, 14, 4, 2, DEEP_INK)
    return c


def boss_sprite() -> Canvas:
    c = Canvas(32, 32)
    c.rect(8, 3, 16, 3, INK)
    c.rect(6, 6, 20, 14, PAPER)
    c.rect(9, 9, 4, 3, DEEP_INK)
    c.rect(19, 9, 4, 3, DEEP_INK)
    c.rect(12, 16, 8, 2, DARK_RED)
    c.rect(4, 20, 24, 8, INK)
    c.rect(1, 19, 5, 8, CRIMSON)
    c.rect(26, 19, 5, 8, CRIMSON)
    c.rect(8, 28, 6, 4, INK)
    c.rect(18, 28, 6, 4, INK)
    for x, y in ((3, 7), (28, 8), (2, 15), (29, 16)):
        c.rect(x, y, 2, 2, GOLD)
    return c


def binder_sprite() -> Canvas:
    c = Canvas(32, 32)
    c.rect(9, 2, 14, 4, DEEP_INK)
    c.rect(7, 6, 18, 13, PAPER)
    c.rect(10, 9, 4, 3, DEEP_INK)
    c.rect(18, 9, 4, 3, DEEP_INK)
    c.vline(16, 7, 12, GOLD)
    c.rect(5, 19, 22, 9, INK)
    c.rect(1, 15, 6, 4, GOLD)
    c.rect(25, 15, 6, 4, GOLD)
    for x in range(2, 31, 4):
        c.pixel(x, 20 + (x % 3), CRIMSON)
    c.rect(8, 28, 6, 4, DEEP_INK)
    c.rect(18, 28, 6, 4, DEEP_INK)
    return c


def author_sprite() -> Canvas:
    c = Canvas(40, 40)
    c.rect(13, 3, 14, 4, DEEP_INK)
    c.rect(10, 7, 20, 15, PAPER)
    c.rect(13, 10, 4, 3, DEEP_INK)
    c.rect(23, 10, 4, 3, DEEP_INK)
    c.vline(20, 8, 13, CRIMSON)
    c.rect(7, 22, 26, 12, INK)
    for x, y in ((2, 16), (34, 16), (0, 25), (36, 25), (4, 31), (32, 31)):
        c.rect(x, y, 5, 2, GOLD)
        c.rect(x + 1, y + 2, 2, 5, CRIMSON)
    c.rect(11, 34, 7, 6, DEEP_INK)
    c.rect(22, 34, 7, 6, DEEP_INK)
    return c


def orb_sprite() -> Canvas:
    c = Canvas(8, 8)
    c.rect(2, 1, 4, 6, CRIMSON)
    c.rect(1, 2, 6, 4, CRIMSON)
    c.rect(3, 2, 2, 3, WHITE)
    c.pixel(2, 5, DARK_RED)
    c.pixel(5, 5, DARK_RED)
    return c


def health_sprite() -> Canvas:
    c = Canvas(8, 8)
    c.rect(1, 2, 6, 4, PAPER)
    c.rect(2, 1, 2, 6, PAPER)
    c.rect(4, 2, 2, 4, PAPER)
    c.rect(3, 2, 2, 4, CRIMSON)
    c.rect(2, 3, 4, 2, CRIMSON)
    return c


def shard_sprite() -> Canvas:
    c = Canvas(8, 8)
    c.pixel(3, 0, GOLD)
    c.rect(2, 1, 4, 2, GOLD)
    c.rect(1, 3, 6, 2, CRIMSON)
    c.rect(2, 5, 4, 2, DARK_RED)
    c.pixel(4, 7, DARK_RED)
    c.rect(3, 2, 2, 3, WHITE)
    return c


def relic_sprite() -> Canvas:
    c = Canvas(12, 12)
    c.rect(2, 1, 8, 10, GOLD)
    c.rect(3, 2, 6, 8, INK)
    c.rect(4, 3, 4, 6, PAPER)
    c.rect(5, 4, 2, 4, CRIMSON)
    c.pixel(1, 3, WHITE)
    c.pixel(10, 8, WHITE)
    return c


def bomb_pickup_sprite() -> Canvas:
    c = Canvas(12, 12)
    c.rect(3, 4, 7, 7, DEEP_INK)
    c.rect(2, 6, 9, 4, CRIMSON)
    c.rect(5, 2, 3, 3, GOLD)
    c.pixel(8, 1, WHITE)
    c.pixel(10, 0, CRIMSON)
    return c


def magnet_pickup_sprite() -> Canvas:
    c = Canvas(12, 12)
    c.rect(2, 2, 3, 7, CRIMSON)
    c.rect(7, 2, 3, 7, STEEL)
    c.rect(3, 8, 6, 3, GOLD)
    c.rect(3, 2, 2, 2, WHITE)
    c.rect(7, 2, 2, 2, WHITE)
    return c


def frenzy_pickup_sprite() -> Canvas:
    c = Canvas(12, 12)
    c.rect(5, 0, 2, 5, GOLD)
    c.rect(3, 3, 6, 7, CRIMSON)
    c.rect(1, 7, 10, 3, DARK_RED)
    c.rect(4, 5, 4, 4, WHITE)
    c.pixel(5, 11, GOLD)
    return c


def ward_pickup_sprite() -> Canvas:
    c = Canvas(12, 12)
    c.rect(2, 1, 8, 7, STEEL)
    c.rect(3, 2, 6, 5, PAPER)
    c.rect(4, 4, 4, 5, GOLD)
    c.rect(5, 3, 2, 7, CRIMSON)
    c.rect(4, 9, 4, 2, DEEP_INK)
    return c


def hourglass_pickup_sprite() -> Canvas:
    c = Canvas(12, 12)
    c.hline(2, 1, 8, GOLD)
    c.hline(2, 10, 8, GOLD)
    c.rect(3, 2, 6, 2, STEEL)
    c.rect(4, 4, 4, 4, PAPER)
    c.rect(3, 8, 6, 2, STEEL)
    c.pixel(5, 5, CRIMSON)
    c.pixel(6, 6, CRIMSON)
    return c


def projectile_sprite() -> Canvas:
    c = Canvas(8, 8)
    # Hostile shots intentionally avoid the crimson/ivory pickup family. The
    # dark-edged cyan diamond also remains identifiable without color alone.
    c.rect(3, 0, 2, 8, DEEP_INK)
    c.rect(2, 1, 4, 6, DEEP_INK)
    c.rect(1, 2, 6, 4, DEEP_INK)
    c.rect(0, 3, 8, 2, DEEP_INK)
    c.rect(3, 1, 2, 6, DANGER_BLUE)
    c.rect(2, 2, 4, 4, DANGER_BLUE)
    c.rect(1, 3, 6, 2, DANGER_CYAN)
    c.rect(3, 2, 2, 4, DANGER_CYAN)
    c.rect(3, 3, 2, 2, WHITE)
    return c


def floor_tile() -> Canvas:
    c = Canvas(16, 16, INK)
    c.hline(0, 0, 16, DEEP_INK)
    c.vline(0, 0, 16, DEEP_INK)
    for x, y in ((3, 4), (12, 2), (8, 11), (14, 14)):
        c.pixel(x, y, (39, 34, 43, 255))
    c.hline(4, 14, 4, (31, 28, 34, 255))
    return c


def icon_sprite() -> Canvas:
    c = Canvas(32, 32, DEEP_INK)
    c.rect(3, 3, 26, 26, PAPER)
    c.rect(5, 5, 22, 22, INK)
    c.rect(7, 7, 18, 18, DARK_RED)
    c.rect(9, 8, 4, 16, WHITE)
    c.rect(13, 7, 12, 4, WHITE)
    c.rect(13, 18, 12, 4, WHITE)
    c.rect(20, 11, 4, 7, CRIMSON)
    return c


def wav_bytes(duration: float, sample_fn: Callable[[float, random.Random], float]) -> bytes:
    sample_rate = 22050
    frame_count = int(duration * sample_rate)
    rng = random.Random(613)
    frames = bytearray()
    for i in range(frame_count):
        t = i / sample_rate
        value = max(-1.0, min(1.0, sample_fn(t, rng)))
        frames.extend(struct.pack("<h", int(value * 32767)))
    import io

    buffer = io.BytesIO()
    with wave.open(buffer, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)
        wav.writeframes(bytes(frames))
    return buffer.getvalue()


def sound_assets() -> dict[str, bytes]:
    def loop_guard(t: float, duration: float) -> float:
        edge = min(1.0, t / 0.055, max(0.0, duration - t) / 0.055)
        return edge * edge * (3.0 - 2.0 * edge)

    def music_score(
        t: float,
        rng: random.Random,
        state: dict[str, float],
        duration: float,
        root: float,
        rate: float,
        notes: tuple[float, ...],
        pattern: tuple[int, ...],
        intensity: float,
        boss: bool = False,
    ) -> float:
        """Build a dry paper/wood/brush score with long-section variation."""

        step = int(t * rate)
        phase = (t * rate) % 1.0
        local_t = phase / rate
        section = int(t / 4.0) % 8
        section_pitch = (1.0, 1.0, 1.05946, 0.94387, 1.0, 0.89090, 1.12246, 1.0)[section]
        note = notes[step % len(notes)] * section_pitch

        pluck_attack = min(1.0, local_t / 0.012)
        pluck_envelope = pluck_attack * math.exp(-local_t * (7.5 + rate * 0.7))
        pluck = pluck_envelope * (
            math.sin(math.tau * note * local_t)
            + 0.34 * math.sin(math.tau * note * 2.01 * local_t)
            + 0.12 * math.sin(math.tau * note * 3.97 * local_t)
        )

        raw = rng.uniform(-1.0, 1.0)
        state["paper"] += (raw - state["paper"]) * 0.31
        state["brush"] += (state["paper"] - state["brush"]) * 0.018
        paper_crack = raw - state["paper"]
        brush_body = state["paper"] - state["brush"]
        struck = pattern[step % len(pattern)]
        percussion_envelope = math.exp(-phase * (19.0 if boss else 25.0)) if struck else 0.0
        body_frequency = root * (0.72 if boss else 0.92)
        percussion = percussion_envelope * (
            paper_crack * (0.52 + 0.16 * struck)
            + brush_body * 0.36
            + math.sin(math.tau * body_frequency * local_t) * (0.32 + 0.1 * struck)
        )

        brush_gate = math.sin(math.pi * ((t * (0.5 if boss else 0.25)) % 1.0)) ** 2
        brush = brush_body * brush_gate * (0.18 if boss else 0.12)
        drone_motion = 0.82 + 0.18 * math.sin(math.tau * t / 8.0)
        drone = drone_motion * (
            math.sin(math.tau * root * t) * 0.095
            + math.sin(math.tau * root * 1.5 * t) * 0.032
        )
        press = 0.0
        if boss and struck >= 2:
            press = percussion_envelope * math.sin(math.tau * root * 0.48 * local_t) * 0.24
        arrangement = 0.78 + (0.12 if section in (2, 3, 6) else 0.0) - (0.08 if section == 4 else 0.0)
        return loop_guard(t, duration) * intensity * arrangement * (drone + pluck * 0.2 + percussion * 0.34 + brush + press)

    def blade_cut(
        duration: float,
        air_weight: float,
        edge_weight: float,
        body_frequency: float,
        contact_ratio: float,
    ) -> Callable[[float, random.Random], float]:
        """Layer a dry blade whoosh without letting a swept oscillator lead it."""

        state = {"fast": 0.0, "slow": 0.0}

        def sample(t: float, rng: random.Random) -> float:
            progress = min(1.0, t / duration)
            raw = rng.uniform(-1.0, 1.0)
            state["fast"] += (raw - state["fast"]) * 0.38
            state["slow"] += (state["fast"] - state["slow"]) * 0.055
            blade_air = state["fast"] - state["slow"]
            edge_air = raw - state["fast"]

            motion = min(1.0, t / max(0.008, duration * 0.075)) * max(0.0, 1.0 - progress) ** 1.35
            contact_time = duration * contact_ratio
            edge_width = max(0.0035, duration * 0.027)
            contact = math.exp(-((t - contact_time) / edge_width) ** 2)
            body = math.exp(-max(0.0, t - contact_time) * 34.0) if t >= contact_time else 0.0
            edge_chirp = (edge_air - blade_air) * contact
            handle_thump = math.sin(math.tau * body_frequency * (t - contact_time)) * body
            return (
                motion * (blade_air * air_weight + edge_air * air_weight * 0.28)
                + contact * edge_air * edge_weight
                + edge_chirp * edge_weight * 0.22
                + handle_thump * 0.17
            )

        return sample

    slash = blade_cut(0.24, 0.74, 0.36, 88.0, 0.45)
    slash_heavy = blade_cut(0.36, 0.92, 0.44, 56.0, 0.52)
    slash_light = blade_cut(0.15, 0.58, 0.46, 112.0, 0.40)

    def noise_state() -> dict[str, float]:
        return {"fast": 0.0, "slow": 0.0}

    def material_noise(
        state: dict[str, float],
        rng: random.Random,
        fast_rate: float = 0.34,
        slow_rate: float = 0.045,
    ) -> tuple[float, float, float]:
        """Return dry edge, cloth/paper body, and low material movement."""

        raw = rng.uniform(-1.0, 1.0)
        state["fast"] += (raw - state["fast"]) * fast_rate
        state["slow"] += (state["fast"] - state["slow"]) * slow_rate
        return raw - state["fast"], state["fast"] - state["slow"], state["slow"]

    def strike(t: float, at: float, width: float) -> float:
        return math.exp(-((t - at) / width) ** 2)

    def tail(t: float, at: float, rate: float) -> float:
        return math.exp(-(t - at) * rate) if t >= at else 0.0

    hit_state = noise_state()

    def hit(t: float, rng: random.Random) -> float:
        edge, body, low = material_noise(hit_state, rng, 0.43, 0.07)
        crack = math.exp(-t * 88.0)
        weight = math.exp(-t * 24.0)
        resonance = math.sin(math.tau * 82.0 * t) * 0.18 + math.sin(math.tau * 127.0 * t) * 0.07
        return crack * edge * 0.58 + weight * body * 0.62 + weight * low * 0.18 + weight * resonance

    dash_state = noise_state()

    def dash(t: float, rng: random.Random) -> float:
        edge, cloth, low = material_noise(dash_state, rng, 0.28, 0.035)
        whoosh = math.sin(math.pi * min(1.0, t / 0.22)) ** 0.7
        foot = tail(t, 0.018, 42.0)
        flap = strike(t, 0.095, 0.018) + strike(t, 0.155, 0.022) * 0.6
        return whoosh * (cloth * 0.72 + edge * 0.13) + foot * math.sin(math.tau * 66.0 * t) * 0.22 + flap * low * 0.36

    pickup_state = noise_state()

    def pickup(t: float, rng: random.Random) -> float:
        edge, paper, _low = material_noise(pickup_state, rng, 0.42, 0.055)
        token = tail(t, 0.025, 18.0)
        catch = strike(t, 0.025, 0.008) + strike(t, 0.135, 0.012) * 0.48
        resonance = math.sin(math.tau * 196.0 * t) + math.sin(math.tau * 293.0 * t) * 0.22
        return catch * edge * 0.36 + token * resonance * 0.16 + max(0.0, 1.0 - t / 0.24) * paper * 0.24

    level_state = noise_state()

    def level_up(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(level_state, rng, 0.27, 0.026)
        page = math.sin(math.pi * min(1.0, t / 0.55)) ** 1.25
        first = tail(t, 0.035, 8.5)
        second = tail(t, 0.285, 10.0)
        resonance = first * (math.sin(math.tau * 110.0 * t) * 0.19 + math.sin(math.tau * 165.0 * t) * 0.08)
        resonance += second * math.sin(math.tau * 82.5 * (t - 0.285)) * 0.14
        return page * (paper * 0.34 + low * 0.14) + strike(t, 0.035, 0.012) * edge * 0.35 + resonance

    hurt_state = noise_state()

    def hurt(t: float, rng: random.Random) -> float:
        edge, cloth, low = material_noise(hurt_state, rng, 0.39, 0.065)
        impact = math.exp(-t * 42.0)
        body = math.exp(-t * 14.0)
        resonance = math.sin(math.tau * 62.0 * t) * 0.27 + math.sin(math.tau * 93.0 * t) * 0.11
        return impact * edge * 0.42 + body * cloth * 0.46 + body * low * 0.2 + body * resonance

    relic_state = noise_state()

    def relic(t: float, rng: random.Random) -> float:
        edge, wax, low = material_noise(relic_state, rng, 0.3, 0.032)
        contact = strike(t, 0.028, 0.01)
        ring = tail(t, 0.028, 6.8)
        resonance = math.sin(math.tau * 146.0 * (t - 0.028)) * 0.2
        resonance += math.sin(math.tau * 219.0 * (t - 0.028)) * 0.08
        resonance += math.sin(math.tau * 287.0 * (t - 0.028)) * 0.035
        return contact * (edge * 0.48 + low * 0.2) + ring * resonance + max(0.0, 1.0 - t / 0.52) * wax * 0.17

    boss_warning_state = noise_state()

    def boss_warning(t: float, rng: random.Random) -> float:
        edge, body, low = material_noise(boss_warning_state, rng, 0.22, 0.018)
        first = tail(t, 0.02, 8.0)
        second = tail(t, 0.37, 8.5)
        drum = first * (math.sin(math.tau * 48.0 * t) * 0.38 + math.sin(math.tau * 72.0 * t) * 0.12)
        drum += second * math.sin(math.tau * 43.0 * (t - 0.37)) * 0.36
        attacks = strike(t, 0.02, 0.012) + strike(t, 0.37, 0.014)
        return drum + attacks * edge * 0.32 + max(0.0, 1.0 - t / 0.75) * (body * 0.16 + low * 0.13)

    seal_state = {"paper": 0.0, "ink": 0.0}

    def seal_cast(t: float, rng: random.Random) -> float:
        raw = rng.uniform(-1.0, 1.0)
        seal_state["paper"] += (raw - seal_state["paper"]) * 0.42
        seal_state["ink"] += (seal_state["paper"] - seal_state["ink"]) * 0.052
        snap = math.exp(-t * 92.0) * (raw - seal_state["paper"])
        drag_env = min(1.0, t / 0.018) * max(0.0, 1.0 - t / 0.28) ** 1.6
        paper_drag = seal_state["paper"] - seal_state["ink"]
        stamp = strike(t, 0.19, 0.016)
        stamp_tail = tail(t, 0.19, 24.0)
        return snap * 0.5 + drag_env * paper_drag * 0.62 + stamp * raw * 0.31 + stamp_tail * math.sin(math.tau * 78.0 * (t - 0.19)) * 0.2

    ink_art_state = noise_state()

    def ink_art(t: float, rng: random.Random) -> float:
        edge, wet, low = material_noise(ink_art_state, rng, 0.2, 0.018)
        draw = math.sin(math.pi * min(1.0, t / 0.47)) ** 1.4 if t <= 0.47 else 0.0
        release = tail(t, 0.45, 11.0)
        impact = strike(t, 0.45, 0.018)
        resonance = release * (math.sin(math.tau * 58.0 * (t - 0.45)) * 0.3 + math.sin(math.tau * 87.0 * (t - 0.45)) * 0.1)
        return draw * (wet * 0.5 + low * 0.25 + edge * 0.06) + impact * edge * 0.44 + resonance

    palimpsest_state = noise_state()

    def ink_art_palimpsest(t: float, rng: random.Random) -> float:
        edge, brush, low = material_noise(palimpsest_state, rng, 0.3, 0.028)
        circle = math.sin(math.pi * min(1.0, t / 0.46)) ** 1.2 if t <= 0.46 else 0.0
        cuts = sum(strike(t, at, 0.012) for at in (0.025, 0.13, 0.235, 0.34))
        body = tail(t, 0.025, 7.5)
        resonance = body * (math.sin(math.tau * 68.0 * t) * 0.18 + math.sin(math.tau * 102.0 * t) * 0.065)
        return circle * (brush * 0.42 + low * 0.17) + cuts * edge * 0.34 + resonance

    final_period_state = noise_state()

    def ink_art_final_period(t: float, rng: random.Random) -> float:
        edge, bristle, low = material_noise(final_period_state, rng, 0.24, 0.02)
        impact = math.exp(-t * 58.0)
        debris = math.exp(-t * 7.2)
        thump = debris * (
            math.sin(math.tau * 42.0 * t) * 0.46
            + math.sin(math.tau * 63.0 * t) * 0.17
            + math.sin(math.tau * 91.0 * t) * 0.06
        )
        settling = strike(t, 0.24, 0.035) + strike(t, 0.43, 0.05) * 0.65
        return impact * edge * 0.5 + debris * (bristle * 0.5 + low * 0.25) + settling * bristle * 0.38 + thump

    red_line_state = noise_state()

    def ink_art_red_line(t: float, rng: random.Random) -> float:
        edge, air, low = material_noise(red_line_state, rng, 0.52, 0.095)
        puncture = math.exp(-t * 105.0)
        passage = math.sin(math.pi * min(1.0, t / 0.24)) * math.exp(-t * 5.5)
        metal = tail(t, 0.012, 20.0) * (
            math.sin(math.tau * 318.0 * t) * 0.15
            + math.sin(math.tau * 477.0 * t) * 0.05
        )
        brake = strike(t, 0.27, 0.026)
        return puncture * edge * 0.62 + passage * (air * 0.48 + low * 0.08) + metal + brake * (edge * 0.32 + low * 0.18)

    seal_storm_state = noise_state()

    def ink_art_seal_storm(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(seal_storm_state, rng, 0.39, 0.055)
        stamp_attack = math.exp(-t * 82.0)
        stamp_body = math.exp(-t * 12.0)
        radial = 0.0
        for index in range(12):
            at = 0.08 + float(index) * 0.042
            radial += strike(t, at, 0.009 + float(index) * 0.0004) * (1.0 - float(index) * 0.035)
        resonance = stamp_body * (
            math.sin(math.tau * 74.0 * t) * 0.22
            + math.sin(math.tau * 111.0 * t) * 0.08
        )
        return stamp_attack * edge * 0.46 + stamp_body * (paper * 0.28 + low * 0.17) + radial * edge * 0.17 + resonance

    cross_revision_state = noise_state()

    def ink_art_cross_revision(t: float, rng: random.Random) -> float:
        edge, blade_air, low = material_noise(cross_revision_state, rng, 0.43, 0.07)
        first = strike(t, 0.025, 0.014)
        second = strike(t, 0.19, 0.016)
        crossed = strike(t, 0.235, 0.028)
        tail_body = tail(t, 0.19, 10.0)
        resonance = tail_body * (
            math.sin(math.tau * 116.0 * (t - 0.19)) * 0.16
            + math.sin(math.tau * 174.0 * (t - 0.19)) * 0.055
        )
        return (first + second * 0.92) * edge * 0.48 + crossed * (blade_air * 0.42 + low * 0.18) + resonance

    enemy_cast_state = noise_state()

    def enemy_cast(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(enemy_cast_state, rng, 0.46, 0.07)
        snaps = strike(t, 0.025, 0.009) + strike(t, 0.145, 0.012) * 0.72
        warning = tail(t, 0.025, 10.0) * math.sin(math.tau * 96.0 * (t - 0.025))
        return snaps * edge * 0.43 + max(0.0, 1.0 - t / 0.32) * paper * 0.26 + warning * 0.17 + low * 0.08

    enemy_dash_state = noise_state()

    def enemy_dash(t: float, rng: random.Random) -> float:
        edge, cloth, low = material_noise(enemy_dash_state, rng, 0.31, 0.035)
        breath = math.sin(math.pi * min(1.0, t / 0.3)) ** 0.75
        step = tail(t, 0.035, 30.0)
        return breath * (cloth * 0.58 + edge * 0.12) + step * math.sin(math.tau * 71.0 * (t - 0.035)) * 0.25 + strike(t, 0.035, 0.012) * low * 0.3

    teleport_state = noise_state()

    def teleport(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(teleport_state, rng, 0.2, 0.015)
        suction = math.sin(math.pi * min(1.0, t / 0.43)) ** 1.3 if t <= 0.43 else 0.0
        close = tail(t, 0.41, 22.0)
        hollow = close * (math.sin(math.tau * 83.0 * (t - 0.41)) * 0.22 + math.sin(math.tau * 124.0 * (t - 0.41)) * 0.08)
        return suction * (paper * 0.42 + low * 0.2 + edge * 0.05) + strike(t, 0.41, 0.015) * edge * 0.35 + hollow

    parry_state = noise_state()

    def parry(t: float, rng: random.Random) -> float:
        edge, metal, _low = material_noise(parry_state, rng, 0.5, 0.11)
        attack = math.exp(-t * 110.0)
        ring = math.exp(-t * 22.0)
        modes = math.sin(math.tau * 390.0 * t) * 0.3 + math.sin(math.tau * 655.0 * t) * 0.13 + math.sin(math.tau * 910.0 * t) * 0.055
        return attack * edge * 0.5 + ring * metal * 0.18 + ring * modes

    shield_state = noise_state()

    def shield(t: float, rng: random.Random) -> float:
        edge, body, low = material_noise(shield_state, rng, 0.38, 0.07)
        attack = math.exp(-t * 78.0)
        ring = math.exp(-t * 17.0)
        modes = math.sin(math.tau * 92.0 * t) * 0.28 + math.sin(math.tau * 184.0 * t) * 0.1 + math.sin(math.tau * 267.0 * t) * 0.04
        return attack * edge * 0.4 + ring * body * 0.34 + ring * low * 0.13 + ring * modes

    heal_state = noise_state()

    def heal(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(heal_state, rng, 0.18, 0.018)
        breath = math.sin(math.pi * min(1.0, t / 0.46)) ** 1.35
        tone_env = min(1.0, t / 0.08) * max(0.0, 1.0 - t / 0.46) ** 1.15
        warm = math.sin(math.tau * 174.0 * t) * 0.12 + math.sin(math.tau * 232.0 * t) * 0.045
        close = strike(t, 0.34, 0.018)
        return breath * (paper * 0.29 + low * 0.12) + tone_env * warm + close * edge * 0.22

    ink_burst_state = noise_state()

    def ink_burst(t: float, rng: random.Random) -> float:
        edge, wet, low = material_noise(ink_burst_state, rng, 0.24, 0.02)
        body = tail(t, 0.025, 7.0)
        impact = strike(t, 0.025, 0.014)
        splats = strike(t, 0.18, 0.026) + strike(t, 0.32, 0.032) * 0.7
        rumble = body * (math.sin(math.tau * 48.0 * (t - 0.025)) * 0.34 + math.sin(math.tau * 73.0 * (t - 0.025)) * 0.1)
        return impact * edge * 0.48 + body * (wet * 0.46 + low * 0.22) + splats * wet * 0.48 + rumble

    powerup_state = noise_state()

    def powerup(t: float, rng: random.Random) -> float:
        edge, wax, low = material_noise(powerup_state, rng, 0.3, 0.035)
        first = strike(t, 0.025, 0.011)
        second = strike(t, 0.19, 0.014)
        body = tail(t, 0.025, 7.5)
        modes = math.sin(math.tau * 130.0 * t) * 0.17 + math.sin(math.tau * 195.0 * t) * 0.065
        return (first + second * 0.7) * edge * 0.4 + body * modes + max(0.0, 1.0 - t / 0.52) * (wax * 0.19 + low * 0.08)

    boss_down_state = noise_state()

    def boss_down(t: float, rng: random.Random) -> float:
        edge, debris, low = material_noise(boss_down_state, rng, 0.21, 0.017)
        impacts = ((0.025, 1.0, 49.0), (0.24, 0.72, 43.0), (0.49, 0.58, 38.0), (0.72, 0.42, 34.0))
        total = max(0.0, 1.0 - t / 0.95) * (debris * 0.27 + low * 0.22)
        for at, weight, frequency in impacts:
            total += strike(t, at, 0.016 + at * 0.012) * edge * 0.34 * weight
            total += tail(t, at, 8.0 + at * 3.0) * math.sin(math.tau * frequency * (t - at)) * 0.27 * weight
        return total

    ui_move_state = noise_state()

    def ui_move(t: float, rng: random.Random) -> float:
        edge, paper, _low = material_noise(ui_move_state, rng, 0.52, 0.12)
        env = math.exp(-t * 46.0)
        return env * (edge * 0.28 + paper * 0.16 + math.sin(math.tau * 230.0 * t) * 0.1)

    ui_confirm_state = noise_state()

    def ui_confirm(t: float, rng: random.Random) -> float:
        edge, wood, low = material_noise(ui_confirm_state, rng, 0.46, 0.09)
        attack = math.exp(-t * 72.0)
        body = math.exp(-t * 25.0)
        return attack * edge * 0.31 + body * wood * 0.2 + body * low * 0.08 + body * math.sin(math.tau * 190.0 * t) * 0.12

    ui_cancel_state = noise_state()

    def ui_cancel(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(ui_cancel_state, rng, 0.4, 0.065)
        flick = max(0.0, 1.0 - t / 0.13) ** 1.5
        knock = tail(t, 0.038, 31.0)
        return flick * (paper * 0.34 + edge * 0.13) + knock * (low * 0.21 + math.sin(math.tau * 126.0 * (t - 0.038)) * 0.11)

    save_state = noise_state()

    def save(t: float, rng: random.Random) -> float:
        edge, paper, low = material_noise(save_state, rng, 0.34, 0.045)
        latch = strike(t, 0.025, 0.009) + strike(t, 0.225, 0.012) * 0.64
        settle = max(0.0, 1.0 - t / 0.38) ** 1.25
        resonance = tail(t, 0.025, 10.0) * (math.sin(math.tau * 130.0 * t) * 0.13 + math.sin(math.tau * 195.0 * t) * 0.045)
        return latch * edge * 0.36 + settle * (paper * 0.25 + low * 0.09) + resonance

    music_states = {
        track: {"paper": 0.0, "brush": 0.0}
        for track in ("archive", "bindery", "finale", "editor", "binder", "author")
    }

    def archive_music(t: float, rng: random.Random) -> float:
        notes = (55.0, 65.41, 73.42, 49.0, 55.0, 82.41, 73.42, 65.41, 49.0, 61.74, 69.30, 55.0, 43.65, 55.0, 65.41, 49.0)
        pattern = (2, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 1, 0, 0, 1, 0)
        return music_score(t, rng, music_states["archive"], 32.0, 55.0, 2.0, notes, pattern, 0.72)

    def bindery_music(t: float, rng: random.Random) -> float:
        notes = (58.27, 58.27, 69.30, 77.78, 58.27, 87.31, 69.30, 51.91, 58.27, 69.30, 77.78, 103.83, 51.91, 58.27, 77.78, 69.30)
        pattern = (2, 0, 1, 0, 0, 1, 2, 0, 1, 0, 1, 0, 2, 0, 0, 1)
        return music_score(t, rng, music_states["bindery"], 32.0, 58.27, 3.0, notes, pattern, 0.78)

    def finale_music(t: float, rng: random.Random) -> float:
        notes = (49.0, 49.0, 61.74, 73.42, 49.0, 82.41, 73.42, 61.74, 55.0, 55.0, 69.30, 82.41, 55.0, 92.50, 82.41, 69.30)
        pattern = (2, 0, 1, 0, 2, 1, 0, 1, 2, 0, 1, 1, 2, 0, 1, 0)
        return music_score(t, rng, music_states["finale"], 32.0, 49.0, 4.0, notes, pattern, 0.84)

    def editor_music(t: float, rng: random.Random) -> float:
        notes = (55.0, 82.41, 55.0, 98.0, 65.41, 87.31, 73.42, 110.0, 55.0, 82.41, 49.0, 73.42, 65.41, 98.0, 55.0, 87.31)
        pattern = (2, 0, 1, 0, 2, 1, 0, 1, 2, 0, 2, 1, 0, 1, 2, 0)
        return music_score(t, rng, music_states["editor"], 24.0, 55.0, 5.0, notes, pattern, 0.88, True)

    def binder_music(t: float, rng: random.Random) -> float:
        notes = (58.27, 77.78, 69.30, 103.83, 58.27, 87.31, 51.91, 77.78, 69.30, 116.54, 58.27, 87.31, 51.91, 69.30, 77.78, 103.83)
        pattern = (2, 0, 0, 1, 2, 0, 1, 0, 2, 1, 0, 1, 2, 0, 1, 1)
        return music_score(t, rng, music_states["binder"], 24.0, 58.27, 4.0, notes, pattern, 0.92, True)

    def author_music(t: float, rng: random.Random) -> float:
        notes = (49.0, 73.42, 98.0, 123.47, 55.0, 82.41, 110.0, 146.83, 49.0, 61.74, 92.50, 138.59, 55.0, 69.30, 103.83, 164.81)
        pattern = (2, 0, 1, 1, 2, 1, 0, 1, 2, 0, 2, 1, 2, 1, 0, 1)
        return music_score(t, rng, music_states["author"], 24.0, 49.0, 4.0, notes, pattern, 0.98, True)

    return {
        "slash.wav": wav_bytes(0.24, slash),
        "hit.wav": wav_bytes(0.16, hit),
        "dash.wav": wav_bytes(0.22, dash),
        "pickup.wav": wav_bytes(0.24, pickup),
        "level_up.wav": wav_bytes(0.55, level_up),
        "hurt.wav": wav_bytes(0.28, hurt),
        "relic.wav": wav_bytes(0.52, relic),
        "boss_warning.wav": wav_bytes(0.75, boss_warning),
        "slash_heavy.wav": wav_bytes(0.36, slash_heavy),
        "slash_light.wav": wav_bytes(0.15, slash_light),
        "seal_cast.wav": wav_bytes(0.28, seal_cast),
        "ink_art.wav": wav_bytes(0.62, ink_art),
        "ink_art_palimpsest.wav": wav_bytes(0.56, ink_art_palimpsest),
        "ink_art_final_period.wav": wav_bytes(0.82, ink_art_final_period),
        "ink_art_red_line.wav": wav_bytes(0.42, ink_art_red_line),
        "ink_art_seal_storm.wav": wav_bytes(0.72, ink_art_seal_storm),
        "ink_art_cross_revision.wav": wav_bytes(0.62, ink_art_cross_revision),
        "enemy_cast.wav": wav_bytes(0.32, enemy_cast),
        "enemy_dash.wav": wav_bytes(0.3, enemy_dash),
        "teleport.wav": wav_bytes(0.5, teleport),
        "parry.wav": wav_bytes(0.22, parry),
        "shield.wav": wav_bytes(0.25, shield),
        "heal.wav": wav_bytes(0.46, heal),
        "ink_burst.wav": wav_bytes(0.65, ink_burst),
        "powerup.wav": wav_bytes(0.52, powerup),
        "boss_down.wav": wav_bytes(0.95, boss_down),
        "ui_move.wav": wav_bytes(0.08, ui_move),
        "ui_confirm.wav": wav_bytes(0.15, ui_confirm),
        "ui_cancel.wav": wav_bytes(0.13, ui_cancel),
        "save.wav": wav_bytes(0.38, save),
        "music_archive.wav": wav_bytes(32.0, archive_music),
        "music_bindery.wav": wav_bytes(32.0, bindery_music),
        "music_finale.wav": wav_bytes(32.0, finale_music),
        "music_editor.wav": wav_bytes(24.0, editor_music),
        "music_binder.wav": wav_bytes(24.0, binder_music),
        "music_author.wav": wav_bytes(24.0, author_music),
    }


def build_assets() -> dict[Path, bytes]:
    images = {
        "player.png": player_sprite(),
        "enemy.png": enemy_sprite(),
        "dasher.png": enemy_sprite(CRIMSON),
        "brute.png": brute_sprite(),
        "scribe.png": scribe_sprite(),
        "splitter.png": splitter_sprite(),
        "leech.png": leech_sprite(),
        "warden.png": warden_sprite(),
        "censor.png": censor_sprite(),
        "errata.png": errata_sprite(),
        "archivist.png": archivist_sprite(),
        "blot.png": blot_sprite(),
        "duelist.png": duelist_sprite(),
        "boss.png": boss_sprite(),
        "binder.png": binder_sprite(),
        "author.png": author_sprite(),
        "ink_orb.png": orb_sprite(),
        "health.png": health_sprite(),
        "shard.png": shard_sprite(),
        "relic.png": relic_sprite(),
        "bomb.png": bomb_pickup_sprite(),
        "magnet.png": magnet_pickup_sprite(),
        "frenzy.png": frenzy_pickup_sprite(),
        "ward.png": ward_pickup_sprite(),
        "hourglass.png": hourglass_pickup_sprite(),
        "projectile.png": projectile_sprite(),
        "floor.png": floor_tile(),
        "icon.png": icon_sprite(),
    }
    built = {IMAGE_ROOT / name: canvas.png_bytes() for name, canvas in images.items()}
    built.update({AUDIO_ROOT / name: data for name, data in sound_assets().items()})
    return built


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when generated assets are missing or stale")
    args = parser.parse_args()
    assets = build_assets()
    stale: list[str] = []
    for path, data in assets.items():
        changed = not path.exists() or path.read_bytes() != data
        if changed:
            stale.append(str(path.relative_to(REPO_ROOT)))
        if not args.check and changed:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)

    curated_payloads: dict[Path, bytes] = {}
    for path in AI_ASSISTED_ASSETS:
        if not path.exists():
            stale.append(str(path.relative_to(REPO_ROOT)))
            continue
        curated_payloads[path] = path.read_bytes()

    manifest = {
        "schema_version": 3,
        "generator": "tools/game/generate_validation_assets.py",
        "purpose": "Per-asset provenance and integrity inventory; not legal advice.",
        "asset_count": len(assets) + len(curated_payloads),
        "assets": [
            {
                "id": ("audio-" if path.suffix == ".wav" else "sprite-") + path.stem.replace("_", "-"),
                "runtime_path": "res://" + path.relative_to(GAME_ROOT).as_posix(),
                "sha256": hashlib.sha256(data).hexdigest(),
                "media_type": "audio" if path.suffix == ".wav" else "image",
                "origin": "manga-forge-source-code",
                "creation_method": "deterministic-procedural-generation",
                "generative_ai": False,
                "live_generation": False,
                "provenance_record": "tools/game/generate_validation_assets.py",
                "prompt_record_status": "not-applicable",
                "derivation": "reproducible bytes generated from committed Python source",
                "human_review_status": "runtime-and-regression-reviewed",
                "rights_review_status": "project-authored-source",
            }
            for path, data in sorted(assets.items(), key=lambda item: str(item[0]))
        ]
        + [
            {
                "id": AI_ASSISTED_ASSETS[path]["id"],
                "runtime_path": "res://" + path.relative_to(GAME_ROOT).as_posix(),
                "sha256": hashlib.sha256(data).hexdigest(),
                "media_type": "audio" if path.suffix.lower() in {".ogg", ".wav", ".mp3"} else "image",
                "origin": AI_ASSISTED_ASSETS[path].get("origin", "openai-image-generation"),
                "creation_method": "pre-generated-ai-assisted",
                "generative_ai": True,
                "live_generation": False,
                "provenance_record": AI_ASSISTED_ASSETS[path]["provenance_record"],
                "prompt_record_status": AI_ASSISTED_ASSETS[path]["prompt_record_status"],
                "derivation": AI_ASSISTED_ASSETS[path]["derivation"],
                "human_review_status": AI_ASSISTED_ASSETS[path].get(
                    "human_review_status", "runtime-and-capture-reviewed"
                ),
                "rights_review_status": AI_ASSISTED_ASSETS[path].get(
                    "rights_review_status", "publisher-confirmation-required-before-commercial-release"
                ),
                "source_commit": AI_ASSISTED_ASSETS[path].get("source_commit", "33f8315"),
            }
            for path, data in sorted(curated_payloads.items(), key=lambda item: str(item[0]))
        ],
    }
    manifest_path = GAME_ROOT / "asset-manifest.json"
    manifest_data = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()
    manifest_changed = not manifest_path.exists() or manifest_path.read_bytes() != manifest_data
    if manifest_changed:
        stale.append(str(manifest_path.relative_to(REPO_ROOT)))
    if not args.check and manifest_changed:
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_bytes(manifest_data)

    if args.check and stale:
        print("stale or missing project assets:")
        for path in stale:
            print(f"- {path}")
        return 1
    total_assets = len(assets) + len(curated_payloads)
    print(f"{'validated' if args.check else 'generated'} {total_assets} assets for {GAME_ROOT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
