#!/usr/bin/env python3
"""Preserve completed build assets even when the original workflow was canceled."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from release_metadata import TARGETS, asset_manifest, compute_metadata

REPOSITORY = 'VN-Linux-Family/vnlf-social-desktop'
REPOSITORIES = (REPOSITORY, 'luank3/vnlfsocialapp')

def pending_uploads(local, remote):
    uploaded = {asset['name']: asset for asset in remote}
    return [asset['name'] for asset in local
            if not (uploaded.get(asset['name'], {}).get('state') == 'uploaded'
                    and uploaded[asset['name']].get('size') == asset['size']
                    and uploaded[asset['name']].get('digest') == 'sha256:' + asset['sha256'])]

def validate_run(run, repository):
    if repository not in REPOSITORIES or (run.get('head_repository') or {}).get('full_name') != repository:
        raise ValueError('Only this repository can publish build artifacts')
    if run.get('event') not in ('push', 'workflow_dispatch') or run.get('path') != '.github/workflows/build.yml':
        raise ValueError('Only the trusted build workflow can publish artifacts')
    if not isinstance(run.get('id'), int) or run['id'] < 1:
        raise ValueError('Invalid build run ID')

def ref_type_for_run(run, context=None):
    if context is not None:
        if not isinstance(context, dict):
            raise ValueError('Invalid build context')
        attempt = context.get('attempt', '')
        if not isinstance(attempt, str) or not attempt.isdecimal() or not 1 <= int(attempt) <= int(run['run_attempt']):
            raise ValueError('Invalid original metadata attempt')
        expected = {'repository': run['head_repository']['full_name'], 'sha': run['head_sha'],
                    'run_id': str(run['id']),
                    'ref_name': run['head_branch'], 'event': run['event']}
        if any(context.get(key) != value for key, value in expected.items()) or context.get('ref_type') not in ('branch', 'tag'):
            raise ValueError('Build context does not match the original run and attempt')
        return context['ref_type']
    if run['event'] == 'workflow_dispatch' and (run.get('head_branch') or '').startswith('v'):
        raise ValueError('Manual version refs require the original build context to distinguish tags from branches')
    return 'tag' if run['event'] == 'push' and (run.get('head_branch') or '').startswith('v') else 'branch'

def metadata_for_run(run, pubspec_version, repository=REPOSITORY, context=None):
    validate_run(run, repository)
    branch = run.get('head_branch') or ''
    ref_type = ref_type_for_run(run, context)
    # Failed-job reruns retain successful metadata outputs from an older attempt.
    # Their binary version retains that metadata attempt; storage tags and binary
    # artifact selection remain bound to the current requested attempt.
    metadata_attempt = context['attempt'] if context else run['run_attempt']
    metadata = compute_metadata(pubspec_version, run['head_sha'], run['run_number'],
                                metadata_attempt, ref_type, branch, run['id'])
    metadata['private_release_tag'] = f"ci-{run['id']}-{run['run_attempt']}"
    if ref_type == 'branch':
        metadata['release_tag'] = metadata['private_release_tag']
    return metadata

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

def api(path, env=None):
    return json.loads(subprocess.check_output(['gh', 'api', path], text=True, env=env))

def run_command(*arguments, env=None):
    subprocess.run(list(arguments), check=True, env=env)

def release_environment():
    environment = os.environ.copy()
    token = environment.pop('RELEASE_GH_TOKEN', None)
    if token:
        environment['GH_TOKEN'] = token
    return environment

def load_context(run, repository, artifacts):
    attempts = []
    for item in artifacts:
        match = re.fullmatch(r'build-context-([1-9][0-9]*)', item['name'])
        if match and not item['expired'] and int(match.group(1)) <= int(run['run_attempt']):
            attempts.append(int(match.group(1)))
    if not attempts:
        return None  # Legacy builds have no context artifact.
    metadata_attempt = max(attempts)
    name = f'build-context-{metadata_attempt}'
    with tempfile.TemporaryDirectory(prefix='vnlf-build-context-') as directory:
        run_command('gh', 'run', 'download', str(run['id']), '--repo', repository,
                    '--pattern', name, '--dir', directory)
        path = Path(directory) / 'build-context.json'
        if path.is_symlink() or path.stat().st_size > 4096:
            raise ValueError('Invalid build context artifact')
        context = json.loads(path.read_text())
        if not isinstance(context, dict) or context.get('attempt') != str(metadata_attempt):
            raise ValueError('Context artifact name and metadata attempt differ')
        ref_type_for_run(run, context)
        return context

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', required=True, choices=REPOSITORIES, help='Private repository that executed the build')
    parser.add_argument('--release-repo', choices=REPOSITORIES, help='Optional private release mirror; defaults to --repo')
    parser.add_argument('--run-id', type=int, required=True)
    parser.add_argument('--attempt', type=int, help='Exact completed attempt to recover')
    parser.add_argument('--download-dir', type=Path, help='Reuse a locally downloaded build instead of downloading again')
    args = parser.parse_args()
    repository = args.repo
    release_repository = args.release_repo or repository
    release_env = release_environment()
    endpoint = f'repos/{repository}/actions/runs/{args.run_id}'
    run = api(endpoint + (f'/attempts/{args.attempt}' if args.attempt is not None else ''))
    if run.get('status') != 'completed':
        raise ValueError('Wait for the original build to finish before preserving its assets')
    validate_run(run, repository)
    # Read only this exact build's pubspec. No code from artifacts is executed.
    pubspec = api(f"repos/{repository}/contents/pubspec.yaml?ref={run['head_sha']}")
    version_text = base64.b64decode(pubspec['content']).decode('utf-8')
    match = re.search(r'^version:\s*[\'"]?([^\s\'"#]+)', version_text, re.MULTILINE)
    if not match:
        raise ValueError('Original build has no declared application version')
    if api(f'repos/{repository}').get('private') is not True or api(f'repos/{release_repository}', env=release_env).get('private') is not True:
        raise ValueError('Refusing to publish internal CI builds to a public source repository')
    artifacts = api(f'repos/{repository}/actions/runs/{args.run_id}/artifacts?per_page=100')['artifacts']
    context = load_context(run, repository, artifacts)
    metadata = metadata_for_run(run, match.group(1), repository, context)
    pattern = artifact_pattern(artifacts, int(run['run_attempt']))
    if pattern is None:
        print('No available binaries were produced; no empty release created.')
        return
    with tempfile.TemporaryDirectory(prefix='vnlf-private-publish-') as temporary:
        root = Path(temporary)
        source = args.download_dir or root / 'download'
        if args.download_dir is None:
            run_command('gh', 'run', 'download', str(args.run_id), '--repo', repository,
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
        notes.write_text(f"VNLF Social {metadata['version']}\n\nBuild: https://github.com/{repository}/actions/runs/{args.run_id}\n"
                         f"Result: {run.get('conclusion')}\n\n" +
                         ('All nine targets are present.\n' if manifest['complete'] else
                          'Incomplete build; missing: ' + ', '.join(manifest['missingTargets']) + '\n') +
                         ('\nDevelopment APK signatures are for internal testing only.\n' if metadata['is_stable'] != 'true' else '') +
                         '\nVerify assets with release.json and SHA256SUMS.\n')
        tag = metadata['private_release_tag']
        existing = subprocess.run(['gh', 'release', 'view', tag, '--repo', release_repository],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=release_env)
        if existing.returncode != 0:
            run_command('gh', 'release', 'create', tag, '--repo', release_repository,
                        '--target', metadata['source_sha'], '--title', f"VNLF Social {metadata['version']}",
                        '--notes-file', str(notes), '--draft', env=release_env)
        # Avoid concurrent large uploads saturating a slow connection. On a
        # manual rerun, skip only assets whose GitHub digest matches exactly.
        release_url = subprocess.check_output(['gh', 'release', 'view', tag, '--repo', release_repository,
                                               '--json', 'apiUrl', '--jq', '.apiUrl'], text=True, env=release_env).strip()
        if not re.fullmatch(r'https://api.github.com/repos/' + re.escape(release_repository) + r'/releases/\d+', release_url):
            raise ValueError('Unexpected release API destination')
        remote = api(release_url, env=release_env)['assets']
        local = list(manifest['assets'])
        for name in ('release.json', 'SHA256SUMS'):
            path = dist / name
            local.append({'name': name, 'size': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
        for name in pending_uploads(local, remote):
            print('Uploading ' + name, flush=True)
            run_command('gh', 'release', 'upload', tag, str(dist / name), '--repo', release_repository, '--clobber', env=release_env)
        if manifest['complete']:
            run_command('gh', 'release', 'edit', tag, '--repo', release_repository, '--draft=false',
                        '--prerelease=' + str(metadata['is_stable'] != 'true').lower(), '--latest=false', env=release_env)
        print(f"Preserved {len(manifest['assets'])} binaries in private release {tag}; complete={manifest['complete']}.")

if __name__ == '__main__':
    main()
