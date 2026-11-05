#!/usr/bin/env python3
"""Version and release manifests shared by every CI platform; no dependencies."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re

BASE = r'(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)'
SEMVER = re.compile(rf'^{BASE}(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$')
TARGETS = {
    ('linux', 'x64', 'tar.gz'), ('linux', 'arm64', 'tar.gz'),
    ('macos', 'x64', 'zip'), ('macos', 'arm64', 'zip'),
    ('windows', 'x64', 'zip'), ('windows', 'arm64', 'zip'),
    ('android', 'armv7', 'apk'), ('android', 'arm64', 'apk'), ('android', 'x64', 'apk'),
}

def compute_metadata(pubspec_version, sha, run_number, attempt, ref_type, ref_name, run_id):
    if not SEMVER.fullmatch(pubspec_version):
        raise ValueError('Invalid pubspec semantic version')
    if not re.fullmatch(r'[0-9a-fA-F]{40}', sha):
        raise ValueError('Expected a complete commit SHA')
    if not 1 <= int(run_number) <= 65535 or int(attempt) < 1:
        raise ValueError('Build number must fit Android and Windows version fields (1..65535)')
    if not re.fullmatch(r'[0-9]+', str(run_id)):
        raise ValueError('Invalid workflow run ID')
    base = pubspec_version.split('+', 1)[0].split('-', 1)[0]
    stable = False
    if ref_type == 'tag':
        if not ref_name.startswith('v') or not SEMVER.fullmatch(ref_name[1:]):
            raise ValueError('Release tags must use v<semantic-version>')
        version = ref_name[1:]
        if version.split('+', 1)[0].split('-', 1)[0] != base:
            raise ValueError('Release tag does not match pubspec version')
        stable = '-' not in version.split('+', 1)[0]
        tag = ref_name
    else:
        version = f'{base}-dev.{int(run_number)}.{int(attempt)}+{sha[:7].lower()}'
        tag = f'ci-{run_id}-{int(attempt)}'
    return {
        'version': version, 'build_name': base, 'build_number': str(int(run_number)),
        'release_tag': tag, 'is_stable': str(stable).lower(),
        'artifact_prefix': f'vnlf-social-{version}', 'source_sha': sha.lower(),
    }

def asset_manifest(directory, version, build_number, sha, require_complete=True):
    if not SEMVER.fullmatch(version):
        raise ValueError('Invalid release version')
    assets = []
    missing = []
    for platform, arch, extension in sorted(TARGETS):
        name = f'vnlf-social-{version}-{platform}-{arch}.{extension}'
        path = Path(directory) / name
        if not path.is_file():
            missing.append(f'{platform}-{arch}')
            continue
        digest = hashlib.sha256()
        with path.open('rb') as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
        assets.append({'name': name, 'platform': platform, 'arch': arch,
                       'sha256': digest.hexdigest(), 'size': path.stat().st_size})
    if require_complete and missing:
        raise ValueError('Missing release targets: ' + ', '.join(missing))
    if not assets:
        raise ValueError('No build assets were produced')
    return {'schemaVersion': 1, 'version': version, 'buildNumber': int(build_number),
            'commit': sha, 'complete': not missing, 'missingTargets': missing, 'assets': assets}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pubspec', default='pubspec.yaml')
    parser.add_argument('--output', default=os.environ.get('GITHUB_OUTPUT'))
    parser.add_argument('--manifest-dir')
    parser.add_argument('--allow-incomplete', action='store_true')
    args = parser.parse_args()
    if args.manifest_dir:
        root = Path(args.manifest_dir)
        manifest = asset_manifest(root, os.environ['APP_VERSION'], os.environ['BUILD_NUMBER'],
                                  os.environ['SOURCE_SHA'], not args.allow_incomplete)
        (root / 'release.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        (root / 'SHA256SUMS').write_text(''.join(f"{a['sha256']}  {a['name']}\n" for a in manifest['assets']))
        return
    match = re.search(r'^version:\s*[\'"]?([^\s\'"#]+)', Path(args.pubspec).read_text(), re.MULTILINE)
    if not match:
        raise ValueError('pubspec.yaml does not declare a version')
    values = compute_metadata(match.group(1), os.environ['GITHUB_SHA'], os.environ['GITHUB_RUN_NUMBER'],
                              os.environ.get('GITHUB_RUN_ATTEMPT', '1'), os.environ['GITHUB_REF_TYPE'],
                              os.environ['GITHUB_REF_NAME'], os.environ['GITHUB_RUN_ID'])
    if args.output:
        with Path(args.output).open('a') as stream:
            for key, value in values.items():
                stream.write(f'{key}={value}\n')
    print(json.dumps(values))

if __name__ == '__main__':
    main()
