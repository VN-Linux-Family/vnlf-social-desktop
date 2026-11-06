import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/profile_relationship.dart';
import 'package:vnlfsocialapp/src/features/profile/domain/public_profile.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_actions.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_data.dart';
import 'package:vnlfsocialapp/src/features/profile/presentation/profile_relationship_controller.dart';

const _viewer = Session(
  userId: 'viewer-1',
  displayName: 'Viewer One',
  username: 'viewer_one',
);
const _otherViewer = Session(
  userId: 'viewer-2',
  displayName: 'Viewer Two',
  username: 'viewer_two',
);

class _Profiles implements PublicProfileRepository {
  bool followed = false;
  bool blocked = false;
  bool sample = false;
  String targetId = 'target-1';
  int reads = 0;

  @override
  Future<PublicProfile?> getProfile(String username) async {
    reads++;
    return PublicProfile(
      author: Author(
        id: targetId,
        username: 'synthetic',
        displayName: 'Nguyễn An',
      ),
      followedByViewer: followed,
      blockedByViewer: blocked,
      isSample: sample,
    );
  }

  @override
  Future<FeedPage> getPosts(String username) => throw UnimplementedError();
  @override
  Future<ProfileCommentsPage> getComments(String username) =>
      throw UnimplementedError();
  @override
  Future<ProjectsPage> getProjects(String username) =>
      throw UnimplementedError();
  @override
  Future<GuestbookPage> getGuestbook(String username, {String? cursor}) =>
      throw UnimplementedError();
}

class _Relationships implements ProfileRelationshipRepository {
  final calls = <String>[];
  Completer<void>? gate;
  Object? failure;
  void Function()? onAcknowledged;

  Future<void> _run(String call) async {
    calls.add(call);
    await gate?.future;
    if (failure != null) throw failure!;
    onAcknowledged?.call();
  }

  @override
  Future<void> setFollowing(String userId, {required bool following}) =>
      _run('${following ? 'follow' : 'unfollow'}:$userId');

  @override
  Future<void> setBlocked(String userId, {required bool blocked}) =>
      _run('${blocked ? 'block' : 'unblock'}:$userId');
}

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider('synthetic')).valueOrNull;
    return Scaffold(
      body: Center(
        child: profile == null
            ? const SizedBox.shrink()
            : ProfileActions(profile: profile, profileKey: 'synthetic'),
      ),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required _Profiles profiles,
  required _Relationships relationships,
  Session? session = _viewer,
  Locale locale = const Locale('vi'),
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Host()),
      GoRoute(path: '/login', builder: (context, state) => const Text('login')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStateProvider.overrideWith((ref) => session),
        publicProfileRepositoryProvider.overrideWithValue(profiles),
        profileRelationshipRepositoryProvider.overrideWithValue(relationships),
        apiClientProvider.overrideWithValue(
          ApiClient(
            hostKey: Object(),
            transport: (request) async => throw StateError('no network'),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(_Host)));
}

Future<void> _openBlockDialog(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Tùy chọn hồ sơ'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chặn người này'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guests are sent to sign in instead of writing', (tester) async {
    final relationships = _Relationships();
    await _pump(
      tester,
      profiles: _Profiles(),
      relationships: relationships,
      session: null,
    );
    expect(
      find.bySemanticsLabel('Đăng nhập để theo dõi Nguyễn An'),
      findsOneWidget,
    );
    expect(find.byTooltip('Tùy chọn hồ sơ'), findsNothing);
    await tester.tap(find.text('Theo dõi'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
    expect(relationships.calls, isEmpty);
  });

  testWidgets('owners and sample profiles get no relationship actions', (
    tester,
  ) async {
    final profiles = _Profiles()..targetId = _viewer.userId;
    await _pump(tester, profiles: profiles, relationships: _Relationships());
    expect(find.text('Theo dõi'), findsNothing);
    expect(find.byTooltip('Tùy chọn hồ sơ'), findsNothing);
  });

  testWidgets('a sample profile never offers writes', (tester) async {
    final profiles = _Profiles()..sample = true;
    await _pump(tester, profiles: profiles, relationships: _Relationships());
    expect(find.text('Theo dõi'), findsNothing);
  });

  testWidgets('follow is acknowledged, then confirmed by a fresh read', (
    tester,
  ) async {
    final profiles = _Profiles();
    final relationships = _Relationships()
      ..onAcknowledged = () => profiles.followed = true;
    await _pump(tester, profiles: profiles, relationships: relationships);
    expect(profiles.reads, 1);
    await tester.tap(find.text('Theo dõi'));
    await tester.pumpAndSettle();
    expect(relationships.calls, ['follow:target-1']);
    expect(profiles.reads, 2);
    expect(find.text('Đang theo dõi'), findsOneWidget);
    expect(find.text('Đang theo dõi Nguyễn An'), findsOneWidget);
  });

  testWidgets('unfollow reads the profile again before changing the label', (
    tester,
  ) async {
    final profiles = _Profiles()..followed = true;
    final relationships = _Relationships()
      ..onAcknowledged = () => profiles.followed = false;
    await _pump(tester, profiles: profiles, relationships: relationships);
    await tester.tap(find.text('Đang theo dõi'));
    await tester.pumpAndSettle();
    expect(relationships.calls, ['unfollow:target-1']);
    expect(find.text('Theo dõi'), findsOneWidget);
    expect(find.text('Đã bỏ theo dõi Nguyễn An'), findsOneWidget);
  });

  testWidgets('repeated taps while pending send a single request', (
    tester,
  ) async {
    final profiles = _Profiles();
    final relationships = _Relationships()
      ..gate = Completer<void>()
      ..onAcknowledged = () => profiles.followed = true;
    await _pump(tester, profiles: profiles, relationships: relationships);
    await tester.tap(find.text('Theo dõi'));
    await tester.pump();
    expect(find.text('Đang cập nhật…'), findsOneWidget);
    await tester.tap(find.text('Đang cập nhật…'), warnIfMissed: false);
    await tester.tap(find.byTooltip('Tùy chọn hồ sơ'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Chặn người này'), findsNothing);
    relationships.gate!.complete();
    await tester.pumpAndSettle();
    expect(relationships.calls, ['follow:target-1']);
    expect(find.text('Đang theo dõi'), findsOneWidget);
  });

  testWidgets('a refused follow explains itself and changes nothing', (
    tester,
  ) async {
    final profiles = _Profiles();
    final relationships = _Relationships()
      ..failure = const HttpFailure(403, code: 'USER_BLOCKED');
    await _pump(tester, profiles: profiles, relationships: relationships);
    await tester.tap(find.text('Theo dõi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không thực hiện được với thành viên này.'),
      findsOneWidget,
    );
    expect(find.text('Theo dõi'), findsOneWidget);
    expect(profiles.reads, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(relationships.calls.length, 1);
  });

  testWidgets('an acknowledgment the server read contradicts is flagged', (
    tester,
  ) async {
    final profiles = _Profiles();
    await _pump(tester, profiles: profiles, relationships: _Relationships());
    await tester.tap(find.text('Theo dõi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa xác nhận được kết quả. Hãy tải lại hồ sơ để kiểm tra.'),
      findsOneWidget,
    );
    expect(find.text('Theo dõi'), findsOneWidget);
  });

  testWidgets('blocking asks first and cancelling sends nothing', (
    tester,
  ) async {
    final relationships = _Relationships();
    await _pump(tester, profiles: _Profiles(), relationships: relationships);
    await _openBlockDialog(tester);
    expect(find.text('Chặn Nguyễn An?'), findsOneWidget);
    expect(find.textContaining('không nhận được thông báo'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(relationships.calls, isEmpty);
    expect(find.text('Theo dõi'), findsOneWidget);
  });

  testWidgets(
    'confirmed block leaves only unblock and unblock restores follow',
    (tester) async {
      final profiles = _Profiles()..followed = true;
      final relationships = _Relationships()
        ..onAcknowledged = () {
          profiles.blocked = true;
          profiles.followed = false;
        };
      await _pump(tester, profiles: profiles, relationships: relationships);
      await _openBlockDialog(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Chặn'));
      await tester.pumpAndSettle();
      expect(relationships.calls, ['block:target-1']);
      expect(find.text('Bỏ chặn'), findsOneWidget);
      expect(find.text('Bạn đã chặn người này.'), findsOneWidget);
      expect(find.text('Theo dõi'), findsNothing);
      expect(find.text('Đang theo dõi'), findsNothing);
      expect(find.byTooltip('Tùy chọn hồ sơ'), findsNothing);

      relationships.onAcknowledged = () => profiles.blocked = false;
      await tester.tap(find.text('Bỏ chặn'));
      await tester.pumpAndSettle();
      expect(relationships.calls.last, 'unblock:target-1');
      expect(find.text('Theo dõi'), findsOneWidget);
    },
  );

  testWidgets('an uncertain block is reconciled and tells the user', (
    tester,
  ) async {
    final relationships = _Relationships()..failure = const HttpFailure(500);
    await _pump(tester, profiles: _Profiles(), relationships: relationships);
    await _openBlockDialog(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Chặn'));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa xác nhận được kết quả. Hãy tải lại hồ sơ để kiểm tra.'),
      findsOneWidget,
    );
    expect(find.text('Theo dõi'), findsOneWidget);
    expect(relationships.calls.length, 1);
  });

  testWidgets('switching accounts mid-request drops the old result', (
    tester,
  ) async {
    final profiles = _Profiles();
    final relationships = _Relationships()..gate = Completer<void>();
    final container = await _pump(
      tester,
      profiles: profiles,
      relationships: relationships,
    );
    await tester.tap(find.text('Theo dõi'));
    await tester.pump();
    expect(find.text('Đang cập nhật…'), findsOneWidget);
    container.read(sessionStateProvider.notifier).state = _otherViewer;
    await tester.pumpAndSettle();
    final readsAfterSwitch = profiles.reads;
    expect(find.text('Đang cập nhật…'), findsNothing);
    expect(find.text('Theo dõi'), findsOneWidget);
    relationships.gate!.complete();
    await tester.pumpAndSettle();
    expect(relationships.calls, ['follow:target-1']);
    expect(profiles.reads, readsAfterSwitch);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Theo dõi'), findsOneWidget);
  });

  testWidgets('signing out hides the writes again', (tester) async {
    final container = await _pump(
      tester,
      profiles: _Profiles(),
      relationships: _Relationships(),
    );
    expect(find.byTooltip('Tùy chọn hồ sơ'), findsOneWidget);
    container.read(sessionStateProvider.notifier).state = null;
    await tester.pumpAndSettle();
    expect(find.byTooltip('Tùy chọn hồ sơ'), findsNothing);
    expect(
      find.bySemanticsLabel('Đăng nhập để theo dõi Nguyễn An'),
      findsOneWidget,
    );
  });

  testWidgets('English labels and a toggle state for assistive tech', (
    tester,
  ) async {
    final profiles = _Profiles()..followed = true;
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      profiles: profiles,
      relationships: _Relationships(),
      locale: const Locale('en'),
    );
    expect(find.text('Following'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Following Nguyễn An. Tap to unfollow'),
      findsOneWidget,
    );
    expect(find.byTooltip('Profile options'), findsOneWidget);
    handle.dispose();
  });
}
