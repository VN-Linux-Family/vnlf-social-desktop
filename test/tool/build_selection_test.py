from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).parents[2] / 'tool'))
import build_selection as selection


class BuildSelectionTest(unittest.TestCase):
    def test_manual_default_builds_one_linux_target(self):
        matrix, android = selection.select_targets('workflow_dispatch', 'branch', 'linux-x64')
        self.assertEqual(matrix['include'], [
            {'platform': 'linux', 'arch': 'x64', 'runner': 'ubuntu-24.04'}])
        self.assertFalse(android)

    def test_android_only_does_not_allocate_desktop_runners(self):
        matrix, android = selection.select_targets('workflow_dispatch', 'branch', 'android')
        self.assertEqual(matrix['include'], [])
        self.assertTrue(android)

    def test_every_tag_build_keeps_all_nine_outputs(self):
        for event in ('push', 'workflow_dispatch'):
            for requested in ('linux-x64', 'android', 'all'):
                matrix, android = selection.select_targets(event, 'tag', requested)
                self.assertEqual(len(matrix['include']), 6)
                self.assertEqual({(row['platform'], row['arch']) for row in matrix['include']},
                                 {(p, a) for p in ('linux', 'windows', 'macos') for a in ('x64', 'arm64')})
                self.assertTrue(android)

    def test_full_manual_matrix_and_invalid_selection(self):
        self.assertEqual(selection.select_targets('workflow_dispatch', 'branch', 'all'),
                         selection.select_targets('push', 'tag', 'all'))
        for event, ref, target in [('push', 'branch', 'all'), ('pull_request', 'branch', 'all'),
                                   ('workflow_dispatch', 'branch', 'unknown')]:
            with self.assertRaises(ValueError):
                selection.select_targets(event, ref, target)
