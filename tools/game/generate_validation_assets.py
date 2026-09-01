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
CURATED_ASSETS = {
    GAME_ROOT / "assets" / "characters" / "combat-cast-atlas-v1.png": {
        "id": "combat-cast-atlas-v1",
        "origin": "project-directed-openai-image-tools",
    },
    GAME_ROOT / "assets" / "characters" / "nara-slash-atlas-v1.png": {
        "id": "nara-slash-atlas-v1",
        "origin": "project-directed-openai-image-tools",
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
    def beat_tone(t: float, rate: float, notes: tuple[float, ...], harmonic: float = 2.0) -> float:
        phase = (t * rate) % 1.0
        envelope = math.sin(math.pi * phase) ** 2
        note = notes[int(t * rate) % len(notes)]
        return envelope * (math.sin(math.tau * note * t) + 0.28 * math.sin(math.tau * note * harmonic * t))

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
            steel_tick = math.sin(math.tau * 930.0 * (t - contact_time)) * contact
            handle_thump = math.sin(math.tau * body_frequency * (t - contact_time)) * body
            return (
                motion * (blade_air * air_weight + edge_air * air_weight * 0.28)
                + contact * edge_air * edge_weight
                + steel_tick * edge_weight * 0.08
                + handle_thump * 0.13
            )

        return sample

    slash = blade_cut(0.24, 0.88, 0.54, 104.0, 0.43)
    slash_heavy = blade_cut(0.36, 1.02, 0.68, 72.0, 0.48)
    slash_light = blade_cut(0.15, 0.68, 0.74, 138.0, 0.38)

    hit_state = {"fast": 0.0, "slow": 0.0}

    def hit(t: float, rng: random.Random) -> float:
        raw = rng.uniform(-1.0, 1.0)
        hit_state["fast"] += (raw - hit_state["fast"]) * 0.48
        hit_state["slow"] += (hit_state["fast"] - hit_state["slow"]) * 0.075
        crack = raw - hit_state["fast"]
        material = hit_state["fast"] - hit_state["slow"]
        edge_env = math.exp(-t * 92.0)
        body_env = math.exp(-t * 25.0)
        return edge_env * crack * 0.92 + body_env * material * 0.68 + body_env * math.sin(math.tau * 78.0 * t) * 0.16

    def dash(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.22)
        return env * (0.4 * rng.uniform(-1.0, 1.0) + 0.3 * math.sin(math.tau * (520.0 - 900.0 * t) * t))

    def pickup(t: float, _rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.24)
        frequency = 520.0 if t < 0.08 else (780.0 if t < 0.16 else 1040.0)
        return 0.5 * env * math.sin(math.tau * frequency * t)

    def level_up(t: float, _rng: random.Random) -> float:
        notes = (440.0, 554.37, 659.25, 880.0)
        note = notes[min(int(t / 0.12), len(notes) - 1)]
        env = max(0.0, 1.0 - t / 0.55)
        return 0.45 * env * (math.sin(math.tau * note * t) + 0.3 * math.sin(math.tau * note * 2.0 * t))

    def hurt(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.28)
        return env * (0.45 * math.sin(math.tau * (240.0 - 420.0 * t) * t) + 0.18 * rng.uniform(-1.0, 1.0))

    def relic(t: float, _rng: random.Random) -> float:
        notes = (392.0, 587.33, 783.99, 1174.66)
        note = notes[min(int(t / 0.11), len(notes) - 1)]
        env = max(0.0, 1.0 - t / 0.52)
        return 0.42 * env * (math.sin(math.tau * note * t) + 0.22 * math.sin(math.tau * note * 3.0 * t))

    def boss_warning(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.75)
        pulse = 1.0 if int(t * 8.0) % 2 == 0 else 0.35
        return env * pulse * (0.45 * math.sin(math.tau * 62.0 * t) + 0.12 * rng.uniform(-1.0, 1.0))

    seal_state = {"paper": 0.0, "ink": 0.0}

    def seal_cast(t: float, rng: random.Random) -> float:
        raw = rng.uniform(-1.0, 1.0)
        seal_state["paper"] += (raw - seal_state["paper"]) * 0.52
        seal_state["ink"] += (seal_state["paper"] - seal_state["ink"]) * 0.065
        snap = math.exp(-t * 105.0) * (raw - seal_state["paper"])
        drag_env = min(1.0, t / 0.018) * max(0.0, 1.0 - t / 0.28) ** 1.6
        paper_drag = seal_state["paper"] - seal_state["ink"]
        stamp = math.exp(-((t - 0.19) / 0.014) ** 2)
        return snap * 0.82 + drag_env * paper_drag * 0.76 + stamp * (raw * 0.42 + math.sin(math.tau * 112.0 * t) * 0.15)

    def ink_art(t: float, rng: random.Random) -> float:
        rise = min(1.0, t / 0.08)
        fall = max(0.0, 1.0 - t / 0.62)
        env = rise * fall
        sweep = 120.0 + 680.0 * t
        return env * (0.35 * math.sin(math.tau * sweep * t) + 0.2 * math.sin(math.tau * sweep * 1.5 * t) + 0.08 * rng.uniform(-1.0, 1.0))

    def enemy_cast(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.32)
        pulse = 1.0 if int(t * 24.0) % 2 == 0 else 0.42
        return env * pulse * (0.32 * math.sin(math.tau * (180.0 + 520.0 * t) * t) + 0.1 * rng.uniform(-1.0, 1.0))

    def enemy_dash(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.3)
        return env * (0.4 * math.sin(math.tau * (420.0 - 720.0 * t) * t) + 0.22 * rng.uniform(-1.0, 1.0))

    def teleport(t: float, rng: random.Random) -> float:
        env = math.sin(math.pi * min(1.0, t / 0.5))
        return env * (0.28 * math.sin(math.tau * (160.0 + 1100.0 * t) * t) + 0.13 * rng.uniform(-1.0, 1.0))

    def parry(t: float, _rng: random.Random) -> float:
        env = math.exp(-24.0 * t)
        return env * (0.5 * math.sin(math.tau * 1760.0 * t) + 0.35 * math.sin(math.tau * 2637.0 * t))

    def shield(t: float, rng: random.Random) -> float:
        env = math.exp(-18.0 * t)
        return env * (0.45 * math.sin(math.tau * 118.0 * t) + 0.22 * rng.uniform(-1.0, 1.0))

    def heal(t: float, _rng: random.Random) -> float:
        notes = (523.25, 659.25, 783.99)
        note = notes[min(int(t / 0.13), len(notes) - 1)]
        env = max(0.0, 1.0 - t / 0.46)
        return 0.42 * env * (math.sin(math.tau * note * t) + 0.2 * math.sin(math.tau * note * 2.0 * t))

    def ink_burst(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.65) ** 1.7
        return env * (0.52 * math.sin(math.tau * (78.0 - 32.0 * t) * t) + 0.38 * rng.uniform(-1.0, 1.0))

    def powerup(t: float, _rng: random.Random) -> float:
        notes = (330.0, 440.0, 554.37, 659.25)
        note = notes[min(int(t / 0.11), len(notes) - 1)]
        env = max(0.0, 1.0 - t / 0.52)
        return 0.38 * env * (math.sin(math.tau * note * t) + 0.22 * math.sin(math.tau * note * 3.0 * t))

    def boss_down(t: float, rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.95)
        fall = 180.0 - 120.0 * t
        return env * (0.42 * math.sin(math.tau * fall * t) + 0.22 * math.sin(math.tau * fall * 0.5 * t) + 0.18 * rng.uniform(-1.0, 1.0))

    def ui_move(t: float, _rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.08)
        return 0.32 * env * math.sin(math.tau * 760.0 * t)

    def ui_confirm(t: float, _rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.15)
        note = 620.0 if t < 0.065 else 930.0
        return 0.35 * env * math.sin(math.tau * note * t)

    def ui_cancel(t: float, _rng: random.Random) -> float:
        env = max(0.0, 1.0 - t / 0.13)
        return 0.32 * env * math.sin(math.tau * (620.0 - 1800.0 * t) * t)

    def save(t: float, _rng: random.Random) -> float:
        note = (392.0, 523.25, 783.99)[min(int(t / 0.11), 2)]
        env = max(0.0, 1.0 - t / 0.38)
        return 0.38 * env * (math.sin(math.tau * note * t) + 0.18 * math.sin(math.tau * note * 2.0 * t))

    def archive_music(t: float, _rng: random.Random) -> float:
        notes = (55.0, 65.41, 73.42, 49.0, 55.0, 82.41, 73.42, 65.41)
        air = 0.018 * math.sin(math.tau * 997.0 * t) * math.sin(math.pi * ((t * 2.0) % 1.0)) ** 2
        return 0.13 * math.sin(math.tau * 55.0 * t) + 0.1 * beat_tone(t, 2.0, notes) + air

    def bindery_music(t: float, _rng: random.Random) -> float:
        notes = (58.27, 58.27, 69.30, 77.78, 58.27, 87.31, 69.30, 51.91, 58.27, 69.30, 77.78, 103.83)
        scrape = 0.028 * math.sin(math.tau * 1307.0 * t) * math.sin(math.pi * ((t * 3.0) % 1.0)) ** 4
        return 0.12 * math.sin(math.tau * 58.25 * t) + 0.11 * beat_tone(t, 3.0, notes, 3.0) + scrape

    def finale_music(t: float, _rng: random.Random) -> float:
        notes = (49.0, 49.0, 61.74, 73.42, 49.0, 82.41, 73.42, 61.74, 55.0, 55.0, 69.30, 82.41, 55.0, 92.50, 82.41, 69.30)
        grit = 0.024 * math.sin(math.tau * 1499.0 * t) * math.sin(math.pi * ((t * 4.0) % 1.0)) ** 4
        return 0.13 * math.sin(math.tau * 49.0 * t) + 0.13 * beat_tone(t, 4.0, notes) + grit

    def editor_music(t: float, _rng: random.Random) -> float:
        notes = (55.0, 82.41, 55.0, 98.0, 65.41, 87.31, 73.42, 110.0, 55.0, 82.41, 49.0, 73.42)
        stamp = math.sin(math.pi * ((t * 5.0) % 1.0)) ** 8
        return 0.13 * math.sin(math.tau * 55.0 * t) + 0.15 * beat_tone(t, 5.0, notes, 1.5) + 0.08 * stamp * math.sin(math.tau * 92.0 * t)

    def binder_music(t: float, _rng: random.Random) -> float:
        notes = (58.27, 77.78, 69.30, 103.83, 58.27, 87.31, 51.91, 77.78, 69.30, 116.54, 58.27, 87.31)
        chain = 0.035 * math.sin(math.tau * 1741.0 * t) * math.sin(math.pi * ((t * 4.0) % 1.0)) ** 6
        return 0.15 * math.sin(math.tau * 58.25 * t) + 0.15 * beat_tone(t, 4.0, notes, 2.5) + chain

    def author_music(t: float, _rng: random.Random) -> float:
        notes = (49.0, 73.42, 98.0, 123.47, 55.0, 82.41, 110.0, 146.83, 49.0, 61.74, 92.50, 138.59, 55.0, 69.30, 103.83, 164.81)
        press = math.sin(math.pi * ((t * 4.0) % 1.0)) ** 10
        return 0.16 * math.sin(math.tau * 49.0 * t) + 0.17 * beat_tone(t, 4.0, notes, 2.0) + 0.09 * press * math.sin(math.tau * 41.0 * t)

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
        "music_archive.wav": wav_bytes(16.0, archive_music),
        "music_bindery.wav": wav_bytes(16.0, bindery_music),
        "music_finale.wav": wav_bytes(16.0, finale_music),
        "music_editor.wav": wav_bytes(12.0, editor_music),
        "music_binder.wav": wav_bytes(12.0, binder_music),
        "music_author.wav": wav_bytes(12.0, author_music),
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
        if not path.exists() or path.read_bytes() != data:
            stale.append(str(path.relative_to(REPO_ROOT)))
        if not args.check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)

    curated_payloads: dict[Path, bytes] = {}
    for path in CURATED_ASSETS:
        if not path.exists():
            stale.append(str(path.relative_to(REPO_ROOT)))
            continue
        curated_payloads[path] = path.read_bytes()

    manifest = {
        "schema_version": 2,
        "generator": "tools/game/generate_validation_assets.py",
        "license": "project-original",
        "assets": [
            {
                "id": path.stem.replace("_", "-"),
                "runtime_path": "res://" + path.relative_to(GAME_ROOT).as_posix(),
                "sha256": hashlib.sha256(data).hexdigest(),
                "origin": "deterministic-manga-forge",
            }
            for path, data in sorted(assets.items(), key=lambda item: str(item[0]))
        ]
        + [
            {
                "id": CURATED_ASSETS[path]["id"],
                "runtime_path": "res://" + path.relative_to(GAME_ROOT).as_posix(),
                "sha256": hashlib.sha256(data).hexdigest(),
                "origin": CURATED_ASSETS[path]["origin"],
            }
            for path, data in sorted(curated_payloads.items(), key=lambda item: str(item[0]))
        ],
    }
    manifest_path = GAME_ROOT / "asset-manifest.json"
    manifest_data = (json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode()
    if not manifest_path.exists() or manifest_path.read_bytes() != manifest_data:
        stale.append(str(manifest_path.relative_to(REPO_ROOT)))
    if not args.check:
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
