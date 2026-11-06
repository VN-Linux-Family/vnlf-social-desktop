import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/settings/data/live_account_profile_repository.dart';
import 'package:vnlfsocialapp/src/features/settings/domain/account_profile.dart';

ApiClient _client(
  List<ApiRequest> log,
  ApiResponse Function(ApiRequest request) respond,
) => ApiClient(
  transport: (request) async {
    log.add(request);
    return respond(request);
  },
  throttleInterval: Duration.zero,
  retryDelay: (_) async {},
  hostKey: Object(),
);

ApiResponse _json(Object body, [int status = 200]) =>
    ApiResponse(statusCode: status, body: jsonEncode(body));

final _patch = ProfilePatch({
  ProfileField.displayName: 'Minh',
  ProfileField.bio: '',
});

void main() {
  test('load reads the public profile by encoded username', () async {
    final log = <ApiRequest>[];
    final repo = LiveAccountProfileRepository(
      _client(
        log,
        (_) => _json({
          'username': 'minh.linux',
          'displayName': 'Minh',
          'bio': null,
          'website': 'https://example.org',
          'unknown': 1,
        }),
      ),
    );
    final profile = await repo.load('minh linux');
    expect(log.single.method, 'GET');
    expect(log.single.path, '/api/v1/users/minh%20linux');
    expect(profile.bio, '');
    expect(profile.website, 'https://example.org');
  });

  test('load rejects a profile without a username', () async {
    final repo = LiveAccountProfileRepository(
      _client([], (_) => _json({'displayName': 'x'})),
    );
    await expectLater(repo.load('x'), throwsA(isA<ParseFailure>()));
  });

  test('save sends one PATCH with only the changed fields', () async {
    final log = <ApiRequest>[];
    final repo = LiveAccountProfileRepository(
      _client(log, (_) => _json({'ok': true})),
    );
    await repo.save(_patch);
    expect(log.single.method, 'PATCH');
    expect(log.single.path, '/api/v1/me/profile');
    expect(jsonDecode(log.single.body!), {'displayName': 'Minh', 'bio': ''});
  });

  test('save does not claim success without ok:true', () async {
    final repo = LiveAccountProfileRepository(
      _client([], (_) => _json({'ok': false})),
    );
    await expectLater(repo.save(_patch), throwsA(isA<ParseFailure>()));
  });

  test('save is never retried after a server error', () async {
    final log = <ApiRequest>[];
    final repo = LiveAccountProfileRepository(
      _client(log, (_) => _json({'code': 'INTERNAL'}, 503)),
    );
    await expectLater(
      repo.save(_patch),
      throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'status', 503)),
    );
    expect(log, hasLength(1));
  });

  test('conflict keeps the typed error code', () async {
    final repo = LiveAccountProfileRepository(
      _client([], (_) => _json({'code': 'USERNAME_TAKEN'}, 409)),
    );
    await expectLater(
      repo.save(ProfilePatch({ProfileField.username: 'taken'})),
      throwsA(
        isA<HttpFailure>().having((e) => e.code, 'code', 'USERNAME_TAKEN'),
      ),
    );
  });

  test('an empty patch is never sent', () async {
    final log = <ApiRequest>[];
    final repo = LiveAccountProfileRepository(
      _client(log, (_) => _json({'ok': true})),
    );
    await expectLater(repo.save(ProfilePatch({})), throwsA(isA<ParseFailure>()));
    expect(log, isEmpty);
  });

  test('a repository cannot write after the account changes', () async {
    final log = <ApiRequest>[];
    final client = _client(log, (_) => _json({'ok': true}));
    final repo = LiveAccountProfileRepository(client);
    client.invalidateSession();
    await expectLater(repo.save(_patch), throwsA(isA<HttpFailure>()));
    await expectLater(repo.load('x'), throwsA(isA<HttpFailure>()));
    expect(log, isEmpty);
  });
}
