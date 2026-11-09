import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/live_channels_screen.dart';

import 'live_channels_test.dart' show channelJson, messageJson;

void main() {
  testWidgets(
    'live guest sees sign in without synthetic channels or requests',
    (tester) async {
      var calls = 0;
      await pump(
        tester,
        transport: (_) async {
          calls++;
          return reply({});
        },
      );
      expect(find.text('Đăng nhập để xem kênh cộng đồng'), findsOneWidget);
      expect(find.text('#chung'), findsNothing);
      expect(find.byKey(const Key('chat-input')), findsNothing);
      expect(calls, 0);
    },
  );

  testWidgets('failed live send retains draft, reply and server history', (
    tester,
  ) async {
    final pending = Completer<ApiResponse>();
    var sends = 0;
    await pump(
      tester,
      signedIn: true,
      transport: (request) async {
        if (request.method == 'POST') {
          if (request.path.endsWith('/read')) {
            return reply({'ok': true, 'changed': true});
          }
          sends++;
          return pending.future;
        }
        if (request.path == '/api/v1/channels') {
          return reply({
            'items': [
              {...channelJson, 'minRoleToPost': 'MEMBER'},
            ],
          });
        }
        return reply({
          'items': [messageJson],
          'nextCursor': null,
        });
      },
    );
    await tester.tap(find.byTooltip('Trả lời'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Bản nháp của tôi',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi tin nhắn'));
    await tester.pump();
    expect(sends, 1);
    expect(find.text('Bản nháp của tôi'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('chat-input'))).enabled,
      isFalse,
    );
    pending.complete(ApiResponse(statusCode: 403, body: '{}'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-input')))
          .controller!
          .text,
      'Bản nháp của tôi',
    );
    expect(find.byKey(const Key('channel-operation-error')), findsOneWidget);
    expect(find.textContaining('Đang trả lời'), findsOneWidget);
    expect(find.text('Tiếng Việt: ặ ữ ờ ẫ ệ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'archived and restricted channels do not expose a send composer',
    (tester) async {
      await pump(
        tester,
        signedIn: true,
        transport: (request) async {
          if (request.path == '/api/v1/channels') {
            return reply({
              'items': [channelJson],
            });
          }
          return reply({'items': <Object?>[], 'nextCursor': null});
        },
      );
      expect(find.byKey(const Key('chat-input')), findsNothing);
      expect(
        find.text('Bạn chưa có quyền gửi tin nhắn trong kênh này.'),
        findsOneWidget,
      );
      expect(find.text('Chưa có tin nhắn'), findsOneWidget);
    },
  );

  testWidgets(
    'channel history authorization failure offers refresh and no fake messages',
    (tester) async {
      await pump(
        tester,
        signedIn: true,
        transport: (request) async {
          if (request.path == '/api/v1/channels') {
            return reply({
              'items': [channelJson],
            });
          }
          return ApiResponse(statusCode: 403, body: '{}');
        },
      );
      expect(
        find.text('Bạn chưa có quyền truy cập nội dung này.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Làm mới tin nhắn'), findsOneWidget);
      expect(find.text('Chưa có tin nhắn'), findsNothing);
    },
  );
}

Future<void> pump(
  WidgetTester tester, {
  required ApiTransport transport,
  bool signedIn = false,
}) async {
  tester.view.physicalSize = const Size(400, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient(
            transport: transport,
            cacheDuration: Duration.zero,
            throttleInterval: Duration.zero,
            hostKey: Object(),
          ),
        ),
        sessionStateProvider.overrideWith(
          (ref) => signedIn
              ? const Session(userId: 'me', displayName: 'Tôi', role: 'MEMBER')
              : null,
        ),
      ],
      child: MaterialApp(
        theme: VnlfTheme.light(),
        locale: const Locale('vi'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('vi')],
        home: const Scaffold(
          body: SafeArea(child: LiveChannelsScreen(channelSlug: 'linux')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ApiResponse reply(Map<String, dynamic> data) =>
    ApiResponse(statusCode: 200, body: jsonEncode(data));
