"""Generates the game's feedback sounds.

The sounds are committed, not generated at build time — but they are generated
*here* rather than sourced, so they can be reasoned about and changed. Every
one is a short envelope-shaped sine chord: no clicks, no licensing, no
megabytes.

    python3 tool/sound_authoring/generate_sounds.py

Design notes, since they are choices rather than facts:

- **Correct rises, wrong falls.** The direction carries the meaning even at low
  volume or through a phone speaker in a noisy room.
- **Wrong is quieter and shorter than correct.** A game that punishes loudly is
  unpleasant to play badly, and playing badly is how a learner starts.
- **Every tone is enveloped.** A sine that starts at full amplitude clicks, and
  the click is the loudest part of it.
"""

import math
import os
import struct
import wave

SAMPLE_RATE = 44_100
OUT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..",
    "core", "feedback", "feedback_impl", "assets", "sounds",
)

# Attack long enough to kill the click, release long enough to avoid a thud.
ATTACK = 0.006
RELEASE = 0.045


def envelope(index: int, total: int) -> float:
    """A smooth attack and release, flat in between."""
    attack = max(1, int(ATTACK * SAMPLE_RATE))
    release = max(1, int(RELEASE * SAMPLE_RATE))

    if index < attack:
        return index / attack
    if index > total - release:
        return max(0.0, (total - index) / release)
    return 1.0


def tone(frequency: float, seconds: float, gain: float) -> list[float]:
    total = int(seconds * SAMPLE_RATE)
    samples = []
    for i in range(total):
        angle = 2 * math.pi * frequency * (i / SAMPLE_RATE)
        # A touch of second harmonic: a bare sine reads as a test tone, this
        # reads as an instrument.
        value = math.sin(angle) + 0.18 * math.sin(2 * angle)
        samples.append(value * gain * envelope(i, total))
    return samples


def write(name: str, samples: list[float]) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)

    peak = max((abs(s) for s in samples), default=1.0) or 1.0
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s / peak * 0.72)) * 32767))
        for s in samples
    )

    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(frames)

    print(f"{name}: {len(samples) / SAMPLE_RATE:.3f}s, {len(frames)} bytes")


def main() -> None:
    # Rising major third: unambiguous, and short enough not to cover the next
    # clue being read.
    write("correct.wav", tone(880.0, 0.075, 0.9) + tone(1318.5, 0.11, 0.85))

    # Falling, lower, quieter, and over quickly.
    write("wrong.wav", tone(233.1, 0.075, 0.55) + tone(174.6, 0.13, 0.5))

    # A major triad, because the end of a round has earned three notes.
    write(
        "finished.wav",
        tone(523.3, 0.1, 0.8) + tone(659.3, 0.1, 0.8) + tone(784.0, 0.22, 0.85),
    )


if __name__ == "__main__":
    main()
