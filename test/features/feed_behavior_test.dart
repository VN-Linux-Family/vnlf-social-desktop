import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/l10n/app_localizations.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/feed_notifier.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/feed_screen.dart';

void main() {
  testWidgets('pending feed uses shared shimmer then renders data', (
    tester,
  ) async {
    final pending = Completer<ApiResponse>();
    await _pumpFeed(tester, (_) => pending.future, settle: false);
    expect(find.byType(VnlfPostCardSkeleton), findsOneWidget);
    expect(
      tester
          .widgetList<VnlfSkeletonShimmerScope>(
            find.byType(VnlfSkeletonShimmerScope),
          )
          .any((scope) => scope.controller != null),
      isTrue,
    );
    pending.complete(_page('Bài viết đã tải'));
    await tester.pumpAndSettle();
    expect(find.text('Bài viết đã tải'), findsOneWidget);
    expect(find.byType(VnlfPostCardSkeleton), findsNothing);
  });

  testWidgets('empty feed can be refreshed to show new data', (tester) async {
    var requests = 0;
    await _pumpFeed(
      tester,
      (_) async =>
          ++requests == 1 ? _page('', count: 0) : _page('Bài viết mới'),
    );
    expect(find.byType(VnlfFeedEmptyState), findsOneWidget);
    await tester.tap(find.text('Làm mới'));
    await tester.pumpAndSettle();
    expect(find.text('Bài viết mới'), findsOneWidget);
  });

  testWidgets('feed failure displays retry and recovers', (tester) async {
    var requests = 0;
    await _pumpFeed(
      tester,
      (_) async => ++requests == 1
          ? ApiResponse(statusCode: 404, body: '{}')
          : _page('Đã thử lại'),
    );
    expect(find.byType(VnlfFeedErrorState), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Đã thử lại'), findsOneWidget);
  });

  testWidgets('tabs request their feed type and ignore stale tab results', (
    tester,
  ) async {
    final latest = Completer<ApiResponse>();
    await _pumpFeed(tester, (request) async {
      return switch (request.query['type']) {
        'latest' => latest.future,
        'top' || 'trending' => _page('Được chú ý từ máy chủ'),
        'articles' || 'article' => _page('Article từ máy chủ'),
        'following' => _page('Đang theo dõi từ máy chủ'),
        _ => throw StateError('Missing feed type: ${request.query['type']}'),
      };
    }, settle: false);
    await tester.tap(find.text('Được chú ý'));
    await tester.pumpAndSettle();
    expect(find.text('Được chú ý từ máy chủ'), findsOneWidget);
    latest.complete(_page('Kết quả cũ'));
    await tester.pumpAndSettle();
    expect(find.text('Kết quả cũ'), findsNothing);
    await tester.tap(find.text('Article'));
    await tester.pumpAndSettle();
    expect(find.text('Article từ máy chủ'), findsOneWidget);
    await tester.tap(find.text('Đang theo dõi'));
    await tester.pumpAndSettle();
    expect(find.text('Yêu cầu đăng nhập'), findsOneWidget);
  });

  testWidgets('scroll appends the next cursor page and stops at the end', (
    tester,
  ) async {
    var pages = 0;
    await _pumpFeed(tester, (request) async {
      pages++;
      return request.query['cursor'] == 'page-2'
          ? _page('Tiếp theo', id: 'second')
          : _page('Trang đầu', count: 8, nextCursor: 'page-2');
    });
    await tester.scrollUntilVisible(
      find.text('Tiếp theo'),
      550,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tiếp theo'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(pages, 2);
  });

  testWidgets('pull to refresh fetches new data before the cache expires', (
    tester,
  ) async {
    var requests = 0;
    await _pumpFeed(
      tester,
      (_) async => _page(++requests == 1 ? 'Bản cũ' : 'Bản mới'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('Bản mới'), findsOneWidget);
    expect(find.text('Bản cũ'), findsNothing);
  });

  testWidgets(
    'pagination failure retains posts and waits for an explicit retry',
    (tester) async {
      var pageRequests = 0;
      final container = await _pumpFeed(tester, (request) async {
        if (request.query['cursor'] == null) {
          return _page('Đã tải', nextCursor: 'page-2');
        }
        return ++pageRequests == 1
            ? ApiResponse(statusCode: 404, body: '{}')
            : _page('Đã phục hồi', id: 'second');
      });
      await container
          .read(feedNotifierProvider(FeedTab.latest).notifier)
          .loadMore();
      await tester.pumpAndSettle();
      expect(find.text('Đã tải'), findsOneWidget);
      expect(find.text('Không tải được bài viết tiếp theo'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(pageRequests, 1);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đã phục hồi'), findsOneWidget);
      expect(find.text('Đã tải'), findsOneWidget);
    },
  );

  testWidgets('refresh discards an in-flight pagination result', (
    tester,
  ) async {
    final pending = Completer<ApiResponse>();
    var initialRequests = 0;
    final container = await _pumpFeed(tester, (request) async {
      if (request.query['cursor'] != null) return pending.future;
      return ++initialRequests == 1
          ? _page('Cũ', nextCursor: 'page-2')
          : _page('Mới');
    });
    final notifier = container.read(
      feedNotifierProvider(FeedTab.latest).notifier,
    );
    final pagination = notifier.loadMore();
    await notifier.refresh();
    pending.complete(_page('Trang cũ', id: 'second'));
    await pagination;
    await tester.pumpAndSettle();
    expect(find.text('Mới'), findsOneWidget);
    expect(find.text('Trang cũ'), findsNothing);
  });
}

ApiResponse _page(
  String excerpt, {
  int count = 1,
  String id = 'first',
  String? nextCursor,
}) {
  final fixture = jsonDecode(
    File('test/fixtures/feed.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final template =
      (fixture['items'] as List<dynamic>).first as Map<String, dynamic>;
  return ApiResponse(
    statusCode: 200,
    body: jsonEncode({
      'items': [
        for (var i = 0; i < count; i++)
          {
            ...template,
            'id': '$id-$i',
            'excerpt': count == 1 ? excerpt : '$excerpt $i',
          },
      ],
      'nextCursor': nextCursor,
    }),
  );
}

Future<ProviderContainer> _pumpFeed(
  WidgetTester tester,
  ApiTransport transport, {
  bool settle = true,
}) async {
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(
        ApiClient(
          transport: transport,
          throttleInterval: Duration.zero,
          hostKey: Object(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: VnlfTheme.light(),
        home: const Scaffold(body: FeedScreen()),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return container;
}
