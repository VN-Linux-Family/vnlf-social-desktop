import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/activity/presentation/activity_page.dart';

void main() {
  testWidgets('signed-out activity never requests private data', (
    tester,
  ) async {
    var calls = 0;
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 500, body: '{}');
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(client)],
        child: const MaterialApp(home: Scaffold(body: ActivityPage())),
      ),
    );
    await tester.pump();
    expect(find.text('Đăng nhập để xem hoạt động'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('signed-in activity reads only the owner calendar', (
    tester,
  ) async {
    final calls = <ApiRequest>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        calls.add(request);
        return ApiResponse(statusCode: 400, body: '{}');
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionStateProvider.overrideWith(
            (_) => const Session(
              userId: 'owner',
              displayName: 'Owner',
              role: 'MEMBER',
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ActivityPage())),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(calls.map((r) => (r.method, r.path)), [
      ('GET', '/api/v1/me/activity-calendar'),
    ]);
    expect(
      find.text('Không tải được hoạt động trong tháng này.'),
      findsOneWidget,
    );
  });
}
