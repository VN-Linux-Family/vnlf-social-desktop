import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    'sync_lucide_icons',
    Path(__file__).parents[2] / 'tool/sync_lucide_icons.py')
lucide = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lucide)

NODES = {
    'arrow-up-right': [['path', {'d': 'M7 7h10v10', 'key': 'a'}],
                       ['path', {'d': 'M7 17 17 7', 'key': 'b'}]],
    'folder-git-2': [['circle', {'cx': '13', 'cy': '12', 'r': '2', 'key': 'c'}]],
}


class GenerateTest(unittest.TestCase):
    def test_names_follow_dart_camel_case(self):
        self.assertEqual(lucide.dart_name('arrow-up-right'), 'arrowUpRight')
        self.assertEqual(lucide.dart_name('folder-git-2'), 'folderGit2')
        self.assertEqual(lucide.dart_name('x'), 'x')

    def test_embeds_outlines_without_react_keys_and_keeps_the_license(self):
        out = lucide.generate(NODES, 'ISC License\n\nCopyright notice.',
                              ['folder-git-2', 'arrow-up-right'])

        self.assertIn("arrowUpRight('<path d=\"M7 7h10v10\"/>"
                      "<path d=\"M7 17 17 7\"/>'),", out)
        self.assertIn("folderGit2('<circle cx=\"13\" cy=\"12\" r=\"2\"/>');",
                      out)
        self.assertNotIn('key=', out)
        self.assertIn('// ISC License', out)
        self.assertIn('// Copyright notice.', out)

    def test_rejects_an_unknown_icon(self):
        with self.assertRaises(ValueError):
            lucide.generate(NODES, 'ISC', ['missing-icon'])


if __name__ == '__main__':
    unittest.main()
