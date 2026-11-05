import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
GUARD = ROOT / 'tool' / 'with_build_slot.sh'

class ResourceGuardTest(unittest.TestCase):
    def test_guard_limits_child_cpu_affinity(self):
        with tempfile.TemporaryDirectory() as temp:
            env = {**os.environ, 'VNLF_BUILD_LOCK_FILE': str(Path(temp) / 'slot')}
            result = subprocess.run([str(GUARD), 'python3', '-c', 'import os; print(len(os.sched_getaffinity(0)))'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertLessEqual(int(result.stdout.strip()), 2)

    def test_second_job_is_refused_while_first_owns_slot(self):
        with tempfile.TemporaryDirectory() as temp:
            marker = Path(temp) / 'ready'
            env = {**os.environ, 'VNLF_BUILD_LOCK_FILE': str(Path(temp) / 'slot')}
            first = subprocess.Popen([str(GUARD), 'python3', '-c', 'import pathlib,sys,time; pathlib.Path(sys.argv[1]).touch(); time.sleep(0.6)', str(marker)], env=env)
            try:
                deadline = time.monotonic() + 3
                while not marker.exists() and time.monotonic() < deadline:
                    time.sleep(0.02)
                self.assertTrue(marker.exists())
                second = subprocess.run([str(GUARD), 'python3', '-c', 'raise SystemExit(0)'], env=env, capture_output=True, text=True)
                self.assertEqual(second.returncode, 75)
                self.assertIn('local build slot', second.stderr)
            finally:
                first.wait(timeout=5)
