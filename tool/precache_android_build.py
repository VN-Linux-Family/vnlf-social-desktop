#!/usr/bin/env python3
"""Fetch Android build inputs whose in-build downloads are flaky.

media_kit_libs_android_video downloads its libmpv jars while Gradle runs, and
the Gradle wrapper downloads its distribution on first use. Fetching both first,
with retries (and MD5 checks for the jars), keeps one transient download error
from failing a build. Run it from the repository root after `flutter pub get`.
"""

from __future__ import annotations

import hashlib
import pathlib
import subprocess
import time
import urllib.request

MPV_VERSION = 'v1.1.7'
MPV_BASE = (
    'https://github.com/media-kit/libmpv-android-video-build/releases/download/'
    f'{MPV_VERSION}'
)
MPV_JARS = (
    ('default-arm64-v8a.jar', '83df25b61193af8fa815e373143ac9af'),
    ('default-armeabi-v7a.jar', '22e21526fefc0a2b8f17adbec9f57590'),
    ('default-x86_64.jar', '6fa26bf0459b11f1c0b0dbc29e5b940d'),
    ('default-x86.jar', '0d742b756dc9d1fcd84ea271d8b68f32'),
)
MPV_CACHE = pathlib.Path('build/media_kit_libs_android_video') / MPV_VERSION


def fetch(url, dest, expected_md5, *, opener=urllib.request.urlopen,
          sleep=time.sleep, attempts=6, min_size=10000):
    path = pathlib.Path(dest)
    path.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(attempts):
        try:
            print(f'Pre-caching {url} (attempt {attempt + 1})...')
            request = urllib.request.Request(
                url, headers={'User-Agent': 'VNLF-CI/1.0'})
            with opener(request, timeout=120) as response:
                data = response.read()
            if hashlib.md5(data).hexdigest() != expected_md5:
                raise ValueError(f'MD5 mismatch for {dest}')
            if len(data) < min_size:
                raise ValueError(f'File too small: {len(data)}')
            path.write_bytes(data)
            print(f'Verified {dest} ({len(data)} bytes)')
            return
        except Exception as exc:  # noqa: BLE001 - every failure is retried
            print(f'Attempt {attempt + 1} failed: {exc}')
            sleep(4 * (attempt + 1))
    raise SystemExit(f'Failed to pre-cache {url}')


def bootstrap_gradle(android_dir='android', *, run=subprocess.run,
                     sleep=time.sleep, attempts=5):
    for attempt in range(1, attempts + 1):
        if run(['./gradlew', '--version'], cwd=android_dir).returncode == 0:
            return
        print(f'Gradle wrapper bootstrap attempt {attempt} failed; retrying...')
        sleep(attempt * 4)
    raise SystemExit('Failed to bootstrap the Gradle wrapper')


def main():
    for name, md5 in MPV_JARS:
        fetch(f'{MPV_BASE}/{name}', MPV_CACHE / name, md5)
    bootstrap_gradle()


if __name__ == '__main__':
    main()
