import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('binary_arch', Path(__file__).parents[2] / 'tool/verify_binary_arch.py')
arch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(arch)

def pe(machine):
    data = bytearray(128)
    data[:2] = b'MZ'
    struct.pack_into('<I', data, 60, 64)
    data[64:68] = b'PE\0\0'
    struct.pack_into('<H', data, 68, machine)
    return data

def elf(machine):
    data = bytearray(64)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<H', data, 18, machine)
    return data

class BinaryArchitectureTest(unittest.TestCase):
    def test_every_windows_dll_must_match_the_executable(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            (root / 'app.exe').write_bytes(pe(0xAA64))
            (root / 'media.dll').write_bytes(pe(0x8664))
            with self.assertRaisesRegex(ValueError, 'media.dll'):
                arch.verify_windows(root, 'arm64')
            (root / 'media.dll').write_bytes(pe(0xAA64))
            self.assertEqual(arch.verify_windows(root, 'arm64'), 2)
    def test_linux_shared_objects_cannot_be_relabelled_as_arm64(self):
        with tempfile.TemporaryDirectory() as name:
            root = Path(name)
            (root / 'app').write_bytes(elf(183))
            (root / 'plugin.so').write_bytes(elf(62))
            with self.assertRaisesRegex(ValueError, 'plugin.so'):
                arch.verify_linux(root, 'arm64')
    def test_android_checks_actual_elf_machine_and_abi_directory(self):
        with tempfile.TemporaryDirectory() as name:
            apk = Path(name) / 'app.apk'
            with zipfile.ZipFile(apk, 'w') as z:
                z.writestr('lib/arm64-v8a/libflutter.so', elf(62))
            with self.assertRaises(ValueError): arch.verify_android(apk, 'arm64')
            with zipfile.ZipFile(apk, 'w') as z:
                z.writestr('lib/arm64-v8a/libflutter.so', elf(183))
            self.assertEqual(arch.verify_android(apk, 'arm64'), 1)
    def test_empty_windows_bundle_is_not_a_success(self):
        with tempfile.TemporaryDirectory() as name:
            with self.assertRaises(ValueError): arch.verify_windows(Path(name), 'x64')

if __name__ == '__main__': unittest.main()
