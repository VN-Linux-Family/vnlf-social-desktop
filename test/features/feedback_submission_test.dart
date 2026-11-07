import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';

void main() {
  testWidgets(
    'feedback rejects short detail and never claims failed writes succeeded',
    (tester) async {
      final bodies = <Map<String, dynamic>>[];
      var succeeds = false;
      var malformed = false;
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          bodies.add(jsonDecode(request.body!) as Map<String, dynamic>);
          return ApiResponse(
            statusCode: succeeds || malformed ? 200 : 503,
            body: succeeds
                ? '{"submissionId":"confirmed","reference":"F-1","rewardQueued":false,"duplicate":false}'
                : '{}',
          );
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(client)],
          child: MaterialApp(
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () => showFeedbackDialog(context, ref),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final input = find.byType(TextField).first;
      await tester.enterText(input, 'Quá ngắn');
      await tester.tap(find.text('Gửi cho VNLF'));
      await tester.pumpAndSettle();
      expect(bodies, isEmpty);
      expect(find.textContaining('20'), findsWidgets);
      await tester.enterText(
        input,
        'Nội dung góp ý bằng tiếng Việt đủ dài để gửi.',
      );
      await tester.tap(find.text('Gửi cho VNLF'));
      await tester.pumpAndSettle();
      expect(find.text('Đã ghi nhận phản hồi!'), findsNothing);
      expect(find.textContaining('Chưa xác nhận được kết quả'), findsOneWidget);
      expect(tester.widget<TextField>(input).enabled, isFalse);
      expect(
        tester.widget<TextField>(input).controller!.text,
        contains('tiếng Việt'),
      );
      final identity = bodies.single['clientSubmissionId'];
      expect(
        identity,
        matches(
          RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
          ),
        ),
      );
      malformed = true;
      await tester.tap(find.text('Gửi cho VNLF'));
      await tester.pumpAndSettle();
      expect(find.text('Đã ghi nhận phản hồi!'), findsNothing);
      expect(find.textContaining('Chưa xác nhận được kết quả'), findsOneWidget);
      expect(bodies.last['clientSubmissionId'], identity);
      succeeds = true;
      await tester.tap(find.text('Gửi cho VNLF'));
      await tester.pumpAndSettle();
      expect(bodies, hasLength(3));
      expect(bodies.last['clientSubmissionId'], identity);
      expect(find.text('Đã ghi nhận phản hồi!'), findsOneWidget);
    },
  );
}
