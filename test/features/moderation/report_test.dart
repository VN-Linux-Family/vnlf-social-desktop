import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
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
          overrides: [apiClientProvider.overrideWithValue(client)],
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
}
