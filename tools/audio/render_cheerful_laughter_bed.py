#!/usr/bin/env python3
"""Render a fresh, cheerful procedural music bed for a laughter vignette."""

from __future__ import annotations

import argparse
import math
import random
import wave
from array import array
from pathlib import Path


SAMPLE_RATE = 48_000
DURATION = 11.0
BPM = 112.0
BEAT = 60.0 / BPM
BAR = BEAT * 4.0
TAU = math.tau


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def smoothstep(value: float) -> float:
    value = clamp(value)
    return value * value * (3.0 - 2.0 * value)


def pan_gains(pan: float) -> tuple[float, float]:
    angle = clamp((pan + 1.0) * 0.5) * math.pi / 2.0
    return math.cos(angle), math.sin(angle)


def bed_duck(time: float) -> float:
    """Keep the opening forward, then make room for laughter and dialogue."""
    fade_in = smoothstep(time / 0.08)
    dialogue_space = 1.0 - 0.48 * smoothstep((time - 2.75) / 0.65)
    fade_out = smoothstep((DURATION - time) / 1.25)
    return fade_in * dialogue_space * fade_out


def add_stereo(left: array, right: array, index: int, value: float, pan: float) -> None:
    left_gain, right_gain = pan_gains(pan)
    left[index] += value * left_gain
    right[index] += value * right_gain


def add_pad(left: array, right: array) -> None:
    """Warm, transparent chord plane with a five-bar D-major progression."""
    chords = (
        (146.832, 220.000, 369.994),  # D3 A3 F#4
        (195.998, 293.665, 493.883),  # G3 D4 B4
        (123.471, 184.997, 293.665),  # B2 F#3 D4
        (110.000, 164.814, 277.183),  # A2 E3 C#4
        (146.832, 220.000, 369.994),  # D3 A3 F#4
        (146.832, 220.000, 369.994),
    )
    for index in range(len(left)):
        time = index / SAMPLE_RATE
        chord_position = min(int(time / BAR), len(chords) - 1)
        local = (time % BAR) / BAR
        chord = chords[chord_position]
        chord_env = 0.83 + 0.17 * math.sin(math.pi * local)
        motion = 0.94 + 0.06 * math.sin(TAU * 0.23 * time)
        gain = 0.035 * bed_duck(time) * chord_env * motion
        left_value = 0.0
        right_value = 0.0
        for voice_index, frequency in enumerate(chord):
            phase = voice_index * 0.31
            left_value += math.sin(TAU * frequency * time + phase)
            left_value += 0.18 * math.sin(TAU * frequency * 2.0 * time + phase + 0.2)
            right_value += math.sin(TAU * frequency * 1.0013 * time + phase + 0.37)
            right_value += 0.18 * math.sin(TAU * frequency * 1.998 * time + phase + 0.61)
        left[index] += left_value * gain
        right[index] += right_value * gain


def add_pluck(
    left: array,
    right: array,
    start: float,
    frequency: float,
    amplitude: float,
    pan: float,
    duration: float = 0.78,
) -> None:
    """Bell-pluck approximation with a soft wooden attack."""
    first = int(start * SAMPLE_RATE)
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    rng = random.Random(round(start * 100_000) + round(frequency))
    noise_state = 0.0
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        attack = smoothstep(time / 0.006)
        envelope = attack * math.exp(-4.8 * time)
        fundamental = math.sin(TAU * frequency * time)
        partials = (
            0.34 * math.sin(TAU * frequency * 2.01 * time + 0.31)
            + 0.13 * math.sin(TAU * frequency * 3.97 * time + 0.72)
        )
        raw_noise = rng.uniform(-1.0, 1.0)
        noise_state += 0.22 * (raw_noise - noise_state)
        transient = noise_state * math.exp(-42.0 * time)
        value = amplitude * envelope * (0.68 * fundamental + partials + 0.10 * transient)
        add_stereo(left, right, first + offset, value * bed_duck(start + time), pan)


def add_soft_kick(left: array, right: array, start: float, amplitude: float) -> None:
    first = int(start * SAMPLE_RATE)
    duration = 0.23
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        progress = time / duration
        phase = TAU * (91.0 * time - 24.0 * time * time / duration)
        envelope = smoothstep(time / 0.004) * math.exp(-8.5 * progress)
        value = amplitude * math.sin(phase) * envelope * bed_duck(start + time)
        left[first + offset] += value
        right[first + offset] += value


def add_wood_click(
    left: array,
    right: array,
    start: float,
    amplitude: float,
    pan: float,
) -> None:
    first = int(start * SAMPLE_RATE)
    duration = 0.095
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    rng = random.Random(round(start * 100_000) + 112)
    state = 0.0
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        raw = rng.uniform(-1.0, 1.0)
        state += 0.38 * (raw - state)
        envelope = math.exp(-38.0 * time)
        tone = math.sin(TAU * 760.0 * time) + 0.35 * math.sin(TAU * 1180.0 * time)
        value = amplitude * envelope * (0.55 * tone + 0.18 * state) * bed_duck(start + time)
        add_stereo(left, right, first + offset, value, pan)


def add_shaker_tick(
    left: array,
    right: array,
    start: float,
    amplitude: float,
    pan: float,
) -> None:
    first = int(start * SAMPLE_RATE)
    duration = 0.055
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    rng = random.Random(round(start * 1_000_000) + 2026)
    low = 0.0
    previous = 0.0
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        raw = rng.uniform(-1.0, 1.0)
        low += 0.14 * (raw - low)
        high = raw - low
        previous += 0.32 * (high - previous)
        envelope = smoothstep(time / 0.002) * math.exp(-62.0 * time)
        value = amplitude * previous * envelope * bed_duck(start + time)
        add_stereo(left, right, first + offset, value, pan)


def add_room(left: array, right: array) -> None:
    dry_left = array("f", left)
    dry_right = array("f", right)
    for delay_seconds, gain in ((0.061, 0.13), (0.127, 0.075), (0.211, 0.04)):
        delay = int(delay_seconds * SAMPLE_RATE)
        for index in range(delay, len(left)):
            left[index] += dry_right[index - delay] * gain
            right[index] += dry_left[index - delay] * gain


def master(left: array, right: array) -> None:
    mean_left = sum(left) / len(left)
    mean_right = sum(right) / len(right)
    peak = 0.0
    for index in range(len(left)):
        left[index] -= mean_left
        right[index] -= mean_right
        peak = max(peak, abs(left[index]), abs(right[index]))
    target_peak = 10.0 ** (-3.2 / 20.0)
    gain = target_peak / peak if peak else 1.0
    drive = 1.03
    normalizer = math.tanh(drive)
    for index in range(len(left)):
        left[index] = math.tanh(left[index] * gain * drive) / normalizer
        right[index] = math.tanh(right[index] * gain * drive) / normalizer


def write_wav(path: Path, left: array, right: array) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = array("h")
    for left_value, right_value in zip(left, right):
        frames.append(round(clamp(left_value, -1.0, 1.0) * 32767.0))
        frames.append(round(clamp(right_value, -1.0, 1.0) * 32767.0))
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(2)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(frames.tobytes())


def render(path: Path) -> None:
    count = round(DURATION * SAMPLE_RATE)
    left = array("f", [0.0]) * count
    right = array("f", [0.0]) * count

    add_pad(left, right)

    motif = (587.330, 739.989, 880.000, 987.767, 880.000, 739.989, 659.255, 587.330)
    for note_index, frequency in enumerate(motif):
        start = 0.12 + note_index * (BEAT * 0.5)
        pan = -0.48 + (note_index % 4) * 0.32
        add_pluck(left, right, start, frequency, 0.105, pan)

    for start, frequency, pan in (
        (3.38, 739.989, -0.38),
        (4.46, 880.000, 0.42),
        (5.54, 659.255, -0.22),
        (7.68, 739.989, 0.30),
        (9.82, 587.330, -0.05),
    ):
        add_pluck(left, right, start, frequency, 0.046, pan, duration=0.95)

    beat_count = math.ceil(DURATION / BEAT)
    for beat_index in range(beat_count):
        start = beat_index * BEAT
        if beat_index % 2 == 0:
            add_soft_kick(left, right, start + 0.01, 0.075 if start < 3.0 else 0.042)
        else:
            add_wood_click(left, right, start + 0.015, 0.046 if start < 3.0 else 0.026, 0.18)
        add_shaker_tick(left, right, start + BEAT * 0.5, 0.038 if start < 3.0 else 0.021, -0.32 if beat_index % 2 else 0.34)

    add_room(left, right)
    master(left, right)
    write_wav(path, left, right)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    render(args.out)


if __name__ == "__main__":
    main()
