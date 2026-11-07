import importlib.util
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
import os
import base64
import contextlib
import io
import tempfile
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).parents[2] / 'tool'))
import publish_private_build as publish

RUN = {'id': 123, 'run_number': 9, 'run_attempt': 2, 'head_sha': 'a' * 40, 'head_branch': 'main', 'event': 'push', 'path': '.github/workflows/build.yml', 'head_repository': {'full_name': publish.REPOSITORY}}

class PrivateBuildPublishTest(unittest.TestCase):
    def test_manual_tag_recovery_uses_verified_original_context(self):
        run = {**RUN, 'event': 'workflow_dispatch', 'head_branch': 'v0.1.0'}
        context = {'repository': publish.REPOSITORY, 'sha': run['head_sha'],
                   'run_id': '123', 'attempt': '2', 'ref_name': 'v0.1.0',
                   'event': 'workflow_dispatch', 'ref_type': 'tag'}
        data = publish.metadata_for_run(run, '0.1.0+1', context=context)
        self.assertEqual(data['version'], '0.1.0')
        self.assertEqual(data['is_stable'], 'true')
        branch_data = publish.metadata_for_run(run, '0.1.0+1', context={**context, 'ref_type': 'branch'})
        self.assertEqual(branch_data['is_stable'], 'false')
        for changes in ({'sha': 'b' * 40}, {'attempt': '0'}, {'attempt': '3'}, {'run_id': '124'},
                        {'repository': 'outside/fork'}, {'ref_name': 'main'},
                        {'event': 'push'}, {'ref_type': 'unknown'}):
            with self.assertRaises(ValueError):
                publish.metadata_for_run(run, '0.1.0+1', context={**context, **changes})

    def test_failed_job_rerun_retains_version_but_never_overwrites_prior_release(self):
        run = {**RUN, 'event': 'workflow_dispatch'}
        context = {'repository': publish.REPOSITORY, 'sha': run['head_sha'],
                   'run_id': '123', 'attempt': '1', 'ref_name': 'main',
                   'event': 'workflow_dispatch', 'ref_type': 'branch'}
        data = publish.metadata_for_run(run, '0.1.0+1', context=context)
        self.assertEqual(data['version'], '0.1.0-dev.9.1+aaaaaaa')
        self.assertEqual(data['private_release_tag'], 'ci-123-2')
        self.assertEqual(data['release_tag'], 'ci-123-2')
        artifacts = [{'name': 'build-context-1', 'expired': False},
                     {'name': 'build-context-3', 'expired': False}]
        def download(*args, env=None):
            self.assertEqual(args[args.index('--pattern') + 1], 'build-context-1')
            Path(args[args.index('--dir') + 1], 'build-context.json').write_text(__import__('json').dumps(context))
        with patch.object(publish, 'run_command', side_effect=download):
            self.assertEqual(publish.load_context(run, publish.REPOSITORY, artifacts), context)

    def test_legacy_ambiguous_manual_version_ref_is_not_guessed(self):
        with self.assertRaises(ValueError):
            publish.metadata_for_run({**RUN, 'event': 'workflow_dispatch', 'head_branch': 'v0.1.0'}, '0.1.0+1')

    def test_source_and_destination_commands_use_separate_tokens(self):
        source = 'luank3/vnlfsocialapp'
        run = {**RUN, 'head_repository': {'full_name': source}, 'status': 'completed'}
        calls = []
        commands = []
        def api(path, env=None):
            calls.append((path, env))
            if path.endswith('/actions/runs/123'): return run
            if '/contents/pubspec.yaml?' in path:
                return {'content': base64.b64encode(b'version: 0.1.0+1\n').decode()}
            if '/artifacts?' in path:
                return {'artifacts': [{'name': 'binary-linux-x64-2', 'expired': False}]}
            if '/releases/' in path: return {'assets': []}
            return {'private': True}
        def command(*args, env=None): commands.append((args, env))
        with tempfile.TemporaryDirectory() as directory:
            Path(directory, 'vnlf-social-0.1.0-dev.9.2+aaaaaaa-linux-x64.tar.gz').write_bytes(b'fixture')
            argv = ['publish', '--repo', source, '--release-repo', publish.REPOSITORY,
                    '--run-id', '123', '--download-dir', directory]
            with patch.dict(os.environ, {'GH_TOKEN': 'fixture-source', 'RELEASE_GH_TOKEN': 'fixture-destination'}), \
                 patch.object(sys, 'argv', argv), patch.object(publish, 'api', side_effect=api), \
                 patch.object(publish, 'run_command', side_effect=command), \
                 patch.object(publish.subprocess, 'run', return_value=SimpleNamespace(returncode=0)), \
                 patch.object(publish.subprocess, 'check_output', return_value=f'https://api.github.com/repos/{publish.REPOSITORY}/releases/9\n'), \
                 contextlib.redirect_stdout(io.StringIO()):
                publish.main()
        for path, environment in calls:
            if source in path:
                self.assertIsNone(environment)
            else:
                self.assertEqual(environment['GH_TOKEN'], 'fixture-destination')
        self.assertTrue(commands)
        for args, environment in commands:
            self.assertEqual(args[:3], ('gh', 'release', 'upload'))
            self.assertEqual(environment['GH_TOKEN'], 'fixture-destination')

    def test_mirror_token_does_not_replace_source_authentication(self):
        with patch.dict(os.environ, {'GH_TOKEN': 'fixture-source', 'RELEASE_GH_TOKEN': 'fixture-destination'}):
            destination = publish.release_environment()
            self.assertEqual(destination['GH_TOKEN'], 'fixture-destination')
            self.assertNotIn('RELEASE_GH_TOKEN', destination)
            self.assertEqual(os.environ['GH_TOKEN'], 'fixture-source')

    def test_personal_runs_are_bound_to_the_explicit_source_repository(self):
        personal = {**RUN, 'head_repository': {'full_name': 'luank3/vnlfsocialapp'}}
        data = publish.metadata_for_run(personal, '0.1.0+1', 'luank3/vnlfsocialapp')
        self.assertEqual(data['private_release_tag'], 'ci-123-2')
        with self.assertRaises(ValueError):
            publish.metadata_for_run(RUN, '0.1.0+1', 'luank3/vnlfsocialapp')
        with self.assertRaises(ValueError):
            publish.metadata_for_run({**RUN, 'head_repository': {'full_name': 'outside/fork'}},
                                     '0.1.0+1', 'outside/fork')

    def test_resuming_upload_skips_only_verified_complete_assets(self):
        local = [{'name': 'binary.zip', 'size': 10, 'sha256': 'a' * 64}, {'name': 'other.zip', 'size': 20, 'sha256': 'b' * 64}]
        remote = [{'name': 'binary.zip', 'size': 10, 'digest': 'sha256:' + 'a' * 64, 'state': 'uploaded'}]
        self.assertEqual(publish.pending_uploads(local, remote), ['other.zip'])
        for changes in [{'digest': 'sha256:' + 'c' * 64}, {'state': 'starter'}, {'size': 9}, {'digest': None}]:
            self.assertEqual(publish.pending_uploads(local, [{**remote[0], **changes}]), ['binary.zip', 'other.zip'])
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
