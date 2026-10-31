#!/usr/bin/env python3
"""Writes correct.wav, the chime for a right answer in a lesson.

The sound is synthesized here from nothing but sine waves, so there is no license to track.
Standard library only, and the output is the same on every run.

    python3 generate_correct.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
PEAK = 0.7  # headroom; the app plays it at volume 0.5
FADE_IN = 0.004
FADE_OUT = 0.04

# Rising C major arpeggio, high and quick: (start seconds, frequency Hz, loudness, decay per second)
NOTES = [
    (0.000, 1046.50, 0.75, 16.0),  # C6
    (0.075, 1318.51, 0.85, 14.0),  # E6
    (0.150, 1567.98, 1.00, 9.0),  # G6, rings out
]
LENGTH = 0.40

# A little of the upper partials makes it a small bell instead of a test tone.
PARTIALS = [(1.0, 1.0), (2.0, 0.22), (3.0, 0.06)]


def sample_at(t: float) -> float:
    total = 0.0
    for start, freq, loudness, decay in NOTES:
        since = t - start
        if since < 0:
            continue
        attack = min(since / 0.003, 1.0)
        body = sum(gain * math.sin(2 * math.pi * freq * mult * since) for mult, gain in PARTIALS)
        total += loudness * attack * math.exp(-decay * since) * body
    return total


def render() -> list[float]:
    count = int(RATE * LENGTH)
    samples = [sample_at(i / RATE) for i in range(count)]

    # No clicks: both ends reach exactly zero.
    for i in range(count):
        t = i / RATE
        samples[i] *= min(t / FADE_IN, 1.0) * min((LENGTH - t - 1 / RATE) / FADE_OUT, 1.0)

    top = max(abs(s) for s in samples)
    return [s / top * PEAK for s in samples]


def main() -> None:
    path = Path(__file__).with_name("correct.wav")
    pcm = b"".join(struct.pack("<h", round(s * 32767)) for s in render())
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(pcm)
    print(f"wrote {path.name}: {len(pcm) / 2 / RATE:.3f}s, {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
