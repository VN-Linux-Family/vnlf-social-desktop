import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/main.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/data/fixture_repositories.dart';
import 'package:vnlfsocialapp/src/data/live_post_repository.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/feature_widgets.dart';
import 'package:vnlfsocialapp/src/features/shared/presentation/post_share.dart';

void main() {
  test('discover articles retain the canonical share slug', () async {
    final client = ApiClient(
      transport: fixtureTransport,
      throttleInterval: Duration.zero,
      hostKey: Object(),
    );
    final discover = await FixtureDiscoverRepository(client).getDiscoverData();
    expect(
      canonicalPostUri(discover.articles.first).toString(),
      'https://vietnamlinuxfamily.net/a/trai-nghiem-arch-linux-va-wayland',
    );
  });

  test('article detail retains the canonical share slug', () async {
    final client = ApiClient(
      transport: (_) async => ApiResponse(
        statusCode: 200,
        body: '{"id":"article-1","slug":"huong-dan-linux","author":{}}',
      ),
      throttleInterval: Duration.zero,
      hostKey: Object(),
    );
    final repository = LivePostRepository(
      client,
      FixturePostRepository(FixtureFeedRepository(client)),
    );
    final post = await repository.getPost('article-1');
    expect(
      canonicalPostUri(post!).toString(),
      'https://vietnamlinuxfamily.net/a/huong-dan-linux',
    );
  });

  test('missing slug does not invent a public URL', () {
    expect(
      canonicalPostUri(
        const FeedPost(
          id: 'unknown',
          excerpt: '',
          voteScore: 0,
          commentCount: 0,
          author: Author(username: 'sample', displayName: 'Sample'),
        ),
      ),
      isNull,
    );
  });

  testWidgets('feed and thread share copy the public article URL', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final router = await _pumpApp(tester);
    await tester.tap(find.byIcon(Icons.link_rounded).first);
    await tester.pumpAndSettle();
    expect(
      copied,
      'https://vietnamlinuxfamily.net/a/chao-mung-cong-dong-linux-viet-nam',
    );
    expect(find.text('Đã sao chép liên kết'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/');

    copied = null;
    router.go('/thread/fixture-post-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.link_rounded).first);
    await tester.pumpAndSettle();
    expect(
      copied,
      'https://vietnamlinuxfamily.net/a/chao-mung-cong-dong-linux-viet-nam',
    );
  });

  testWidgets('clipboard failure gives feedback without leaving the post', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'unavailable');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final router = await _pumpApp(tester);
    await tester.tap(find.byIcon(Icons.link_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Không thể sao chép liên kết'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(tester.takeException(), isNull);
  });

  for (final topInset in [0.0, 48.0]) {
    testWidgets('thread consumes top inset once ($topInset)', (tester) async {
      tester.view.padding = FakeViewPadding(top: topInset);
      tester.view.viewPadding = FakeViewPadding(top: topInset);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final router = await _pumpApp(tester);
      router.go('/thread/fixture-post-1');
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(FeatureHeader)).dy, topInset + 12);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<GoRouter> _pumpApp(WidgetTester tester) async {
  tester.platformDispatcher.localesTestValue = const [Locale('vi')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MainApp());
  await tester.pumpAndSettle();
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
      as GoRouter;
}
