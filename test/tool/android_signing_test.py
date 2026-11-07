import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('prepare_android_signing', ROOT / 'tool' / 'prepare_android_signing.py')
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)

class AndroidSigningTest(unittest.TestCase):
    def test_java_properties_preserves_whitespace_unicode_and_escapes(self):
        self.assertEqual(signing.property_value(' ặ:=\\\n'), r'\ \u1eb7\:\=\\\n')

    def test_stable_release_refuses_missing_signing_without_creating_properties(self):
        with tempfile.TemporaryDirectory() as temp:
            env = {key: value for key, value in os.environ.items() if not key.startswith('ANDROID_')}
            env['RUNNER_TEMP'] = temp
            result = subprocess.run(['python3', str(ROOT / 'tool' / 'prepare_android_signing.py'), '--stable', 'true'], cwd=temp, env=env, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('No development signing fallback', result.stderr)
            self.assertFalse((Path(temp) / 'android/app/key.properties').exists())
