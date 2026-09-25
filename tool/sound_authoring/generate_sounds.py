"""Generates the game's feedback sounds.

The sounds are committed, not generated at build time — but they are generated
*here* rather than sourced, so they can be reasoned about and changed. Every
one is a short envelope-shaped sine chord: no clicks, no licensing, no
megabytes.

    python3 tool/sound_authoring/generate_sounds.py

Design notes, since they are choices rather than facts:

- **Correct rises, wrong falls.** The direction carries the meaning even at low
  volume or through a phone speaker in a noisy room.
- **Correct is a celebration.** Four ringing notes, not two beeps: finding
  a word is the moment the game exists for.
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


def bell(frequency: float, seconds: float, gain: float) -> list[float]:
    """A struck, ringing note: instant attack, then an exponential decay.

    The partials make it a bell rather than a beep — the octave carries the
    body, the faint inharmonic one on top is the sparkle.
    """
    total = int(seconds * SAMPLE_RATE)
    attack = int(0.004 * SAMPLE_RATE)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        angle = 2 * math.pi * frequency * t
        value = (
            math.sin(angle)
            + 0.30 * math.sin(2 * angle) * math.exp(-t / 0.09)
            + 0.08 * math.sin(4.2 * angle) * math.exp(-t / 0.05)
        )
        level = min(1.0, i / attack) * math.exp(-t / 0.16)
        # A short fade at the very end, so the tail never clicks off.
        level *= min(1.0, (total - i) / (0.02 * SAMPLE_RATE))
        samples.append(value * gain * level)
    return samples


def mix(voices: list[tuple[float, list[float]]]) -> list[float]:
    """Overlays each (start in seconds, samples) voice into one track."""
    length = max(int(start * SAMPLE_RATE) + len(v) for start, v in voices)
    out = [0.0] * length
    for start, samples in voices:
        offset = int(start * SAMPLE_RATE)
        for i, value in enumerate(samples):
            out[offset + i] += value
    return out


def write(name: str, samples: list[float], loudness: float = 0.72) -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)

    peak = max((abs(s) for s in samples), default=1.0) or 1.0
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s / peak * loudness)) * 32767))
        for s in samples
    )

    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(SAMPLE_RATE)
        out.writeframes(frames)

    print(f"{name}: {len(samples) / SAMPLE_RATE:.3f}s, {len(frames)} bytes")


def main() -> None:
    # A found word should sound like a small win, not an acknowledgement: a
    # quick rising major arpeggio of ringing bell notes, each still sounding
    # as the next lands, so the four blend into one bright sparkle. Rising, so
    # it still means "right" through a phone speaker in a noisy room; done in
    # about half a second, before the next clue needs the player's attention.
    # Louder than the other cues on purpose — this is the one to celebrate.
    write(
        "correct.wav",
        mix([
            (0.000, bell(1046.5, 0.36, 0.55)),  # C6
            (0.055, bell(1318.5, 0.36, 0.55)),  # E6
            (0.110, bell(1568.0, 0.38, 0.60)),  # G6
            (0.165, bell(2093.0, 0.40, 0.70)),  # C7, the top of the sparkle
        ]),
        loudness=0.9,
    )

    # Falling, lower, quieter, and over quickly.
    write("wrong.wav", tone(233.1, 0.075, 0.55) + tone(174.6, 0.13, 0.5))

    # A major triad, because the end of a round has earned three notes.
    write(
        "finished.wav",
        tone(523.3, 0.1, 0.8) + tone(659.3, 0.1, 0.8) + tone(784.0, 0.22, 0.85),
    )


if __name__ == "__main__":
    main()
