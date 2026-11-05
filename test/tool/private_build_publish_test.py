import importlib.util
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[2] / 'tool'))
import publish_private_build as publish

RUN = {'id': 123, 'run_number': 9, 'run_attempt': 2, 'head_sha': 'a' * 40, 'head_branch': 'main', 'event': 'push', 'path': '.github/workflows/build.yml', 'head_repository': {'full_name': publish.REPOSITORY}}

class PrivateBuildPublishTest(unittest.TestCase):
    def test_development_metadata_is_bound_to_original_run(self):
        data = publish.metadata_for_run(RUN, '0.1.0+1')
        self.assertEqual(data['release_tag'], 'ci-123-2')
        self.assertEqual(data['private_release_tag'], 'ci-123-2')
        self.assertEqual(data['version'], '0.1.0-dev.9.2+aaaaaaa')
    def test_stable_attempts_have_distinct_private_tags(self):
        data = publish.metadata_for_run({**RUN, 'head_branch':'v0.1.0'}, '0.1.0+1')
        self.assertEqual(data['release_tag'], 'v0.1.0')
        self.assertEqual(data['private_release_tag'], 'ci-123-2')
    def test_foreign_and_pull_request_workflows_cannot_publish(self):
        for run in [{**RUN, 'head_repository': {'full_name':'outside/fork'}}, {**RUN, 'event':'pull_request'}, {**RUN, 'path':'.github/workflows/other.yml'}]:
            with self.subTest(run=run):
                with self.assertRaises(ValueError): publish.metadata_for_run(run, '0.1.0+1')
    def test_artifact_selection_never_mixes_attempts(self):
        artifacts = [{'name': 'binary-linux-x64-1', 'expired': False}, {'name': 'binary-linux-x64-2', 'expired': False}]
        self.assertEqual(publish.artifact_pattern(artifacts, 2), 'binary-*-2')
        self.assertIsNone(publish.artifact_pattern(artifacts, 3))
        legacy = [{'name': 'binary-android', 'expired': False}]
        self.assertEqual(publish.artifact_pattern(legacy, 1), 'binary-*')
        self.assertIsNone(publish.artifact_pattern(legacy, 2))
    def test_staging_excludes_unknown_files_and_rejects_duplicate_targets(self):
        import tempfile
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            source = root / 'download'; source.mkdir()
            (source / 'source.dart').write_text('not a binary')
            target = 'vnlf-social-0.1.0-linux-arm64.tar.gz'
            (source / target).write_bytes(b'archive')
            dest = root / 'dist'
            publish.stage_assets(source, dest, '0.1.0')
            self.assertEqual([p.name for p in dest.iterdir()], [target])
            duplicate = source / 'another';duplicate.mkdir()
            (duplicate / target).write_bytes(b'conflicting archive')
            with self.assertRaises(ValueError): publish.stage_assets(source, root / 'other', '0.1.0')
