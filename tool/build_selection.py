#!/usr/bin/env python3
"""Choose explicit packaging targets without allocating unused hosted runners."""
import json
import os

DESKTOP = [
    {'platform': platform, 'arch': arch, 'runner': runner}
    for platform, arch, runner in (
        ('linux', 'x64', 'ubuntu-24.04'),
        ('linux', 'arm64', 'ubuntu-24.04-arm'),
        ('windows', 'x64', 'windows-2025'),
        ('windows', 'arm64', 'windows-11-arm'),
        ('macos', 'x64', 'macos-15-intel'),
        ('macos', 'arm64', 'macos-15'),
    )
]


def select_targets(event, ref_type, requested):
    if event in ('push', 'workflow_dispatch') and ref_type == 'tag':
        requested = 'all'
    elif event != 'workflow_dispatch':
        raise ValueError('Packaging requires an explicit dispatch or release tag')
    if requested not in ('linux-x64', 'android', 'all'):
        raise ValueError('Unknown packaging target set')
    rows = DESKTOP if requested == 'all' else DESKTOP[:1] if requested == 'linux-x64' else []
    return {'include': rows}, requested in ('android', 'all')


def main():
    matrix, android = select_targets(os.environ['GITHUB_EVENT_NAME'],
                                     os.environ['GITHUB_REF_TYPE'],
                                     os.environ.get('BUILD_SET', 'linux-x64'))
    with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
        output.write('desktop_matrix=' + json.dumps(matrix, separators=(',', ':')) + '\n')
        output.write('build_desktop=' + str(bool(matrix['include'])).lower() + '\n')
        output.write('build_android=' + str(android).lower() + '\n')


if __name__ == '__main__':
    main()
