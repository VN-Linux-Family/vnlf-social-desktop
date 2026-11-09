import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/feed/presentation/feed_screen.dart';

void main() {
  testWidgets(
    'guest Following tab stays visible and explains sign-in requirement',
    (tester) async {
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async => request.query['type'] == 'following'
            ? ApiResponse(statusCode: 401, body: '{}')
            : ApiResponse(statusCode: 200, body: '{"items":[]}'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(client),
            sessionProvider.overrideWithValue(const AsyncData(null)),
            sessionStateProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(home: Scaffold(body: FeedScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đang theo dõi'), findsOneWidget);
      expect(find.text('Hôm nay bạn muốn chia sẻ điều gì?'), findsOneWidget);
      await tester.tap(find.text('Đang theo dõi'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có bài nào'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
    },
  );
}
