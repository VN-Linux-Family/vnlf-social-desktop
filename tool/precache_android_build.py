#!/usr/bin/env python3
"""Fetch the libmpv jars that media_kit downloads during the Android build.

media_kit_libs_android_video downloads these jars while Gradle runs; fetching
them first, with retries and MD5 checks, keeps one transient GitHub error from
failing a build. Run it from the repository root after `flutter pub get`.

The Gradle wrapper is not pre-fetched: `android/gradlew` is ignored by Git and
only exists once `flutter build` has generated it.
"""

from __future__ import annotations

import hashlib
import pathlib
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


def main():
    for name, md5 in MPV_JARS:
        fetch(f'{MPV_BASE}/{name}', MPV_CACHE / name, md5)


if __name__ == '__main__':
    main()
