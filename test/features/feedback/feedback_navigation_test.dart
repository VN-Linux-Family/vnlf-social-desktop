import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/feedback/feedback.dart';

void main() {
  testWidgets('member can open their feedback thread and send a message', (
    tester,
  ) async {
    const owner = Session(
      userId: 'owner',
      username: 'owner',
      displayName: 'Owner',
      role: 'MEMBER',
    );
    final repo = _FeedbackFake();
    final router = createMainRouter()..go('/feedback');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ioTransportProvider.overrideWithValue(null),
          sessionStateProvider.overrideWith((_) => owner),
          sessionProvider.overrideWithValue(const AsyncData(owner)),
          feedbackRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: VnlfTheme.light(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('VNLF-FEED0001'), findsOneWidget);
    await tester.tap(find.text('VNLF-FEED0001'));
    await tester.pumpAndSettle();
    expect(find.text('Đội VNLF đã nhận.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Cảm ơn đội ngũ');
    await tester.pump();
    await tester.tap(find.text('Gửi tin nhắn'));
    await tester.pumpAndSettle();
    expect(repo.sends, 1);
    expect(find.text('Cảm ơn đội ngũ'), findsOneWidget);
  });
}

class _FeedbackFake implements FeedbackRepository {
  int sends = 0;
  final ticket = FeedbackTicket(
    id: '11111111-1111-4111-8111-111111111111',
    reference: 'VNLF-FEED0001',
    kind: FeedbackKind.feedback,
    status: FeedbackStatus.open,
    detail: 'Góp ý thử nghiệm',
    pagePath: '/',
    attachmentCount: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    messageCount: 1,
    staffReplied: true,
  );
  final messages = <FeedbackMessage>[
    FeedbackMessage(
      id: 'staff',
      staff: true,
      mine: false,
      content: 'Đội VNLF đã nhận.',
      createdAt: DateTime.utc(2026),
    ),
  ];
  @override
  Future<List<FeedbackTicket>> loadMine({bool refresh = false}) async => [
    ticket,
  ];
  @override
  Future<FeedbackThread> loadThread(
    String ticketId, {
    bool refresh = false,
  }) async => FeedbackThread(ticket: ticket, messages: messages);
  @override
  Future<FeedbackMessage> sendMessage({
    required String ticketId,
    required String clientMessageId,
    required String content,
  }) async {
    sends++;
    final message = FeedbackMessage(
      id: 'own',
      staff: false,
      mine: true,
      content: content,
      createdAt: DateTime.utc(2026),
    );
    messages.add(message);
    return message;
  }
}
