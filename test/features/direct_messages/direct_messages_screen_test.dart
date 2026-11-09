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
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_messages_screen.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_tile.dart';

import 'direct_message_repository_test.dart'
    show sampleConversationJson, sampleMessageJson;

void main() {
  testWidgets('collection does not open or mark the first conversation read', (
    tester,
  ) async {
    final paths = <String>[];
    await _pumpDmScreen(
      tester,
      signedIn: true,
      conversationId: null,
      transport: (request) async {
        paths.add(request.path);
        if (request.path == '/api/v1/dm/conversations') {
          return _reply({
            'items': [sampleConversationJson],
          });
        }
        if (request.path == '/api/v1/channels') {
          return _reply({'items': <Object?>[]});
        }
        if (request.path == '/api/v1/dm/conversations/conv-1') {
          return _reply(sampleConversationJson);
        }
        return _reply({
          'items': [sampleMessageJson],
          'nextCursor': null,
        });
      },
    );
    expect(paths.where((path) => path.contains('/conversations/')), isEmpty);
    expect(find.byKey(const Key('dm-chat-input')), findsNothing);
  });

  testWidgets(
    'a missing direct conversation never falls back to another inbox row',
    (tester) async {
      final paths = <String>[];
      await _pumpDmScreen(
        tester,
        signedIn: true,
        conversationId: 'conv-missing',
        transport: (request) async {
          paths.add(request.path);
          if (request.path == '/api/v1/dm/conversations') {
            return _reply({
              'items': [sampleConversationJson],
            });
          }
          if (request.path == '/api/v1/channels') {
            return _reply({'items': <Object?>[]});
          }
          if (request.path.contains('conv-missing')) {
            return ApiResponse(statusCode: 404, body: '{}');
          }
          if (request.path == '/api/v1/dm/conversations/conv-1') {
            return _reply(sampleConversationJson);
          }
          return _reply({
            'items': [sampleMessageJson],
            'nextCursor': null,
          });
        },
      );
      expect(paths.any((path) => path.contains('conv-missing')), isTrue);
      expect(paths.any((path) => path.contains('conv-1')), isFalse);
      expect(find.byKey(const Key('dm-chat-input')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'guest sees sign-in state card without firing any DM network requests',
    (tester) async {
      var calls = 0;
      await _pumpDmScreen(
        tester,
        signedIn: false,
        transport: (_) async {
          calls++;
          return _reply(<String, dynamic>{});
        },
      );

      expect(find.text('Đăng nhập để xem tin nhắn trực tiếp'), findsOneWidget);
      expect(find.byKey(const Key('dm-chat-input')), findsNothing);
      expect(calls, 0);
    },
  );

  testWidgets(
    'failed DM send retains draft, reply target, and Vietnamese message history',
    (tester) async {
      final pendingSend = Completer<ApiResponse>();
      var sendCalls = 0;

      await _pumpDmScreen(
        tester,
        signedIn: true,
        transport: (request) async {
          if (request.method == 'POST' && request.path.endsWith('/messages')) {
            sendCalls++;
            return pendingSend.future;
          }
          if (request.method == 'POST' && request.path.endsWith('/read')) {
            return _reply(<String, dynamic>{
              'ok': true,
              'changed': true,
              'lastReadMessageId': 'msg-1',
            });
          }
          if (request.path == '/api/v1/dm/conversations') {
            return _reply(<String, dynamic>{
              'items': <Map<String, dynamic>>[sampleConversationJson],
            });
          }
          if (request.path == '/api/v1/dm/conversations/conv-1') {
            return _reply(sampleConversationJson);
          }
          return _reply(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                ...sampleMessageJson,
                'attachments': <Object?>[],
              },
            ],
            'nextCursor': null,
            'viewerState': 'ACTIVE',
          });
        },
      );

      expect(
        find.widgetWithText(DirectMessageTile, 'Tiếng Việt: ặ ữ ờ ẫ ệ'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Trả lời'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('dm-chat-input')),
        'Bản nháp DM giữ nguyên',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('dm-send-button')));
      await tester.pump();

      expect(sendCalls, 1);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dm-chat-input')))
            .enabled,
        isFalse,
      );

      pendingSend.complete(
        ApiResponse(statusCode: 403, body: '{"code":"DM_BLOCKED"}'),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dm-chat-input')))
            .controller!
            .text,
        'Bản nháp DM giữ nguyên',
      );
      expect(find.byKey(const Key('dm-operation-error')), findsOneWidget);
      expect(find.textContaining('Đang trả lời'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'incoming pending request shows accept and decline controls instead of text input',
    (tester) async {
      final incomingConversation = <String, dynamic>{
        ...sampleConversationJson,
        'status': 'REQUESTED',
        'viewerState': 'REQUEST_REQUIRED',
        'canSend': false,
      };

      await _pumpDmScreen(
        tester,
        signedIn: true,
        transport: (request) async {
          if (request.path == '/api/v1/dm/conversations') {
            return _reply(<String, dynamic>{
              'items': <Map<String, dynamic>>[incomingConversation],
            });
          }
          if (request.path == '/api/v1/dm/conversations/conv-1') {
            return _reply(incomingConversation);
          }
          return _reply(<String, dynamic>{
            'items': <Object?>[],
            'nextCursor': null,
            'viewerState': 'ACTIVE',
          });
        },
      );

      expect(find.byKey(const Key('dm-chat-input')), findsNothing);
      expect(
        find.byKey(const Key('dm-incoming-request-banner')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('dm-accept-request-button')), findsOneWidget);
      expect(
        find.byKey(const Key('dm-decline-request-button')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpDmScreen(
  WidgetTester tester, {
  required ApiTransport transport,
  required bool signedIn,
  String? conversationId = 'conv-1',
}) async {
  tester.view.physicalSize = const Size(900, 850);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
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
        home: Scaffold(
          body: SafeArea(
            child: DirectMessagesScreen(conversationId: conversationId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ApiResponse _reply(Map<String, dynamic> data) =>
    ApiResponse(statusCode: 200, body: jsonEncode(data));
