import importlib.util
from pathlib import Path
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('linux_dependencies', ROOT / 'tool/install_linux_dependencies.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class LinuxDependenciesTest(unittest.TestCase):
    def test_deb822_mirror_change_preserves_signature_fields_and_other_repositories(self):
        text = 'Types: deb\nURIs: http://azure.archive.ubuntu.com/ubuntu/\nSuites: noble noble-updates\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n\nURIs: https://packages.microsoft.com/repos/code\n'
        changed = module.rewrite_archive(text, 'x64', 'https://mirrors.edge.kernel.org/ubuntu')
        self.assertIn('URIs: https://mirrors.edge.kernel.org/ubuntu/', changed)
        self.assertIn('Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg', changed)
        self.assertIn('https://packages.microsoft.com/repos/code', changed)
        self.assertIn('Suites: noble noble-updates', changed)

    def test_legacy_source_rewrites_only_the_exact_archive_prefix(self):
        text = 'deb [signed-by=/key.gpg] https://archive.ubuntu.com/ubuntu noble main\n# https://archive.ubuntu.com/ubuntu-extra\n'
        changed = module.rewrite_archive(text, 'x64', module.X64_MIRRORS[0])
        self.assertIn('deb [signed-by=/key.gpg] ' + module.X64_MIRRORS[0] + ' noble main', changed)
        self.assertIn('https://archive.ubuntu.com/ubuntu-extra', changed)

    def test_arm_sources_keep_the_ports_archive_and_do_not_use_an_amd64_mirror(self):
        text = 'URIs: http://ports.ubuntu.com/ubuntu-ports\n'
        self.assertEqual(module.rewrite_archive(text, 'arm64', module.ARM_MIRROR), 'URIs: https://ports.ubuntu.com/ubuntu-ports\n')
        self.assertNotIn('azure', module.rewrite_archive(text, 'arm64', module.ARM_MIRROR))

    def test_failed_download_switches_mirror_before_one_offline_install(self):
        calls = []
        with tempfile.TemporaryDirectory() as directory:
            sources = Path(directory)
            (sources / 'sources.list').write_text('deb http://azure.archive.ubuntu.com/ubuntu noble main\n')
            downloads = 0
            def run(argv, timeout):
                nonlocal downloads
                calls.append((argv, timeout))
                if '--download-only' in argv:
                    downloads += 1
                    return downloads == 2
                return True
            result = module.install_dependencies('x64', sources, run=run)
            self.assertTrue(result)
            self.assertIn(module.X64_MIRRORS[1], (sources / 'sources.list').read_text())
        installs = [argv for argv, _ in calls if '--no-download' in argv]
        self.assertEqual(len(installs), 1)
        self.assertEqual(downloads, 2)
        self.assertIn('--download-only', calls[-2][0])
        self.assertTrue(all(timeout <= 300 for _, timeout in calls))
        self.assertTrue(all('Acquire::ForceIPv4=true' in argv for argv, _ in calls))

    def test_no_package_install_when_every_download_fails(self):
        calls = []
        with tempfile.TemporaryDirectory() as directory:
            def run(argv, timeout):
                calls.append(argv)
                return '--download-only' not in argv
            self.assertFalse(module.install_dependencies('x64', Path(directory), run=run))
        self.assertFalse(any('--no-download' in argv for argv in calls))
        self.assertEqual(sum('--download-only' in argv for argv in calls), len(module.X64_MIRRORS))

    def test_install_failure_is_reported_without_repeating_package_mutations(self):
        calls = []
        with tempfile.TemporaryDirectory() as directory:
            def run(argv, timeout):
                calls.append(argv)
                return '--no-download' not in argv
            self.assertFalse(module.install_dependencies('arm64', Path(directory), run=run))
        self.assertEqual(sum('--no-download' in argv for argv in calls), 1)
        self.assertIn('libmpv-dev', module.PACKAGES)
        self.assertIn('libepoxy-dev', module.PACKAGES)

    def test_command_timeout_stops_the_child_process(self):
        start = time.monotonic()
        self.assertFalse(module.run_command([sys.executable, '-c', 'import time; time.sleep(10)'], timeout=0.05))
        self.assertLess(time.monotonic() - start, 2)


if __name__ == '__main__':
    unittest.main()
