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
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('What would you like to share today?'), findsOneWidget);
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in required'), findsOneWidget);
    },
  );
}
