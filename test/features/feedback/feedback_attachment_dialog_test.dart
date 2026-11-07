import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_media_repository.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_draft_store.dart';
import 'package:vnlfsocialapp/src/features/feedback/presentation/feedback_attachment_dialog.dart';

void main() {
  testWidgets('history navigation saves the current feedback draft', (
    tester,
  ) async {
    final storage = _Memory();
    var openedHistory = false;
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (_) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
          sessionStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  openedHistory =
                      await showDialog<bool>(
                        context: context,
                        builder: (_) => const FeedbackAttachmentDialog(
                          ownerId: 'owner',
                          pagePath: '/',
                        ),
                      ) ==
                      true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bản nháp cần được giữ lại');
    await tester.tap(find.text('Góp ý của tôi'));
    await tester.pumpAndSettle();
    expect(openedHistory, isTrue);
    expect(
      (await FeedbackDraftStore(storage).read('owner'))!.detail,
      'Bản nháp cần được giữ lại',
    );
  });

  testWidgets('uploads a selected attachment and submits its confirmed ID', (
    tester,
  ) async {
    final requests = <ApiRequest>[];
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (request) async {
        requests.add(request);
        if (request.path.endsWith('/presign')) {
          return ApiResponse(
            statusCode: 200,
            body: '{"assetId":"asset-1","uploadUrl":"https://storage.invalid/upload","expiresIn":600,"headers":{"content-type":"image/png"}}',
          );
        }
        if (request.path.endsWith('/complete')) {
          return ApiResponse(
            statusCode: 200,
            body: '{"assetId":"asset-1","status":"READY"}',
          );
        }
        return ApiResponse(
          statusCode: 201,
          body: '{"submissionId":"ticket-1","reference":"VNLF-1234","rewardQueued":true,"duplicate":false}',
        );
      },
    );
    var uploads = 0;
    final media = FeedbackMediaRepository(
      client,
      upload: (_, file, _) async {
        expect(await file.openRead().expand((bytes) => bytes).toList(), [
          1,
          2,
          3,
        ]);
        uploads++;
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (_) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
          sessionStorageProvider.overrideWithValue(_Memory()),
          apiClientProvider.overrideWithValue(client),
          feedbackMediaRepositoryProvider.overrideWithValue(media),
          feedbackFilePickerProvider.overrideWithValue(
            () async => FeedbackMediaFile(
              name: 'sample.png',
              mime: 'image/png',
              length: 3,
              openRead: () => Stream.value([1, 2, 3]),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Đây là nội dung góp ý đủ dài để gửi.',
    );
    await tester.ensureVisible(find.text('Thêm tệp'));
    await tester.tap(find.text('Thêm tệp'));
    await tester.pumpAndSettle();
    expect(find.text('sample.png'), findsOneWidget);
    expect(uploads, 1);
    await tester.tap(find.text('Gửi cho VNLF'));
    await tester.pumpAndSettle();
    expect(find.text('Đã ghi nhận phản hồi!'), findsOneWidget);
    expect(requests.map((r) => r.path), [
      '/api/v1/feedback/assets/presign',
      '/api/v1/feedback/assets/asset-1/complete',
      '/api/v1/feedback',
    ]);
    final presign = jsonDecode(requests.first.body!) as Map<String, dynamic>;
    final submit = jsonDecode(requests.last.body!) as Map<String, dynamic>;
    expect(submit['clientSubmissionId'], presign['clientSubmissionId']);
    expect(submit['assetIds'], ['asset-1']);
  });

  testWidgets(
    'failed owner preservation stays redacted and can be retried by owner',
    (tester) async {
      final storage = _Memory();
      final client = ApiClient(
        hostKey: Object(),
        transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
      );
      final container = ProviderContainer(
        overrides: [
          sessionStateProvider.overrideWith(
            (ref) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
          sessionStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('vi'),
            supportedLocales: [Locale('vi')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: Scaffold(
              body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nội dung riêng cần lưu');
      storage.failWrites = true;
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'other',
        displayName: 'Other',
      );
      await tester.pumpAndSettle();
      expect(find.text('Nội dung riêng cần lưu'), findsNothing);
      expect(find.textContaining('Không thể lưu thay đổi'), findsOneWidget);
      expect(find.text('Thử lưu lại'), findsNothing);
      storage.failWrites = false;
      container.read(sessionStateProvider.notifier).state = const Session(
        userId: 'owner',
        displayName: 'Owner',
      );
      await tester.pump();
      await tester.tap(find.text('Thử lưu lại'));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung riêng cần lưu'), findsNothing);
      expect(
        (await FeedbackDraftStore(storage).read('owner'))!.detail,
        'Nội dung riêng cần lưu',
      );
    },
  );

  testWidgets('switching accounts hides and preserves a pending edit', (
    tester,
  ) async {
    final storage = _Memory();
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    final container = ProviderContainer(
      overrides: [
        sessionStateProvider.overrideWith(
          (ref) => const Session(userId: 'owner', displayName: 'Owner'),
        ),
        sessionStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Nội dung riêng của chủ tài khoản',
    );
    container.read(sessionStateProvider.notifier).state = const Session(
      userId: 'other',
      displayName: 'Other',
    );
    await tester.pump();
    expect(find.text('Nội dung riêng của chủ tài khoản'), findsNothing);
    expect(find.text('Tài khoản đã thay đổi'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      (await FeedbackDraftStore(storage).read('owner'))!.detail,
      'Nội dung riêng của chủ tài khoản',
    );
    expect(await FeedbackDraftStore(storage).read('other'), isNull);
  });

  testWidgets('debounced text survives reopening the dialog', (tester) async {
    final storage = _Memory();
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    Widget app(bool show) => ProviderScope(
      overrides: [
        sessionStateProvider.overrideWith(
          (ref) => const Session(userId: 'owner', displayName: 'Owner'),
        ),
        sessionStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(client),
      ],
      child: MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: show
              ? const FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/')
              : const SizedBox(),
        ),
      ),
    );
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nội dung đã lưu an toàn');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung đã lưu an toàn'), findsOneWidget);
  });

  testWidgets('storage failure is visible and disables sending', (
    tester,
  ) async {
    final storage = _Memory();
    final client = ApiClient(
      hostKey: Object(),
      transport: (_) async => ApiResponse(statusCode: 200, body: '{}'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (ref) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
          sessionStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWithValue(client),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    storage.failWrites = true;
    await tester.enterText(find.byType(TextField), 'Nội dung không lưu được');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.textContaining('Không lưu được bản nháp'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Gửi cho VNLF'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('invalid selected file is rejected without a presign', (
    tester,
  ) async {
    var calls = 0;
    final client = ApiClient(
      hostKey: Object(),
      throttleInterval: Duration.zero,
      transport: (_) async {
        calls++;
        return ApiResponse(statusCode: 200, body: '{}');
      },
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (ref) => const Session(userId: 'owner', displayName: 'Owner'),
          ),
          sessionStorageProvider.overrideWithValue(_Memory()),
          apiClientProvider.overrideWithValue(client),
          feedbackFilePickerProvider.overrideWithValue(
            () async => FeedbackMediaFile(
              name: 'bad.svg',
              mime: 'image/svg+xml',
              length: 1,
              openRead: () => Stream.value([1]),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          supportedLocales: [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm tệp'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tệp không hợp lệ hoặc vượt quá giới hạn kích thước.'),
      findsOneWidget,
    );
    expect(calls, 0);
  });
}

final class _Memory implements SessionStorage {
  final values = <String, String>{};
  bool failWrites = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('storage failed');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
