import hashlib
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location(
    'precache_android_build',
    Path(__file__).parents[2] / 'tool/precache_android_build.py')
precache = importlib.util.module_from_spec(spec)
spec.loader.exec_module(precache)

PAYLOAD = b'synthetic libmpv jar ' * 1000
PAYLOAD_MD5 = hashlib.md5(PAYLOAD).hexdigest()


class Responses:
    def __init__(self, *bodies):
        self.bodies = list(bodies)
        self.requests = []

    def __call__(self, request, timeout):
        self.requests.append((request, timeout))
        body = self.bodies.pop(0)
        if isinstance(body, Exception):
            raise body
        return io.BytesIO(body)


class FetchTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dest = Path(self.tmp.name) / 'cache' / 'default-arm64-v8a.jar'
        self.sleeps = []

    def tearDown(self):
        self.tmp.cleanup()

    def test_writes_a_verified_download(self):
        opener = Responses(PAYLOAD)
        precache.fetch('https://example.invalid/a.jar', self.dest, PAYLOAD_MD5,
                       opener=opener, sleep=self.sleeps.append)

        self.assertEqual(self.dest.read_bytes(), PAYLOAD)
        request, timeout = opener.requests[0]
        self.assertEqual(request.get_header('User-agent'), 'VNLF-CI/1.0')
        self.assertEqual(timeout, 120)
        self.assertEqual(self.sleeps, [])

    def test_retries_a_failed_or_corrupt_download(self):
        opener = Responses(OSError('reset'), b'x' * 20000, PAYLOAD)
        precache.fetch('https://example.invalid/a.jar', self.dest, PAYLOAD_MD5,
                       opener=opener, sleep=self.sleeps.append)

        self.assertEqual(self.dest.read_bytes(), PAYLOAD)
        self.assertEqual(self.sleeps, [4, 8])

    def test_gives_up_without_writing_a_bad_file(self):
        opener = Responses(*[b'x' * 20000] * 3)
        with self.assertRaises(SystemExit):
            precache.fetch('https://example.invalid/a.jar', self.dest,
                           PAYLOAD_MD5, opener=opener,
                           sleep=self.sleeps.append, attempts=3)

        self.assertFalse(self.dest.exists())
        self.assertEqual(self.sleeps, [4, 8, 12])


class GradleBootstrapTest(unittest.TestCase):
    def test_retries_until_the_wrapper_runs(self):
        codes = [1, 0]
        calls = []
        sleeps = []

        def run(args, cwd):
            calls.append((args, cwd))
            return subprocess.CompletedProcess(args, codes.pop(0))

        precache.bootstrap_gradle(run=run, sleep=sleeps.append)

        self.assertEqual(calls, [(['./gradlew', '--version'], 'android')] * 2)
        self.assertEqual(sleeps, [4])

    def test_stops_after_the_last_attempt(self):
        def run(args, cwd):
            return subprocess.CompletedProcess(args, 1)

        with self.assertRaises(SystemExit):
            precache.bootstrap_gradle(run=run, sleep=lambda _: None,
                                      attempts=2)


if __name__ == '__main__':
    unittest.main()
