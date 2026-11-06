import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/profile/data/live_profile_relationship_repository.dart';
import 'package:vnlfsocialapp/src/features/profile/data/live_public_profile_repository.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/profile_relationship.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/public_profile.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_relationship_controller.dart';

const _author = Author(
  id: 'target',
  username: 'synthetic',
  displayName: 'Synthetic Member',
);

PublicProfile _profile({bool followed = false, bool blocked = false}) =>
    PublicProfile(
      author: _author,
      followedByViewer: followed,
      blockedByViewer: blocked,
    );

class _Repository implements ProfileRelationshipRepository {
  final calls = <String>[];
  Completer<void>? gate;
  Object? failure;

  Future<void> _run(String call) async {
    calls.add(call);
    await gate?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> setFollowing(String userId, {required bool following}) =>
      _run('${following ? 'follow' : 'unfollow'}:$userId');

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) =>
      _run('${blocked ? 'block' : 'unblock'}:$userId');
}

ProfileRelationshipController _controller(
  _Repository repository, {
  required Future<PublicProfile?> Function() refresh,
  bool Function()? current,
  String viewerId = 'viewer',
}) => ProfileRelationshipController(
  repository: repository,
  refresh: refresh,
  isViewerCurrent: current ?? () => true,
  viewerId: viewerId,
  targetId: 'target',
);

void main() {
  test('success needs the acknowledgment and a fresh matching read', () async {
    final repository = _Repository();
    var reads = 0;
    final controller = _controller(
      repository,
      refresh: () async {
        reads++;
        return _profile(followed: true);
      },
    );
    await controller.perform(ProfileRelationshipAction.follow, _profile());
    expect(repository.calls, ['follow:target']);
    expect(reads, 1);
    expect(controller.state.completed, ProfileRelationshipAction.follow);
    expect(controller.state.failure, isNull);
    expect(controller.state.pending, isNull);
    controller.dispose();
  });

  test('an acknowledgment the fresh read contradicts is unconfirmed', () async {
    final controller = _controller(
      _Repository(),
      refresh: () async => _profile(),
    );
    await controller.perform(ProfileRelationshipAction.block, _profile());
    expect(controller.state.completed, isNull);
    expect(controller.state.failure, isA<RelationshipUnconfirmed>());
    controller.dispose();
  });

  test('a failed fresh read after an acknowledgment is unconfirmed', () async {
    final controller = _controller(
      _Repository(),
      refresh: () async => throw const TransportFailure(),
    );
    await controller.perform(
      ProfileRelationshipAction.unfollow,
      _profile(followed: true),
    );
    expect(controller.state.completed, isNull);
    expect(controller.state.failure, isA<RelationshipUnconfirmed>());
    controller.dispose();
  });

  test('missing relationship state cannot confirm an unblock', () async {
    final controller = _controller(
      _Repository(),
      refresh: () async => const PublicProfile(author: _author),
    );
    await controller.perform(
      ProfileRelationshipAction.unblock,
      _profile(blocked: true),
    );
    expect(controller.state.failure, isA<RelationshipUnconfirmed>());
    expect(controller.state.completed, isNull);
    controller.dispose();
  });

  test('server error after a write reconciles without resending', () async {
    final repository = _Repository()..failure = const HttpFailure(500);
    var reads = 0;
    final controller = _controller(
      repository,
      refresh: () async {
        reads++;
        return _profile(blocked: true);
      },
    );
    await controller.perform(ProfileRelationshipAction.block, _profile());
    expect(repository.calls, ['block:target']);
    expect(reads, 1);
    expect(controller.state.failure, isA<RelationshipUnconfirmed>());
    controller.dispose();
  });

  test('repeated taps are single flight and never retried', () async {
    final repository = _Repository()..gate = Completer<void>();
    final controller = _controller(
      repository,
      refresh: () async => _profile(followed: true),
    );
    final first = controller.perform(
      ProfileRelationshipAction.follow,
      _profile(),
    );
    await controller.perform(ProfileRelationshipAction.follow, _profile());
    await controller.perform(ProfileRelationshipAction.block, _profile());
    expect(controller.state.pending, ProfileRelationshipAction.follow);
    repository.gate!.complete();
    await first;
    expect(repository.calls, ['follow:target']);
    controller.dispose();
  });

  test(
    'server refusal keeps the profile untouched and is not retried',
    () async {
      final repository = _Repository()
        ..failure = const HttpFailure(403, code: 'USER_BLOCKED');
      var reads = 0;
      final controller = _controller(
        repository,
        refresh: () async {
          reads++;
          return _profile();
        },
      );
      await controller.perform(ProfileRelationshipAction.follow, _profile());
      expect(controller.state.failure, isA<RelationshipRejected>());
      expect(controller.state.completed, isNull);
      expect(repository.calls.length, 1);
      expect(reads, 0);
      controller.dispose();
    },
  );

  for (final (status, matcher) in [
    (401, isA<RelationshipSignedOut>()),
    (404, isA<RelationshipUserMissing>()),
    (429, isA<RelationshipRateLimited>()),
    (500, isA<RelationshipUnconfirmed>()),
  ]) {
    test('HTTP $status maps to a typed failure', () async {
      final controller = _controller(
        _Repository()..failure = HttpFailure(status),
        refresh: () async => _profile(),
      );
      await controller.perform(ProfileRelationshipAction.follow, _profile());
      expect(controller.state.failure, matcher);
      controller.dispose();
    });
  }

  test(
    'an unknown transport outcome triggers one read, not a resend',
    () async {
      final repository = _Repository()..failure = const TransportFailure();
      var reads = 0;
      final controller = _controller(
        repository,
        refresh: () async {
          reads++;
          return _profile();
        },
      );
      await controller.perform(ProfileRelationshipAction.follow, _profile());
      expect(repository.calls.length, 1);
      expect(reads, 1);
      expect(controller.state.failure, isA<RelationshipUnconfirmed>());
      expect(controller.state.completed, isNull);
      controller.dispose();
    },
  );

  test('another account taking over drops late results', () async {
    final repository = _Repository()..gate = Completer<void>();
    var current = true;
    var reads = 0;
    final controller = _controller(
      repository,
      current: () => current,
      refresh: () async {
        reads++;
        return _profile(followed: true);
      },
    );
    final pending = controller.perform(
      ProfileRelationshipAction.follow,
      _profile(),
    );
    current = false;
    repository.gate!.complete();
    await pending;
    expect(reads, 0);
    expect(controller.state.completed, isNull);
    expect(controller.state.failure, isNull);
    await controller.perform(ProfileRelationshipAction.unfollow, _profile());
    expect(repository.calls.length, 1);
    controller.dispose();
  });

  test('disposing mid-flight ignores the late answer', () async {
    final repository = _Repository()..gate = Completer<void>();
    var reads = 0;
    final controller = _controller(
      repository,
      refresh: () async {
        reads++;
        return _profile(followed: true);
      },
    );
    final pending = controller.perform(
      ProfileRelationshipAction.follow,
      _profile(),
    );
    controller.dispose();
    repository.gate!.complete();
    await pending;
    expect(reads, 0);
  });

  test('wrong account, self and contradictory states never write', () async {
    final repository = _Repository();
    final self = _controller(
      repository,
      viewerId: 'target',
      refresh: () async => _profile(),
    );
    await self.perform(ProfileRelationshipAction.follow, _profile());
    await self.perform(ProfileRelationshipAction.block, _profile());
    final signedOut = _controller(
      repository,
      viewerId: '',
      refresh: () async => _profile(),
    );
    await signedOut.perform(ProfileRelationshipAction.follow, _profile());
    final controller = _controller(repository, refresh: () async => _profile());
    final blocked = _profile(blocked: true);
    await controller.perform(ProfileRelationshipAction.follow, blocked);
    await controller.perform(ProfileRelationshipAction.unfollow, _profile());
    await controller.perform(ProfileRelationshipAction.unblock, _profile());
    await controller.perform(ProfileRelationshipAction.block, blocked);
    expect(repository.calls, isEmpty);
    for (final c in [self, signedOut, controller]) {
      c.dispose();
    }
  });

  group('live repositories', () {
    late List<ApiRequest> requests;
    ApiClient client(ApiResponse Function(ApiRequest) respond) => ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      cacheDuration: Duration.zero,
      transport: (request) async {
        requests.add(request);
        return respond(request);
      },
    );
    setUp(() => requests = []);

    test('uses the website follow and block verbs on the member id', () async {
      final repository = LiveProfileRelationshipRepository(
        client((_) => ApiResponse(statusCode: 200, body: '{"ok":true}')),
      );
      await repository.setFollowing('user-1', following: true);
      await repository.setFollowing('user-1', following: false);
      await repository.setBlocked('user-1', blocked: true);
      await repository.setBlocked('user-1', blocked: false);
      expect(requests.map((r) => '${r.method} ${r.path}'), [
        'POST /api/v1/users/user-1/follow',
        'DELETE /api/v1/users/user-1/follow',
        'POST /api/v1/users/user-1/block',
        'DELETE /api/v1/users/user-1/block',
      ]);
      expect(requests.every((r) => r.body == null), isTrue);
    });

    test(
      'accepts the unblock acknowledgment carrying a viewer state',
      () async {
        final repository = LiveProfileRelationshipRepository(
          client(
            (_) => ApiResponse(
              statusCode: 200,
              body: '{"ok":true,"viewerState":"REQUEST_REQUIRED"}',
            ),
          ),
        );
        await repository.setBlocked('user-1', blocked: false);
        expect(requests.length, 1);
      },
    );

    for (final body in ['{}', '{"ok":false}', '{"ok":"true"}']) {
      test('rejects the unacknowledged body $body', () async {
        final repository = LiveProfileRelationshipRepository(
          client((_) => ApiResponse(statusCode: 200, body: body)),
        );
        await expectLater(
          repository.setFollowing('user-1', following: true),
          throwsA(isA<ParseFailure>()),
        );
      });
    }

    test('rejects an empty member id before any request', () async {
      final repository = LiveProfileRelationshipRepository(
        client((_) => ApiResponse(statusCode: 200, body: '{"ok":true}')),
      );
      await expectLater(
        repository.setBlocked('', blocked: true),
        throwsA(isA<ParseFailure>()),
      );
      expect(requests, isEmpty);
    });

    for (final status in [429, 500, 503]) {
      test(
        'sends a write exactly once when the server answers $status',
        () async {
          final repository = LiveProfileRelationshipRepository(
            client((_) => ApiResponse(statusCode: status, body: '{}')),
          );
          await expectLater(
            repository.setFollowing('user-1', following: true),
            throwsA(isA<HttpFailure>()),
          );
          expect(requests.length, 1);
        },
      );
    }

    test('keeps the server refusal code', () async {
      final repository = LiveProfileRelationshipRepository(
        client(
          (_) => ApiResponse(statusCode: 403, body: '{"code":"USER_BLOCKED"}'),
        ),
      );
      await expectLater(
        repository.setFollowing('user-1', following: true),
        throwsA(
          isA<HttpFailure>()
              .having((e) => e.statusCode, 'status', 403)
              .having((e) => e.code, 'code', 'USER_BLOCKED'),
        ),
      );
    });

    test(
      'profile read preserves missing relationship flags as unknown',
      () async {
        Map<String, dynamic> body({Object? followed, Object? blocked}) => {
          'id': 'user-1',
          'username': 'synthetic',
          'displayName': 'Synthetic Member',
          'followedByViewer': ?followed,
          'blockedByViewer': ?blocked,
        };
        var next = body(followed: true, blocked: false);
        final repository = LivePublicProfileRepository(
          client((_) => ApiResponse(statusCode: 200, body: jsonEncode(next))),
        );
        var profile = (await repository.getProfile('synthetic'))!;
        expect(profile.followedByViewer, isTrue);
        expect(profile.blockedByViewer, isFalse);
        next = body();
        profile = (await repository.getProfile('synthetic'))!;
        expect(profile.followedByViewer, isNull);
        expect(profile.blockedByViewer, isNull);
        next = body(blocked: 'yes');
        await expectLater(
          repository.getProfile('synthetic'),
          throwsA(isA<ParseFailure>()),
        );
      },
    );
  });
}
