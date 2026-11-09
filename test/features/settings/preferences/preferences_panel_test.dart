import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/settings/preferences/motion_preference_scope.dart';
import 'package:vnlfsocialapp/src/features/settings/preferences/preferences_panel.dart';

void main() {
  testWidgets('motion setting preserves the system accessibility choice', (
    tester,
  ) async {
    Future<void> render(bool system, bool preference) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: system),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MotionPreferenceScope(
            reduceMotion: preference,
            child: Builder(
              builder: (context) => Text(
                MediaQuery.disableAnimationsOf(context)
                    ? 'reduced'
                    : 'standard',
              ),
            ),
          ),
        ),
      ),
    );
    await render(false, false);
    expect(find.text('standard'), findsOneWidget);
    await render(false, true);
    expect(find.text('reduced'), findsOneWidget);
    await render(true, false);
    expect(find.text('reduced'), findsOneWidget);
  });

  testWidgets('a preference is saved without overwriting the other fields', (
    tester,
  ) async {
    final requests = <ApiRequest>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        requests.add(request);
        return ApiResponse(
          statusCode: 200,
          body: request.method == 'GET' ? '{}' : '{"ok":true}',
        );
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionStateProvider.overrideWith(
            (_) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PreferencesPanel()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hiển thị trạng thái trực tuyến'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lưu'));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    final write = requests.singleWhere((request) => request.method == 'PATCH');
    expect(jsonDecode(write.body!), {'onlineVisible': false});
    expect(find.text('Đã lưu cài đặt.'), findsOneWidget);
  });

  testWidgets(
    'account switch hides prior settings while the new account loads',
    (tester) async {
      var reads = 0;
      final next = Completer<ApiResponse>();
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (_) async {
          if (++reads == 1) {
            return ApiResponse(
              statusCode: 200,
              body: '{"onlineVisible":false}',
            );
          }
          return next.future;
        },
      );
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          sessionStateProvider.overrideWith(
            (_) => const Session(userId: 'first', displayName: 'First'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PreferencesPanel()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(
                SwitchListTile,
                'Hiển thị trạng thái trực tuyến',
              ),
            )
            .value,
        isFalse,
      );
      client.invalidateSession();
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'second',
        displayName: 'Second',
      );
      await tester.pump();
      expect(find.text('Hiển thị trạng thái trực tuyến'), findsNothing);
      next.complete(
        ApiResponse(statusCode: 200, body: '{"onlineVisible":true}'),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(
                SwitchListTile,
                'Hiển thị trạng thái trực tuyến',
              ),
            )
            .value,
        isTrue,
      );
    },
  );
}
