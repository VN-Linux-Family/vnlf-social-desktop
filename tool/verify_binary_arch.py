#!/usr/bin/env python3
"""Reject mismatched native executables and runtime libraries before packaging."""
import argparse
from pathlib import Path
import struct
import zipfile

ELF_MACHINES = {'armv7': 40, 'arm64': 183, 'x64': 62}
PE_MACHINES = {'arm64': 0xAA64, 'x64': 0x8664}
ANDROID_ABIS = {'armv7': 'armeabi-v7a', 'arm64': 'arm64-v8a', 'x64': 'x86_64'}

def elf_machine(data):
    if len(data) < 20 or data[:4] != b'\x7fELF' or data[5] not in (1, 2):
        raise ValueError('Invalid ELF header')
    return struct.unpack_from('<H' if data[5] == 1 else '>H', data, 18)[0]

def verify_windows(root, architecture):
    count = 0
    for path in Path(root).rglob('*'):
        if not path.is_file() or path.suffix.lower() not in ('.dll', '.exe'):
            continue
        with path.open('rb') as stream:
            header = stream.read(64)
            if len(header) < 64 or header[:2] != b'MZ':
                raise ValueError('Invalid PE header: ' + str(path))
            stream.seek(struct.unpack_from('<I', header, 60)[0])
            pe = stream.read(6)
            if len(pe) != 6 or pe[:4] != b'PE\0\0' or struct.unpack_from('<H', pe, 4)[0] != PE_MACHINES[architecture]:
                raise ValueError('Wrong native Windows architecture: ' + str(path))
        count += 1
    if not count:
        raise ValueError('No Windows native binaries found')
    return count

def verify_linux(root, architecture):
    count = 0
    for path in Path(root).rglob('*'):
        if not path.is_file():
            continue
        with path.open('rb') as stream:
            header = stream.read(64)
        if header[:4] != b'\x7fELF':
            continue
        if elf_machine(header) != ELF_MACHINES[architecture]:
            raise ValueError('Wrong native Linux architecture: ' + str(path))
        count += 1
    if not count:
        raise ValueError('No Linux native binaries found')
    return count

def verify_android(apk, architecture):
    count = 0
    with zipfile.ZipFile(apk) as archive:
        for name in archive.namelist():
            if not name.startswith('lib/') or not name.endswith('.so'):
                continue
            if name.split('/')[1] != ANDROID_ABIS[architecture]:
                raise ValueError('Unexpected Android ABI: ' + name)
            with archive.open(name) as stream:
                header = stream.read(64)
            if elf_machine(header) != ELF_MACHINES[architecture]:
                raise ValueError('Wrong Android ELF architecture: ' + name)
            count += 1
    if not count:
        raise ValueError('No Android native libraries found')
    return count

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['windows', 'linux', 'android'], required=True)
    parser.add_argument('--arch', choices=['x64', 'arm64', 'armv7'], required=True)
    parser.add_argument('path', type=Path)
    args = parser.parse_args()
    if args.platform != 'android' and args.arch == 'armv7':
        parser.error('armv7 is only supported for Android')
    verify = {'windows': verify_windows, 'linux': verify_linux, 'android': verify_android}[args.platform]
    count = verify(args.path, args.arch)
    print(f'Verified {count} {args.platform}/{args.arch} native binaries')

if __name__ == '__main__': main()
