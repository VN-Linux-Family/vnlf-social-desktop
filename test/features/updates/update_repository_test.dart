import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/features/updates/data/github_update_repository.dart';
import 'package:vnlfsocialapp/src/features/updates/domain/app_update.dart';

void main() {
  test('semantic versions order prereleases and ignore build metadata', () {
    expect(
      ReleaseVersion.parse('1.2.3')
          .compareTo(ReleaseVersion.parse('1.2.3-rc.2')),
      greaterThan(0),
    );
    expect(
      ReleaseVersion.parse('1.2.3-rc.10')
          .compareTo(ReleaseVersion.parse('1.2.3-rc.2')),
      greaterThan(0),
    );
    expect(
      ReleaseVersion.parse('1.2.3+aaa')
          .compareTo(ReleaseVersion.parse('1.2.3+bbb')),
      0,
    );
    expect(
      ReleaseVersion.parse('1.10.0').compareTo(ReleaseVersion.parse('1.9.9')),
      greaterThan(0),
    );
  });

  test(
    'a missing or private release repository is an explicit unavailable result',
    () async {
      final repository = GitHubUpdateRepository(
        transport: (_) async => const ReleaseResponse(404, '{}'),
      );
      final result = await repository.check(
        '0.1.0',
        const UpdatePlatform('linux', 'arm64', 'tar.gz'),
      );
      expect(result, isA<UpdateUnavailable>());
    },
  );

  test('a newer release selects the native architecture only', () async {
    final repository = GitHubUpdateRepository(
      transport: (_) async => ReleaseResponse(
        200,
        jsonEncode({
          'tag_name': 'v1.0.0',
          'draft': false,
          'prerelease': false,
          'html_url': 'https://github.com/VN-Linux-Family/vnlf-social-desktop/releases/tag/v1.0.0',
          'assets': [
            {
              'name': 'vnlf-social-1.0.0-linux-x64.tar.gz',
              'browser_download_url': 'https://github.com/VN-Linux-Family/vnlf-social-desktop/releases/download/v1.0.0/linux-x64.tar.gz',
            },
            {
              'name': 'vnlf-social-1.0.0-linux-arm64.tar.gz',
              'browser_download_url': 'https://github.com/VN-Linux-Family/vnlf-social-desktop/releases/download/v1.0.0/linux-arm64.tar.gz',
            },
          ],
        }),
      ),
    );
    final result = await repository.check(
      '0.1.0',
      const UpdatePlatform('linux', 'arm64', 'tar.gz'),
    ) as UpdateAvailable;
    expect(result.asset!.name, 'vnlf-social-1.0.0-linux-arm64.tar.gz');
    expect(result.version, '1.0.0');
  });

  test('update checks never downgrade an installed newer version', () async {
    final repository = GitHubUpdateRepository(
      transport: (_) async => ReleaseResponse(
        200,
        jsonEncode({
          'tag_name': 'v0.1.0',
          'html_url': 'https://github.com/VN-Linux-Family/vnlf-social-desktop/releases/tag/v0.1.0',
          'assets': <Object>[],
        }),
      ),
    );
    expect(
      await repository.check(
        '0.2.0',
        const UpdatePlatform('windows', 'x64', 'zip'),
      ),
      isA<UpdateCurrent>(),
    );
  });

  test('release links outside the expected repository are rejected', () async {
    final repository = GitHubUpdateRepository(
      transport: (_) async => ReleaseResponse(
        200,
        jsonEncode({
          'tag_name': 'v1.0.0',
          'html_url': 'https://attacker.invalid/release',
          'assets': <Object>[],
        }),
      ),
    );
    await expectLater(
      repository.check(
        '0.1.0',
        const UpdatePlatform('android', 'arm64', 'apk'),
      ),
      throwsA(isA<UpdateFailure>()),
    );
  });

  test('network failures remain visible to the update UI', () async {
    final repository = GitHubUpdateRepository(
      transport: (_) async => throw const UpdateFailure(),
    );
    await expectLater(
      repository.check('0.1.0', const UpdatePlatform('linux', 'x64', 'tar.gz')),
      throwsA(isA<UpdateFailure>()),
    );
  });
}
