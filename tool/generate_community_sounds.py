#!/usr/bin/env python3
"""Write the website's community chimes as WAV files in assets/sounds/.

The website (`apps/web/components/social/community-sounds.tsx`) synthesizes its
chimes with Web Audio: one sine oscillator per note, the notes 100 ms apart.
Each note's gain ramps exponentially from 0.0001 to 0.045 in 12 ms, back down
to 0.0001 at 140 ms, and the note stops at 160 ms. A message plays 660 and
880 Hz; someone joining a voice room plays 440, 660 and 880 Hz.

Usage: python3 tool/generate_community_sounds.py [output-directory]
"""

import math
import struct
import sys
import wave
from pathlib import Path

RATE = 48000
NOTE_GAP = 0.1
ATTACK = 0.012
RELEASE = 0.14
STOP = 0.16
FLOOR = 0.0001
PEAK = 0.045

SOUNDS = {
    'message.wav': (660, 880),
    'voice-join.wav': (440, 660, 880),
}


def gain(elapsed):
    """The gain of one note, `elapsed` seconds after it starts."""
    if elapsed < 0 or elapsed >= STOP:
        return 0.0
    if elapsed < ATTACK:
        return FLOOR * (PEAK / FLOOR) ** (elapsed / ATTACK)
    if elapsed < RELEASE:
        return PEAK * (FLOOR / PEAK) ** ((elapsed - ATTACK) / (RELEASE - ATTACK))
    return FLOOR


def samples(notes):
    """16-bit samples of the notes, each starting NOTE_GAP after the last."""
    length = round((NOTE_GAP * (len(notes) - 1) + STOP) * RATE)
    result = []
    for index in range(length):
        time = index / RATE
        value = 0.0
        for number, frequency in enumerate(notes):
            elapsed = time - number * NOTE_GAP
            if 0 <= elapsed < STOP:
                value += gain(elapsed) * math.sin(2 * math.pi * frequency * elapsed)
        result.append(round(value * 32767))
    return result


def write(path, notes):
    data = samples(notes)
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(struct.pack(f'<{len(data)}h', *data))


def main(argv):
    root = Path(__file__).resolve().parents[1]
    target = Path(argv[1]) if len(argv) > 1 else root / 'assets' / 'sounds'
    target.mkdir(parents=True, exist_ok=True)
    for name, notes in SOUNDS.items():
        write(target / name, notes)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
