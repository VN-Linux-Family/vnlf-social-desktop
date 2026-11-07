import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/moderation/presentation/report_dialog.dart';

void main() {
  testWidgets(
    'report requires reason, preserves failed draft, and awaits server confirmation',
    (tester) async {
      var succeeds = false;
      final writes = <Map<String, dynamic>>[];
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          expect(request.method, 'POST');
          expect(request.path, '/api/v1/reports');
          writes.add(jsonDecode(request.body!) as Map<String, dynamic>);
          return ApiResponse(
            statusCode: succeeds ? 201 : 403,
            body: succeeds ? '{"reportId":"confirmed-report"}' : '{}',
          );
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(client), sessionStateProvider.overrideWith((ref) => const Session(userId: 'a', displayName: 'A'))],
          child: MaterialApp(
            home: Scaffold(
              body: ReportDialog(
                targetId: '00000000-0000-4000-8000-000000000001',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      await tester.enterText(find.byKey(const Key('report-reason')), 'Spam');
      await tester.enterText(
        find.byKey(const Key('report-detail')),
        'Synthetic moderation test',
      );
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not send'), findsOneWidget);
      expect(find.text('Report received'), findsNothing);
      expect(writes.single['targetType'], 'ARTICLE');
      succeeds = true;
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(writes, hasLength(2));
      expect(find.text('Report received'), findsOneWidget);
    },
  );
  testWidgets('report cannot submit its draft after an account switch', (tester) async {
    var writes = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero, transport: (request) async {
      writes++;
      return ApiResponse(statusCode: 201, body: '{"reportId":"report"}');
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(client), sessionStateProvider.overrideWith((ref) => const Session(userId: 'a', displayName: 'A'))],
      child: const MaterialApp(home: Scaffold(body: ReportDialog(targetId: 'target'))),
    ));
    await tester.enterText(find.byKey(const Key('report-reason')), 'Spam');
    final container = ProviderScope.containerOf(tester.element(find.byType(ReportDialog)));
    container.read(sessionStateProvider.notifier).state = const Session(userId: 'b', displayName: 'B');
    await tester.pump();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.textContaining('Your account changed'), findsOneWidget);
    expect(find.text('Spam'), findsOneWidget);
  });

  testWidgets('same account after session invalidation cannot submit an old draft', (tester) async {
    var writes = 0;
    final client = ApiClient(hostKey: Object(), transport: (request) async {
      writes++;
      return ApiResponse(statusCode: 201, body: '{"reportId":"report"}');
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(client), sessionStateProvider.overrideWith((ref) => const Session(userId: 'a', displayName: 'A'))],
      child: const MaterialApp(home: Scaffold(body: ReportDialog(targetId: 'target'))),
    ));
    await tester.enterText(find.byKey(const Key('report-reason')), 'Spam');
    client.invalidateSession();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.textContaining('Your account changed'), findsOneWidget);
  });

}
