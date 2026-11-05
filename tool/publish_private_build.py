#!/usr/bin/env python3
"""Preserve completed build assets even when the original workflow was canceled."""
import argparse
import base64
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from release_metadata import TARGETS, asset_manifest, compute_metadata

REPOSITORY = 'VN-Linux-Family/vnlf-social-desktop'

def metadata_for_run(run, pubspec_version):
    if (run.get('head_repository') or {}).get('full_name') != REPOSITORY:
        raise ValueError('Only this repository can publish build artifacts')
    if run.get('event') not in ('push', 'workflow_dispatch') or run.get('path') != '.github/workflows/build.yml':
        raise ValueError('Only the trusted build workflow can publish artifacts')
    if not isinstance(run.get('id'), int) or run['id'] < 1:
        raise ValueError('Invalid build run ID')
    branch = run.get('head_branch') or ''
    ref_type = 'tag' if run['event'] == 'push' and branch.startswith('v') else 'branch'
    return compute_metadata(pubspec_version, run['head_sha'], run['run_number'],
                            run['run_attempt'], ref_type, branch, run['id'])

def stage_assets(source, destination, version):
    allowed = {f'vnlf-social-{version}-{platform}-{arch}.{extension}' for platform, arch, extension in TARGETS}
    found = {}
    for path in Path(source).rglob('*'):
        if not path.is_file() or path.is_symlink() or path.name not in allowed:
            continue
        if path.name in found:
            raise ValueError('Duplicate artifact target: ' + path.name)
        found[path.name] = path
    Path(destination).mkdir(parents=True, exist_ok=True)
    for name, path in found.items():
        shutil.copyfile(path, Path(destination) / name)

def artifact_pattern(artifacts, attempt):
    current = [item for item in artifacts if item['name'].startswith('binary-') and not item['expired']]
    if any(item['name'].endswith(f'-{attempt}') for item in current):
        return f'binary-*-{attempt}'
    # Older build workflow versions had no attempt suffix. Their first build
    # can still be recovered, while ambiguous later attempts are never mixed.
    if attempt == 1 and any(item['name'] in {'binary-android', *(f'binary-{p}-{a}' for p, a, _ in TARGETS if p != 'android')} for item in current):
        return 'binary-*'
    return None

def api(path):
    return json.loads(subprocess.check_output(['gh', 'api', path], text=True))

def run_command(*arguments):
    subprocess.run(list(arguments), check=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id', type=int, required=True)
    parser.add_argument('--attempt', type=int, help='Exact completed attempt to recover')
    parser.add_argument('--download-dir', type=Path, help='Reuse a locally downloaded build instead of downloading again')
    args = parser.parse_args()
    endpoint = f'repos/{REPOSITORY}/actions/runs/{args.run_id}'
    run = api(endpoint + (f'/attempts/{args.attempt}' if args.attempt is not None else ''))
    if run.get('status') != 'completed':
        raise ValueError('Wait for the original build to finish before preserving its assets')
    # Read only this exact build's pubspec. No code from artifacts is executed.
    pubspec = api(f"repos/{REPOSITORY}/contents/pubspec.yaml?ref={run['head_sha']}")
    version_text = base64.b64decode(pubspec['content']).decode('utf-8')
    match = re.search(r'^version:\s*[\'"]?([^\s\'"#]+)', version_text, re.MULTILINE)
    if not match:
        raise ValueError('Original build has no declared application version')
    metadata = metadata_for_run(run, match.group(1))
    if api(f'repos/{REPOSITORY}').get('private') is not True:
        raise ValueError('Refusing to publish internal CI builds to a public source repository')
    artifacts = api(f'repos/{REPOSITORY}/actions/runs/{args.run_id}/artifacts?per_page=100')['artifacts']
    pattern = artifact_pattern(artifacts, int(run['run_attempt']))
    if pattern is None:
        print('No available binaries were produced; no empty release created.')
        return
    with tempfile.TemporaryDirectory(prefix='vnlf-private-publish-') as temporary:
        root = Path(temporary)
        source = args.download_dir or root / 'download'
        if args.download_dir is None:
            run_command('gh', 'run', 'download', str(args.run_id), '--repo', REPOSITORY,
                        '--pattern', pattern, '--dir', str(source))
        dist = root / 'dist'
        stage_assets(source, dist, metadata['version'])
        manifest = asset_manifest(dist, metadata['version'], metadata['build_number'],
                                  metadata['source_sha'], require_complete=False)
        manifest['workflowRun'] = args.run_id
        manifest['workflowConclusion'] = run.get('conclusion')
        (dist / 'release.json').write_text(json.dumps(manifest, indent=2) + '\n')
        (dist / 'SHA256SUMS').write_text(''.join(f"{asset['sha256']}  {asset['name']}\n" for asset in manifest['assets']))
        notes = root / 'notes.md'
        notes.write_text(f"VNLF Social {metadata['version']}\n\nBuild: https://github.com/{REPOSITORY}/actions/runs/{args.run_id}\n"
                         f"Result: {run.get('conclusion')}\n\n" +
                         ('All nine targets are present.\n' if manifest['complete'] else
                          'Incomplete build; missing: ' + ', '.join(manifest['missingTargets']) + '\n') +
                         ('\nDevelopment APK signatures are for internal testing only.\n' if metadata['is_stable'] != 'true' else '') +
                         '\nVerify assets with release.json and SHA256SUMS.\n')
        tag = metadata['private_release_tag']
        existing = subprocess.run(['gh', 'release', 'view', tag, '--repo', REPOSITORY],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if existing.returncode != 0:
            run_command('gh', 'release', 'create', tag, '--repo', REPOSITORY,
                        '--target', metadata['source_sha'], '--title', f"VNLF Social {metadata['version']}",
                        '--notes-file', str(notes), '--draft')
        run_command('gh', 'release', 'upload', tag, *map(str, sorted(dist.iterdir())),
                    '--repo', REPOSITORY, '--clobber')
        if manifest['complete']:
            run_command('gh', 'release', 'edit', tag, '--repo', REPOSITORY, '--draft=false',
                        '--prerelease=' + str(metadata['is_stable'] != 'true').lower(), '--latest=false')
        print(f"Preserved {len(manifest['assets'])} binaries in private release {tag}; complete={manifest['complete']}.")

if __name__ == '__main__':
    main()
