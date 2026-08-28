#!/usr/bin/env python3
"""Render a short procedural suspense bed for the Hainan narration cue."""

from __future__ import annotations

import argparse
import math
import random
import wave
from array import array
from pathlib import Path


SAMPLE_RATE = 48_000
DURATION = 14.0
TAU = math.tau


def clamp(value: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, value))


def smoothstep(value: float) -> float:
    value = clamp(value)
    return value * value * (3.0 - 2.0 * value)


def pan_gains(pan: float) -> tuple[float, float]:
    angle = (clamp((pan + 1.0) * 0.5) * math.pi) / 2.0
    return math.cos(angle), math.sin(angle)


def add_sample(left: array, right: array, index: int, value: float, pan: float) -> None:
    left_gain, right_gain = pan_gains(pan)
    left[index] += value * left_gain
    right[index] += value * right_gain


def add_drone(left: array, right: array) -> None:
    """Low string-like harmonic plane with a restrained semitone tension."""
    base = 73.416  # D2
    fifth = 110.0  # A2
    tension = 155.563  # Eb3
    for index in range(len(left)):
        time = index / SAMPLE_RATE
        fade_in = smoothstep(time / 1.4)
        fade_out = smoothstep((DURATION - time) / 1.4)
        duck = 1.0 - 0.69 * smoothstep((time - 2.75) / 0.75)
        breath = 0.86 + 0.14 * math.sin(TAU * 0.115 * time)
        tremble = 0.97 + 0.03 * math.sin(TAU * 3.1 * time)
        envelope = fade_in * fade_out * duck * breath

        left_value = (
            0.095 * math.sin(TAU * base * time)
            + 0.033 * math.sin(TAU * base * 2.0 * time + 0.17)
            + 0.016 * math.sin(TAU * base * 3.0 * time + 0.41)
            + 0.055 * math.sin(TAU * fifth * time + 0.11)
            + 0.012 * math.sin(TAU * tension * time + 0.52) * tremble
        )
        right_value = (
            0.095 * math.sin(TAU * (base * 1.0018) * time + 0.23)
            + 0.033 * math.sin(TAU * (base * 2.003) * time + 0.47)
            + 0.016 * math.sin(TAU * (base * 3.002) * time + 0.73)
            + 0.055 * math.sin(TAU * (fifth * 0.999) * time + 0.36)
            + 0.012 * math.sin(TAU * (tension * 1.001) * time + 0.89) * tremble
        )
        left[index] += left_value * envelope
        right[index] += right_value * envelope


def add_sub_pulse(left: array, right: array) -> None:
    """A slow threat pulse that recedes once narration begins."""
    for index in range(len(left)):
        time = index / SAMPLE_RATE
        fade_in = smoothstep(time / 0.35)
        fade_out = smoothstep((DURATION - time) / 1.1)
        duck = 1.0 - 0.76 * smoothstep((time - 2.7) / 0.8)
        pulse = 0.30 + 0.70 * smoothstep((math.sin(TAU * 0.72 * time - 0.8) + 1.0) * 0.5)
        value = 0.052 * math.sin(TAU * 36.708 * time) * pulse * fade_in * fade_out * duck
        left[index] += value
        right[index] += value


def add_drum(
    left: array,
    right: array,
    start: float,
    amplitude: float,
    pan: float = 0.0,
    duration: float = 0.78,
) -> None:
    """Synthetic cinematic floor-drum: pitched body, skin resonance, and soft attack."""
    first = int(start * SAMPLE_RATE)
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    rng = random.Random(round(start * 10_000) + 7331)
    noise_state = 0.0
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        progress = time / duration
        frequency_start = 108.0
        frequency_end = 47.0
        phase = TAU * (
            frequency_start * time
            + 0.5 * (frequency_end - frequency_start) * (time * time / duration)
        )
        body_envelope = math.exp(-5.7 * progress)
        skin_envelope = math.exp(-18.0 * progress)
        raw_noise = rng.uniform(-1.0, 1.0)
        noise_state += 0.11 * (raw_noise - noise_state)
        body = math.sin(phase) + 0.31 * math.sin(phase * 1.96 + 0.31)
        skin = noise_state * skin_envelope
        attack = smoothstep(time / 0.006)
        value = amplitude * attack * (0.72 * body * body_envelope + 0.22 * skin)
        add_sample(left, right, first + offset, value, pan)


def add_reverse_swell(
    left: array,
    right: array,
    start: float,
    duration: float,
    amplitude: float,
) -> None:
    """Dark filtered swell that opens the narration entrance without broadband hiss."""
    first = int(start * SAMPLE_RATE)
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    rng = random.Random(1990)
    low_state = 0.0
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        progress = clamp(time / duration)
        raw_noise = rng.uniform(-1.0, 1.0)
        low_state += 0.018 * (raw_noise - low_state)
        tonal = math.sin(TAU * (77.782 + 8.0 * progress) * time + 0.2)
        envelope = smoothstep(progress) * smoothstep((1.0 - progress) / 0.08)
        value = amplitude * envelope * (0.58 * low_state + 0.42 * tonal)
        pan = -0.42 + 0.84 * progress
        add_sample(left, right, first + offset, value, pan)


def add_glass_note(
    left: array,
    right: array,
    start: float,
    frequency: float,
    amplitude: float,
    pan: float,
) -> None:
    """Sparse high-mid point used as an investigative motif."""
    duration = 1.85
    first = int(start * SAMPLE_RATE)
    count = min(int(duration * SAMPLE_RATE), len(left) - first)
    for offset in range(max(0, count)):
        time = offset / SAMPLE_RATE
        attack = smoothstep(time / 0.012)
        envelope = attack * math.exp(-3.4 * time)
        value = amplitude * envelope * (
            math.sin(TAU * frequency * time)
            + 0.23 * math.sin(TAU * frequency * 2.01 * time + 0.4)
            + 0.08 * math.sin(TAU * frequency * 3.98 * time + 0.8)
        )
        add_sample(left, right, first + offset, value, pan)


def add_room(left: array, right: array) -> None:
    """Short cross-fed delays for a distant, humid night-space impression."""
    dry_left = array("f", left)
    dry_right = array("f", right)
    taps = ((0.083, 0.17), (0.167, 0.10), (0.293, 0.055))
    for delay_seconds, gain in taps:
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

    target_peak = 10.0 ** (-3.0 / 20.0)
    gain = target_peak / peak if peak else 1.0
    drive = 1.08
    drive_norm = math.tanh(drive)
    for index in range(len(left)):
        left[index] = math.tanh(left[index] * gain * drive) / drive_norm
        right[index] = math.tanh(right[index] * gain * drive) / drive_norm


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
    sample_count = round(DURATION * SAMPLE_RATE)
    left = array("f", [0.0]) * sample_count
    right = array("f", [0.0]) * sample_count

    add_drone(left, right)
    add_sub_pulse(left, right)
    add_reverse_swell(left, right, 1.85, 1.25, 0.11)

    for start, amplitude, pan in (
        (0.10, 0.62, -0.10),
        (0.92, 0.52, 0.12),
        (1.72, 0.57, -0.14),
        (2.50, 0.70, 0.08),
        (5.75, 0.18, -0.18),
        (9.10, 0.16, 0.16),
        (12.20, 0.14, -0.08),
    ):
        add_drum(left, right, start, amplitude, pan)

    add_glass_note(left, right, 0.55, 293.665, 0.042, -0.55)  # D4
    add_glass_note(left, right, 1.37, 311.127, 0.036, 0.52)   # Eb4
    add_glass_note(left, right, 2.20, 220.000, 0.040, -0.18)  # A3
    add_glass_note(left, right, 10.70, 155.563, 0.012, 0.35)  # distant Eb3

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
