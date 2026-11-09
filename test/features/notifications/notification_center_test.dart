import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/notifications/domain/notifications_repository.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notice_copy.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notification_bell.dart';
import 'package:vnlfsocialapp/src/features/notifications/presentation/notification_center.dart';

const _member = Session(
  userId: 'owner',
  displayName: 'Chủ nhà',
  role: 'MEMBER',
);

Map<String, Object?> _notice({
  String id = 'n1',
  String type = 'article-liked',
  String href = '/a/cai-arch-linux',
  List<Map<String, Object?>> actors = const [],
  int actorCount = 0,
  Map<String, Object?>? summary = const {
    'title': 'Cài Arch Linux trên Btrfs',
    'excerpt': '',
  },
  String? readAt,
  DateTime? updatedAt,
}) => {
  'id': id,
  'type': type,
  'actorId': null,
  'targetType': 'ARTICLE',
  'targetId': 'article-1',
  'groupKey': null,
  'eventCount': 1,
  'actorCount': actorCount,
  'actors': actors,
  'targetSummary': summary,
  'href': href,
  'payload': <String, Object?>{},
  'readAt': readAt,
  'createdAt': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
  'updatedAt': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
};

Map<String, Object?> _actor(String id, String name) => {
  'id': id,
  'username': id,
  'displayName': name,
  'avatarUrl': null,
};

void main() {
  late List<ApiRequest> requests;

  ApiClient client(List<Map<String, Object?>> items, {int unseen = 0}) {
    requests = [];
    return ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        requests.add(request);
        final body = request.method == 'GET'
            ? {
                'items': items,
                'nextCursor': null,
                'unreadCount': items.where((i) => i['readAt'] == null).length,
                'unseenCount': unseen,
              }
            : {'ok': true};
        return ApiResponse(statusCode: 200, body: jsonEncode(body));
      },
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ApiClient api, {
    List<GoRoute> routes = const [],
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: NotificationCenter()),
        ),
        ...routes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((_) => _member),
          apiClientProvider.overrideWithValue(api),
        ],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a row reads like the website and opens its link in the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpPage(
      tester,
      client([
        _notice(
          actors: [_actor('an', 'An Nhiên'), _actor('binh', 'Bình Minh')],
          actorCount: 5,
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ]),
      routes: [
        GoRoute(
          path: '/thread/:id',
          builder: (_, state) =>
              Scaffold(body: Text('thread ${state.pathParameters['id']}')),
        ),
      ],
    );
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('An Nhiên'), findsOneWidget);
    expect(find.text('Bình Minh'), findsOneWidget);
    expect(
      find.textContaining('và 3 người khác đã thích bài viết của bạn'),
      findsOneWidget,
    );
    expect(find.text('Cài Arch Linux trên Btrfs'), findsOneWidget);
    expect(find.text('3 giờ'), findsOneWidget);

    await tester.tap(find.text('Cài Arch Linux trên Btrfs'));
    await tester.pumpAndSettle();
    expect(find.text('thread cai-arch-linux'), findsOneWidget);
    final read = requests.singleWhere((r) => r.path.endsWith('/read'));
    expect(jsonDecode(read.body!), {
      'ids': ['n1'],
    });
  });

  for (final (href, route, label) in [
    ('/feedback/ticket-1', '/feedback/:id', 'ticket'),
    ('/messages/conversation-1', '/messages/:id', 'conversation'),
    ('/projects/cong-cu', '/projects/:slug', 'project'),
    ('/u/chu-nha?tab=guestbook', '/profile/:id', 'guestbook'),
  ]) {
    testWidgets('$label links open the app screen', (tester) async {
      await pumpPage(
        tester,
        client([_notice(href: href, readAt: '2026-11-01T00:00:00Z')]),
        routes: [
          GoRoute(
            path: route,
            builder: (_, state) =>
                Scaffold(body: Text(state.uri.queryParameters['tab'] ?? label)),
          ),
        ],
      );
      await tester.tap(find.text('Cài Arch Linux trên Btrfs'));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      // A read notice is not marked again.
      expect(requests.where((r) => r.path.endsWith('/read')), isEmpty);
    });
  }

  testWidgets('filters ask the server, and mark all sends no ids', (
    tester,
  ) async {
    await pumpPage(tester, client([_notice()]));
    await tester.tap(find.text('Chưa đọc'));
    await tester.pumpAndSettle();
    expect(requests.last.query['filter'], 'unread');

    await tester.tap(find.bySemanticsLabel('Loại thông báo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bình luận').last);
    await tester.pumpAndSettle();
    expect(requests.last.query['kind'], 'comment');
    expect(requests.last.query['filter'], 'unread');

    await tester.tap(find.text('Đánh dấu tất cả đã đọc'));
    await tester.pumpAndSettle();
    final read = requests.lastWhere((r) => r.path.endsWith('/read'));
    expect(jsonDecode(read.body!), <String, Object?>{});
  });

  testWidgets('opening the list clears the bell only when it shows a count', (
    tester,
  ) async {
    await pumpPage(tester, client([_notice()], unseen: 2));
    expect(requests.where((r) => r.path.endsWith('/seen')), hasLength(1));

    await pumpPage(tester, client([_notice()]));
    expect(requests.where((r) => r.path.endsWith('/seen')), isEmpty);
  });

  testWidgets('an empty list says so with the bell', (tester) async {
    await pumpPage(tester, client([]));
    expect(find.text('Chưa có thông báo nào.'), findsOneWidget);
  });

  testWidgets('the bell opens the compact list, which leads to the page', (
    tester,
  ) async {
    final api = client([_notice()], unseen: 1);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: NotificationBellBox(),
            ),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const Scaffold(body: Text('page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((_) => _member),
          apiClientProvider.overrideWithValue(api),
        ],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byType(NotificationBellBox));
    await tester.pumpAndSettle();
    expect(find.text('Đóng thông báo'), findsNothing);
    expect(find.byTooltip('Đóng thông báo'), findsOneWidget);
    await tester.tap(find.text('Xem tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('guests who press the bell go to sign in', (tester) async {
    var calls = 0;
    final api = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 200, body: '{}');
      },
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Center(child: NotificationBellBox())),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('login')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith((_) => null),
          apiClientProvider.overrideWithValue(api),
        ],
        child: MaterialApp.router(
          theme: VnlfTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.byType(NotificationBellBox));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
    expect(calls, 0);
  });

  group('copy', () {
    CommunityNotice notice(
      String type, {
      String title = '',
      String excerpt = '',
      bool summarized = true,
      Map<String, Object?> payload = const {},
    }) => CommunityNotice(
      id: 'n',
      type: type,
      targetId: 't',
      targetType: 'ARTICLE',
      href: '/',
      title: title,
      excerpt: excerpt,
      summarized: summarized,
      payload: payload,
    );

    test('moderation notices name what was removed and why', () {
      expect(
        notificationAction('moderation-content-removed', {'kind': 'COMMENT'}),
        'đã gỡ bình luận của bạn',
      );
      expect(
        notificationAction('moderation-content-removed', const {}),
        'đã gỡ nội dung của bạn',
      );
      expect(
        notificationSnippet(
          notice(
            'moderation-content-removed',
            title: 'Spam',
            excerpt: 'mua ngay',
          ),
        ),
        'Lý do: Spam · “mua ngay”',
      );
      expect(notificationAction('something-new', const {}), 'có cập nhật mới');
    });

    test('a comment without a summary says it is gone', () {
      expect(
        notificationSnippet(notice('comment-replied', summarized: false)),
        'Bình luận không còn hiển thị',
      );
      expect(notificationSnippet(notice('comment-replied')), '');
    });

    test('kinds pick the badge icon in the website order', () {
      expect(noticeKind('article-liked'), NoticeKind.like);
      expect(noticeKind('comment-mentioned'), NoticeKind.comment);
      expect(noticeIcon('comment-mentioned'), VnlfLucide.atSign);
      expect(noticeIcon('feedback-status'), VnlfLucide.messageSquareText);
      expect(noticeIcon('guestbook-signed'), VnlfLucide.shield);
    });

    test('days follow the calendar in Vietnam', () {
      // 23:30 in Vietnam on 9 November.
      final now = DateTime.utc(2026, 11, 9, 16, 30);
      expect(noticeDay(DateTime.utc(2026, 11, 8, 17, 5), now), 'Hôm nay');
      expect(noticeDay(DateTime.utc(2026, 11, 8, 16, 55), now), 'Hôm qua');
      expect(noticeDay(DateTime.utc(2026, 11, 7, 16, 55), now), 'Trước đó');
      expect(
        noticeAge(now.subtract(const Duration(minutes: 59)), now),
        'Vừa xong',
      );
      expect(noticeAge(now.subtract(const Duration(hours: 23)), now), '23 giờ');
      expect(noticeAge(now.subtract(const Duration(hours: 49)), now), '2 ngày');
    });
  });
}
