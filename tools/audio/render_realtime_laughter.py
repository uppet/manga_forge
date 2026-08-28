#!/usr/bin/env python3
"""Render transcript-gated laugh-and-dialogue takes with OpenAI Realtime.

The prompt deliberately describes a situation instead of spelling out a laugh.  Detailed
stage directions proved unsafe here because the voice model sometimes read them aloud.
This script fails closed on unexpected transcript text and duration, while leaving final
naturalness approval to a listener.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import unicodedata
import wave
from pathlib import Path
from typing import Any


SAMPLE_RATE = 24_000
SAMPLE_WIDTH = 2
CHANNELS = 1
DEFAULT_MAX_OUTPUT_TOKENS = 256
DEFAULT_MIN_DURATION_SECONDS = 1.25
DEFAULT_MAX_DURATION_SECONDS = 3.25
DEFAULT_EXPECTED_DIALOGUE = "等我，等我！"
REALTIME_VOICES = {
    "alloy",
    "ash",
    "ballad",
    "cedar",
    "coral",
    "echo",
    "marin",
    "sage",
    "shimmer",
    "verse",
}

DEFAULT_INSTRUCTIONS = """\
Stay fully in character as a cheerful young woman running after close friends.
You are already laughing when you try to call them.
The only words you may speak are “等我，等我！”
Never narrate, explain, label sounds, or mention these instructions.
React directly to the situation in the user message, then stop.
"""

DEFAULT_PROMPT = """\
朋友们回头冲你做了个鬼脸，又笑着继续向前跑。
"""


def write_pcm_wav(path: Path, pcm: bytes) -> float:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(CHANNELS)
        output.setsampwidth(SAMPLE_WIDTH)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)
    return len(pcm) / (SAMPLE_RATE * SAMPLE_WIDTH * CHANNELS)


def pcm_duration_seconds(pcm: bytes) -> float:
    return len(pcm) / (SAMPLE_RATE * SAMPLE_WIDTH * CHANNELS)


def normalize_transcript(value: str) -> str:
    normalized = unicodedata.normalize("NFKC", value).lower()
    return "".join(character for character in normalized if character.isalnum())


def transcript_matches_dialogue(transcript: str, expected_dialogue: str) -> bool:
    """Allow short laugh syllables, but reject descriptive or conversational speech."""
    normalized = normalize_transcript(transcript)
    expected = normalize_transcript(expected_dialogue)
    if normalized == expected:
        return True

    if not expected:
        # A laughter-only response is commonly transcribed as vocalized syllables rather
        # than an empty string.  Keep this whitelist deliberately narrow: these characters
        # are plausible laugh/breath sounds, while labels such as "笑声"/"laughter" and
        # lexical interjections such as "哎呀" continue to fail closed.
        remaining = re.sub(r"[哈呵嘻嘿呼啊嗯唔呃咳哼]+", "", normalized)
        remaining = re.sub(
            r"(?:(?:ha+h*|he+h*|hi+h*|huh|hm+|ah+|oh+|uh+|whew)+)",
            "",
            remaining,
        )
        return remaining == ""

    # Realtime transcripts may spell a genuine nonverbal onset as ha/heh/huh or 哈/呵/嘻/嘿.
    # Only these compact syllables may surround the exact dialogue.  Words such as
    # "laughter", "笑声", "喘息", or any stage direction remain and therefore fail.
    without_chinese_laugh = re.sub(r"[哈呵嘻嘿]+", "", normalized)
    without_short_latin_laugh = re.sub(
        r"^(?:(?:ha+h*|he+h*|hi+h*|huh|hm)+)", "", without_chinese_laugh
    )
    without_short_latin_laugh = re.sub(
        r"(?:(?:ha+h*|he+h*|hi+h*|huh|hm)+)$", "", without_short_latin_laugh
    )
    return without_short_latin_laugh == expected


def render_take(
    client: Any,
    *,
    model: str,
    voice: str,
    prompt: str,
    instructions: str,
    max_output_tokens: int = DEFAULT_MAX_OUTPUT_TOKENS,
) -> tuple[bytes, str]:
    audio_chunks: list[bytes] = []
    transcript_chunks: list[str] = []

    with client.realtime.connect(model=model) as connection:
        connection.session.update(
            session={
                "type": "realtime",
                "model": model,
                "output_modalities": ["audio"],
                "audio": {
                    "output": {
                        "format": {"type": "audio/pcm", "rate": SAMPLE_RATE},
                        "voice": voice,
                    }
                },
                "instructions": instructions,
                "reasoning": {"effort": "minimal"},
                "max_output_tokens": max_output_tokens,
            }
        )
        connection.conversation.item.create(
            item={
                "type": "message",
                "role": "user",
                "content": [{"type": "input_text", "text": prompt}],
            }
        )
        connection.response.create(
            response={
                "output_modalities": ["audio"],
                "max_output_tokens": max_output_tokens,
            }
        )

        for event in connection:
            if event.type == "response.output_audio.delta":
                audio_chunks.append(base64.b64decode(event.delta))
            elif event.type == "response.output_audio_transcript.delta":
                transcript_chunks.append(event.delta)
            elif event.type == "error":
                message = getattr(getattr(event, "error", None), "message", repr(event))
                raise RuntimeError(f"Realtime API error: {message}")
            elif event.type == "response.done":
                response = getattr(event, "response", None)
                status = getattr(response, "status", None)
                if status not in (None, "completed"):
                    details = getattr(response, "status_details", None)
                    raise RuntimeError(f"Realtime response ended with {status}: {details}")
                break

    pcm = b"".join(audio_chunks)
    if not pcm:
        raise RuntimeError("Realtime response completed without audio data")
    return pcm, "".join(transcript_chunks).strip()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--count", type=int, default=10)
    parser.add_argument(
        "--max-attempts",
        type=int,
        help="Maximum raw generations; defaults to four times --count.",
    )
    parser.add_argument("--model", default="gpt-realtime-2.1")
    parser.add_argument("--voice", default="marin")
    parser.add_argument(
        "--voices",
        nargs="+",
        help="Cycle through these voices instead of using only --voice.",
    )
    parser.add_argument("--prefix", default="candidate")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT)
    parser.add_argument("--instructions", default=DEFAULT_INSTRUCTIONS)
    parser.add_argument("--expected-dialogue", default=DEFAULT_EXPECTED_DIALOGUE)
    parser.add_argument(
        "--max-output-tokens", type=int, default=DEFAULT_MAX_OUTPUT_TOKENS
    )
    parser.add_argument(
        "--min-duration", type=float, default=DEFAULT_MIN_DURATION_SECONDS
    )
    parser.add_argument(
        "--max-duration", type=float, default=DEFAULT_MAX_DURATION_SECONDS
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite candidate files that already exist.",
    )
    args = parser.parse_args()

    if not os.environ.get("OPENAI_API_KEY"):
        parser.error("OPENAI_API_KEY is required")
    if not 1 <= args.count <= 24:
        parser.error("--count must be between 1 and 24")
    if not 64 <= args.max_output_tokens <= 4096:
        parser.error("--max-output-tokens must be between 64 and 4096")
    if args.min_duration <= 0 or args.max_duration <= args.min_duration:
        parser.error("duration limits must satisfy 0 < min < max")

    maximum_attempts = args.max_attempts or args.count * 4
    if maximum_attempts < args.count:
        parser.error("--max-attempts must be at least --count")

    voices = args.voices or [args.voice]
    unsupported_voices = sorted(set(voices) - REALTIME_VOICES)
    if unsupported_voices:
        parser.error(
            "unsupported Realtime voice(s): "
            + ", ".join(unsupported_voices)
            + "; supported voices: "
            + ", ".join(sorted(REALTIME_VOICES))
        )
    target_paths = [
        args.out_dir / f"{args.prefix}_{index:02d}.wav"
        for index in range(1, args.count + 1)
    ]
    existing = [path for path in target_paths if path.exists()]
    if existing and not args.force:
        parser.error(
            f"{len(existing)} target file(s) already exist; use --force or a fresh --out-dir"
        )

    args.out_dir.mkdir(parents=True, exist_ok=True)
    try:
        from openai import OpenAI
    except ImportError as exc:
        parser.error(
            "openai[realtime] is required; run with "
            "`uv run --with 'openai[realtime]' python ...`"
        )
        raise AssertionError("unreachable") from exc
    client = OpenAI()
    accepted_takes: list[dict[str, object]] = []
    attempts: list[dict[str, object]] = []

    for attempt_index in range(1, maximum_attempts + 1):
        voice = voices[(attempt_index - 1) % len(voices)]
        try:
            pcm, transcript = render_take(
                client,
                model=args.model,
                voice=voice,
                prompt=args.prompt,
                instructions=args.instructions,
                max_output_tokens=args.max_output_tokens,
            )
        except Exception as exc:
            attempt_record = {
                "attempt": attempt_index,
                "voice": voice,
                "status": "rejected",
                "rejection_reasons": [
                    f"generation error: {exc.__class__.__name__}: {exc}"
                ],
            }
            attempts.append(attempt_record)
            print(
                f"attempt {attempt_index}: rejected | voice={voice} | "
                f"generation error: {exc.__class__.__name__}: {exc}"
            )
            continue
        duration = pcm_duration_seconds(pcm)
        rejection_reasons: list[str] = []
        if not transcript_matches_dialogue(transcript, args.expected_dialogue):
            rejection_reasons.append("unexpected transcript content")
        if duration < args.min_duration:
            rejection_reasons.append("too short")
        if duration > args.max_duration:
            rejection_reasons.append("too long")

        attempt_record: dict[str, object] = {
            "attempt": attempt_index,
            "voice": voice,
            "duration_seconds": round(duration, 3),
            "transcript": transcript,
            "normalized_transcript": normalize_transcript(transcript),
            "status": "rejected" if rejection_reasons else "accepted",
            "rejection_reasons": rejection_reasons,
        }

        if rejection_reasons:
            attempts.append(attempt_record)
            print(
                f"attempt {attempt_index}: rejected | {duration:.3f}s | "
                f"voice={voice} | transcript={transcript!r} | "
                + ", ".join(rejection_reasons)
            )
            continue

        accepted_index = len(accepted_takes) + 1
        filename = f"{args.prefix}_{accepted_index:02d}.wav"
        destination = args.out_dir / filename
        write_pcm_wav(destination, pcm)
        attempt_record["file"] = filename
        attempts.append(attempt_record)
        accepted_takes.append(attempt_record)
        print(
            f"candidate {accepted_index}/{args.count}: {duration:.3f}s | "
            f"voice={voice} | transcript={transcript!r}"
        )
        if len(accepted_takes) == args.count:
            break

    manifest = {
        "ai_generated": True,
        "model": args.model,
        "voices": voices,
        "sample_rate": SAMPLE_RATE,
        "channels": CHANNELS,
        "instructions": args.instructions,
        "prompt": args.prompt,
        "expected_dialogue": args.expected_dialogue,
        "validation": {
            "transcript_gate": "exact dialogue plus optional short laugh syllables only",
            "duration_seconds": [args.min_duration, args.max_duration],
            "manual_audition_required": True,
            "note": "Generation metadata is a hard content gate, not proof of naturalness.",
        },
        "requested_count": args.count,
        "accepted_count": len(accepted_takes),
        "attempt_count": len(attempts),
        "takes": accepted_takes,
        "attempts": attempts,
    }
    (args.out_dir / "realtime_candidates.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    if len(accepted_takes) != args.count:
        raise RuntimeError(
            f"Only {len(accepted_takes)} of {args.count} candidates passed after "
            f"{len(attempts)} attempts; see realtime_candidates.json"
        )


if __name__ == "__main__":
    main()
