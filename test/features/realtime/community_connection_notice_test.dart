import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/design_system/tokens/vnlf_theme.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_status.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_connection_notice.dart';

void main() {
  group('CommunityConnectionNotice', () {
    testWidgets('hides while the connection is not presenting a notice', (
      tester,
    ) async {
      for (final phase in [
        CommunityConnectionPhase.idle,
        CommunityConnectionPhase.connected,
        CommunityConnectionPhase.suspended,
        CommunityConnectionPhase.disposed,
      ]) {
        await tester.pumpWidget(
          _app(CommunityConnectionNotice(status: CommunitySocketStatus(phase))),
        );

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(TextButton), findsNothing);
        expect(find.textContaining('tin nhắn'), findsNothing);
      }
    });

    testWidgets('announces Vietnamese progress copy by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.connecting),
          ),
          locale: const Locale('vi'),
        ),
      );

      expect(find.text('Đang kết nối để cập nhật tin nhắn.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('WebSocket'), findsNothing);
    });

    testWidgets('uses English progress copy for an English locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(
              CommunityConnectionPhase.reconnecting,
            ),
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Reconnecting to update messages.'), findsOneWidget);
    });

    testWidgets('offers retry only for failure and invokes its callback', (
      tester,
    ) async {
      var retryCount = 0;
      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.failed),
            onRetry: () => retryCount++,
          ),
        ),
      );

      expect(
        find.text('Tin nhắn mới chưa thể cập nhật lúc này.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Thử lại'));
      expect(retryCount, 1);
    });

    testWidgets('explains failure without a retry control when none is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.failed),
          ),
        ),
      );

      expect(
        find.text('Tin nhắn mới chưa thể cập nhật lúc này.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('revoked session asks for sign-in and never offers retry', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.revoked),
            onRetry: () {},
          ),
        ),
      );

      expect(
        find.text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Thử lại'), findsNothing);
    });

    testWidgets('failure content fits a 360px viewport at text scale 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.failed),
            onRetry: () {},
          ),
          textScaleFactor: 2,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Tin nhắn mới chưa thể cập nhật lúc này.'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('uses a static icon when reduce-motion is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.connecting),
          ),
          disableAnimations: true,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('exposes one live announcement for visible status copy', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          CommunityConnectionNotice(
            status: CommunitySocketStatus(CommunityConnectionPhase.connecting),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Đang kết nối để cập nhật tin nhắn.'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}

Widget _app(
  Widget child, {
  Locale locale = const Locale('vi'),
  double textScaleFactor = 1,
  bool disableAnimations = false,
}) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('vi'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: VnlfTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScaleFactor),
      disableAnimations: disableAnimations,
    ),
    child: child!,
  ),
  home: Scaffold(body: child),
);
