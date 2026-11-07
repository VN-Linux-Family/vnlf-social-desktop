import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('release_metadata', ROOT / 'tool' / 'release_metadata.py')
metadata = importlib.util.module_from_spec(spec)
spec.loader.exec_module(metadata)

class ReleaseMetadataTest(unittest.TestCase):
    def test_ci_version_has_numeric_platform_build_number(self):
        data = metadata.compute_metadata('0.4.2+7', 'a' * 40, 93, 2, 'branch', 'main', '123456')
        self.assertEqual(data['version'], '0.4.2-dev.93.2+aaaaaaa')
        self.assertEqual(data['build_name'], '0.4.2')
        self.assertEqual(data['build_number'], '93')
        self.assertEqual(data['release_tag'], 'ci-123456-2')
        self.assertEqual(data['is_stable'], 'false')

    def test_stable_tag_must_match_pubspec(self):
        data = metadata.compute_metadata('0.4.2+7', 'b' * 40, 94, 1, 'tag', 'v0.4.2', '123457')
        self.assertEqual(data['version'], '0.4.2')
        self.assertEqual(data['is_stable'], 'true')
        self.assertEqual(data['release_tag'], 'v0.4.2')
        with self.assertRaises(ValueError):
            metadata.compute_metadata('0.4.2+7', 'b' * 40, 94, 1, 'tag', 'v0.4.3', '123457')

    def test_release_candidates_remain_private_prereleases(self):
        data = metadata.compute_metadata('0.4.2+7', 'c' * 40, 95, 1, 'tag', 'v0.4.2-rc.1', '123458')
        self.assertEqual(data['version'], '0.4.2-rc.1')
        self.assertEqual(data['is_stable'], 'false')

    def test_invalid_or_overflowing_build_number_is_not_silently_rewritten(self):
        for run in [0, -1, 65536]:
            with self.assertRaises(ValueError):
                metadata.compute_metadata('0.4.2', 'a' * 40, run, 1, 'branch', 'main', '123')

    def test_manifest_covers_each_requested_architecture_with_checksums(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            names = [
                'vnlf-social-0.4.2-linux-x64.tar.gz', 'vnlf-social-0.4.2-linux-arm64.tar.gz',
                'vnlf-social-0.4.2-macos-x64.zip', 'vnlf-social-0.4.2-macos-arm64.zip',
                'vnlf-social-0.4.2-windows-x64.zip', 'vnlf-social-0.4.2-windows-arm64.zip',
                'vnlf-social-0.4.2-android-armv7.apk', 'vnlf-social-0.4.2-android-arm64.apk',
                'vnlf-social-0.4.2-android-x64.apk',
            ]
            for name in names:
                (root / name).write_bytes(b'build artifact')
            manifest = metadata.asset_manifest(root, '0.4.2', 96, 'a' * 40, require_complete=True)
            self.assertEqual(len(manifest['assets']), 9)
            self.assertTrue(all(asset['size'] == 14 and len(asset['sha256']) == 64 for asset in manifest['assets']))
            (root / names[0]).unlink()
            with self.assertRaises(ValueError):
                metadata.asset_manifest(root, '0.4.2', 96, 'a' * 40, require_complete=True)
