import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/composer/data/composer_repository.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_providers.dart';
import 'package:vnlfsocialapp/src/features/composer/presentation/composer_screen.dart';

void main() {
  testWidgets('failed recovery blocks editing and offers retry', (
    tester,
  ) async {
    final storage = _Storage()
      ..values['vnlf.composer.synthetic-owner.new'] =
          '{damaged synthetic draft';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (ref) => const Session(
              userId: 'synthetic-owner',
              username: 'synthetic',
              displayName: 'Thử',
            ),
          ),
          sessionProvider.overrideWithValue(
            const AsyncData(
              Session(
                userId: 'synthetic-owner',
                username: 'synthetic',
                displayName: 'Thử',
              ),
            ),
          ),
          sessionStorageProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(home: ComposerScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FleatherEditor), findsNothing);
    expect(find.text('Tải lại bản nháp'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(
      storage.values['vnlf.composer.synthetic-owner.new'],
      '{damaged synthetic draft',
    );
  });
  testWidgets(
    'signed-in composer retains content on failed save and never acknowledges publication',
    (tester) async {
      final requests = <ApiRequest>[];
      final client = ApiClient(
        hostKey: Object(),
        throttleInterval: Duration.zero,
        transport: (request) async {
          requests.add(request);
          return request.method == 'PATCH'
              ? ApiResponse(statusCode: 503, body: '{}')
              : ApiResponse(
                  statusCode: 201,
                  body: jsonEncode({
                    'id': 'draft-id',
                    'version': 0,
                    'format': 'POST',
                    'status': 'DRAFT',
                  }),
                );
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionStateProvider.overrideWith(
              (ref) => const Session(
                userId: 'synthetic-owner',
                username: 'synthetic',
                displayName: 'Thành viên thử',
              ),
            ),
            sessionProvider.overrideWithValue(
              const AsyncData(
                Session(
                  userId: 'synthetic-owner',
                  username: 'synthetic',
                  displayName: 'Thành viên thử',
                ),
              ),
            ),
            sessionStorageProvider.overrideWithValue(_Storage()),
            composerRepositoryProvider.overrideWithValue(
              LiveComposerRepository(client),
            ),
          ],
          child: const MaterialApp(home: ComposerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final editor = tester.widget<FleatherEditor>(find.byType(FleatherEditor));
      editor.controller.replaceText(0, 0, 'Tiếng Việt: ặ ữ ờ ẫ ệ');
      await tester.pump();
      await tester.tap(find.text('Đăng'));
      await tester.pumpAndSettle();
      expect(requests.map((r) => r.method), ['POST', 'PATCH']);
      expect(find.textContaining('Bản nháp vẫn được giữ'), findsOneWidget);
      expect(find.byType(FleatherEditor), findsOneWidget);
      expect(
        editor.controller.document.toPlainText(),
        contains('Tiếng Việt: ặ ữ ờ ẫ ệ'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('signed-out composer offers login without creating a draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionProvider.overrideWithValue(const AsyncData(null))],
        child: const MaterialApp(home: ComposerScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để viết bài'), findsOneWidget);
    expect(find.byType(FleatherEditor), findsNothing);
  });
}

class _Storage implements SessionStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
