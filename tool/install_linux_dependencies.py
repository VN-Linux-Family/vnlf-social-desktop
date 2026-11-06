#!/usr/bin/env python3
"""Install native Ubuntu build dependencies with bounded archive failover."""
import argparse
import os
from pathlib import Path
import re
import signal
import subprocess

PACKAGES = ('clang', 'cmake', 'ninja-build', 'pkg-config', 'libgtk-3-dev',
            'liblzma-dev', 'libsecret-1-dev', 'libmpv-dev', 'libepoxy-dev')
X64_MIRRORS = ('https://azure.archive.ubuntu.com/ubuntu',
               'https://mirrors.edge.kernel.org/ubuntu',
               'https://archive.ubuntu.com/ubuntu')
ARM_MIRROR = 'https://ports.ubuntu.com/ubuntu-ports'
OPTIONS = ('-o', 'Acquire::Retries=1', '-o', 'Acquire::ForceIPv4=true',
           '-o', 'Acquire::http::Timeout=20', '-o', 'Acquire::https::Timeout=20')


def rewrite_archive(text, architecture, mirror):
    if architecture == 'x64':
        hosts = ('azure.archive.ubuntu.com/ubuntu', 'archive.ubuntu.com/ubuntu',
                 'mirrors.edge.kernel.org/ubuntu')
    elif architecture == 'arm64':
        hosts = ('ports.ubuntu.com/ubuntu-ports',)
    else:
        raise ValueError('Unsupported native Linux architecture')
    for host in hosts:
        text = re.sub(r'https?://' + re.escape(host) + r'(?=[/\s]|$)', mirror, text)
    return text


def set_archive(source_root, architecture, mirror):
    paths = [source_root / 'sources.list']
    # GitHub's Ubuntu images use mirror+file:/etc/apt/apt-mirrors.txt.
    # Updating only the .sources URI leaves every failover on the old host.
    paths.extend(source_root.glob('apt-mirrors*.txt'))
    for extension in ('*.sources', '*.list'):
        paths.extend((source_root / 'sources.list.d').glob(extension))
    for path in paths:
        if path.is_file() and not path.is_symlink():
            before = path.read_text()
            after = rewrite_archive(before, architecture, mirror)
            if before != after:
                path.write_text(after)


def run_command(argv, timeout):
    environment = os.environ | {'DEBIAN_FRONTEND': 'noninteractive', 'NEEDRESTART_MODE': 'a'}
    process = subprocess.Popen(argv, env=environment, start_new_session=True)
    try:
        return process.wait(timeout=timeout) == 0
    except subprocess.TimeoutExpired:
        print('APT stage exceeded its deadline; stopping its process group.', flush=True)
        return False
    finally:
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            except ProcessLookupError:
                process.wait()


def install_dependencies(architecture, source_root, run=run_command):
    if architecture not in ('x64', 'arm64'):
        raise ValueError('Unsupported native Linux architecture')
    mirrors = X64_MIRRORS if architecture == 'x64' else (ARM_MIRROR, ARM_MIRROR)
    for mirror in mirrors:
        print('Preparing signed Ubuntu packages from ' + mirror, flush=True)
        set_archive(source_root, architecture, mirror)
        if not run(['apt-get', 'update', *OPTIONS], timeout=180):
            continue
        # Fully downloaded .deb files remain in APT's validated local cache when
        # a slow archive is replaced. No dpkg writes happen in this retry phase.
        if not run(['apt-get', 'install', '-y', '--no-install-recommends',
                    '--download-only', *OPTIONS, *PACKAGES], timeout=300):
            continue
        return run(['apt-get', 'install', '-y', '--no-install-recommends',
                    '--no-download', *OPTIONS, *PACKAGES], timeout=300)
    print('No Ubuntu archive completed the dependency download.', flush=True)
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--arch', choices=('x64', 'arm64'), required=True)
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error('Run this installer as root on an Ubuntu CI runner.')
    actual = subprocess.check_output(['dpkg', '--print-architecture'], text=True).strip()
    if actual != {'x64': 'amd64', 'arm64': 'arm64'}[args.arch]:
        parser.error('The runner architecture does not match the requested build.')
    def interrupted(_signal, _frame):
        raise SystemExit(143)
    signal.signal(signal.SIGTERM, interrupted)
    return 0 if install_dependencies(args.arch, Path('/etc/apt')) else 1


if __name__ == '__main__':
    raise SystemExit(main())
