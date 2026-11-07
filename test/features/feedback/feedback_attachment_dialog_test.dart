import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/session_storage_contract.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/feedback_media_repository.dart';
import 'package:vnlfsocialapp/src/features/feedback/presentation/feedback_attachment_dialog.dart';

void main() {
  testWidgets('debounced text survives reopening the dialog', (tester) async {
    final storage = _Memory();
    final client = ApiClient(hostKey: Object(), transport: (_) async =>
      ApiResponse(statusCode: 200, body: '{}'));
    Widget app(bool show) => ProviderScope(overrides: [
      sessionStateProvider.overrideWith((ref) => const Session(userId: 'owner', displayName: 'Owner')),
      sessionStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWithValue(client),
    ], child: MaterialApp(locale: const Locale('vi'), supportedLocales: const [Locale('vi')],
      home: Scaffold(body: show ? const FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/') : const SizedBox())));
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

  testWidgets('storage failure is visible and disables sending', (tester) async {
    final storage = _Memory();
    final client = ApiClient(hostKey: Object(), transport: (_) async =>
      ApiResponse(statusCode: 200, body: '{}'));
    await tester.pumpWidget(ProviderScope(overrides: [
      sessionStateProvider.overrideWith((ref) => const Session(userId: 'owner', displayName: 'Owner')),
      sessionStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWithValue(client),
    ], child: const MaterialApp(locale: Locale('vi'), supportedLocales: [Locale('vi')],
      home: Scaffold(body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/')))));
    await tester.pumpAndSettle();
    storage.failWrites = true;
    await tester.enterText(find.byType(TextField), 'Nội dung không lưu được');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.textContaining('Không lưu được bản nháp'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Gửi cho VNLF')).onPressed, isNull);
  });

  testWidgets('invalid selected file is rejected without a presign', (tester) async {
    var calls = 0;
    final client = ApiClient(hostKey: Object(), throttleInterval: Duration.zero,
      transport: (_) async { calls++; return ApiResponse(statusCode: 200, body: '{}'); });
    await tester.pumpWidget(ProviderScope(overrides: [
      sessionStateProvider.overrideWith((ref) => const Session(userId: 'owner', displayName: 'Owner')),
      sessionStorageProvider.overrideWithValue(_Memory()),
      apiClientProvider.overrideWithValue(client),
      feedbackFilePickerProvider.overrideWithValue(() async => FeedbackMediaFile(
        name: 'bad.svg', mime: 'image/svg+xml', length: 1, openRead: () => Stream.value([1]))),
    ], child: const MaterialApp(locale: Locale('vi'), supportedLocales: [Locale('vi')],
      home: Scaffold(body: FeedbackAttachmentDialog(ownerId: 'owner', pagePath: '/')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm tệp'));
    await tester.pumpAndSettle();
    expect(find.text('Tệp không hợp lệ hoặc vượt quá giới hạn kích thước.'), findsOneWidget);
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
  Future<void> delete(String key) async { values.remove(key); }
}
