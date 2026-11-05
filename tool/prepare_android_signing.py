#!/usr/bin/env python3
"""Prepare ignored Android signing files without printing credentials."""
import argparse
import base64
import json
import os
from pathlib import Path
import secrets
import subprocess


def property_value(value):
    # Properties.load(InputStream) uses Latin-1; encode Unicode as Java escapes.
    escaped = json.dumps(value, ensure_ascii=True)[1:-1]
    return escaped.replace(' ', '\\ ').replace('=', '\\=').replace(':', '\\:')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stable', choices=['true', 'false'], required=True)
    args = parser.parse_args()
    directory = Path(os.environ['RUNNER_TEMP']) / 'vnlf-signing'
    directory.mkdir(parents=True, exist_ok=True)
    keystore = directory / 'release.keystore'
    required = ['ANDROID_KEYSTORE_BASE64', 'ANDROID_STORE_PASSWORD', 'ANDROID_KEY_PASSWORD', 'ANDROID_KEY_ALIAS']
    configured = all(os.environ.get(name) for name in required)
    if args.stable == 'true' and not configured:
        raise SystemExit('Stable Android releases require all four ANDROID signing secrets. No development signing fallback is permitted.')
    if configured:
        keystore.write_bytes(base64.b64decode(os.environ['ANDROID_KEYSTORE_BASE64'], validate=True))
        store_password = os.environ['ANDROID_STORE_PASSWORD']
        key_password = os.environ['ANDROID_KEY_PASSWORD']
        alias = os.environ['ANDROID_KEY_ALIAS']
    else:
        store_password = key_password = secrets.token_urlsafe(32)
        alias = 'ci-development'
        env = {**os.environ, 'VNLF_CI_KEY_PASSWORD': store_password}
        subprocess.run(['keytool', '-genkeypair', '-noprompt', '-keystore', str(keystore),
                        '-storetype', 'PKCS12', '-alias', alias, '-keyalg', 'RSA', '-keysize', '2048',
                        '-validity', '30', '-dname', 'CN=VNLF CI Development',
                        '-storepass:env', 'VNLF_CI_KEY_PASSWORD', '-keypass:env', 'VNLF_CI_KEY_PASSWORD'],
                       check=True, env=env, stdout=subprocess.DEVNULL)
        print('CI development signature prepared; these APKs are not stable release candidates.')
    properties = {'storeFile': str(keystore), 'storePassword': store_password,
                  'keyPassword': key_password, 'keyAlias': alias}
    destination = Path('android/app/key.properties')
    destination.write_text(''.join(f'{name}={property_value(value)}\n' for name, value in properties.items()))
    destination.chmod(0o600)
    keystore.chmod(0o600)

if __name__ == '__main__':
    main()
