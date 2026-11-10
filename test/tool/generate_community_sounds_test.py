import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    'generate_community_sounds', ROOT / 'tool' / 'generate_community_sounds.py')
sounds = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sounds)


def read(path):
    with wave.open(str(path), 'rb') as source:
        frames = source.readframes(source.getnframes())
        return source.getframerate(), source.getnchannels(), struct.unpack(f'<{len(frames) // 2}h', frames)


class CommunitySoundsTest(unittest.TestCase):
    def test_the_envelope_follows_the_website_ramps(self):
        self.assertAlmostEqual(sounds.gain(0), 0.0001)
        self.assertAlmostEqual(sounds.gain(0.012), 0.045)
        self.assertAlmostEqual(sounds.gain(0.1399999), 0.0001, places=6)
        self.assertEqual(sounds.gain(0.16), 0.0)

    def test_a_message_lasts_until_its_second_note_stops(self):
        data = sounds.samples((660, 880))
        self.assertEqual(len(data), round(0.26 * sounds.RATE))
        self.assertLessEqual(max(abs(value) for value in data), round(2 * 0.045 * 32767))

    def test_the_committed_assets_match_the_generator(self):
        with tempfile.TemporaryDirectory() as temp:
            self.assertEqual(sounds.main(['generate', temp]), 0)
            for name in sounds.SOUNDS:
                fresh = read(Path(temp) / name)
                committed = read(ROOT / 'assets' / 'sounds' / name)
                self.assertEqual(fresh[:2], committed[:2], name)
                self.assertEqual(len(fresh[2]), len(committed[2]), name)
                # The platform's sine may differ in its last bit.
                self.assertLessEqual(max(abs(a - b) for a, b in zip(fresh[2], committed[2])), 1, name)


if __name__ == '__main__':
    unittest.main()
