import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/app_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/channels/domain/channel_models.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/live_channel_state.dart';
import 'package:vnlfsocialapp/src/features/communication/presentation/communication_directory.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';

import '../direct_messages/direct_message_controller_test.dart'
    show ControlledDmRepository;

void main() {
  for (final layout in [
    (360.0, 1.0),
    (900.0, 1.0),
    (1440.0, 1.0),
    (360.0, 1.6),
  ]) {
    testWidgets(
      'actual communication routes at width ${layout.$1}, text ${layout.$2}',
      (tester) async {
        tester.view.physicalSize = Size(layout.$1, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const owner = Session(
          userId: 'test-user',
          displayName: 'Một',
          username: 'mot',
          role: 'MEMBER',
        );
        final paths = <String>[];
        final client = ApiClient(
          hostKey: Object(),
          throttleInterval: Duration.zero,
          transport: (request) async {
            paths.add(request.path);
            return ApiResponse(
              statusCode: 200,
              body: jsonEncode({'items': <Object?>[], 'nextCursor': null}),
            );
          },
        );
        final router = createMainRouter()..go('/messages');
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sessionStateProvider.overrideWith((ref) => owner),
              sessionProvider.overrideWithValue(const AsyncData(owner)),
              preferencesStorageProvider.overrideWithValue(_Preferences()),
              apiClientProvider.overrideWithValue(client),
              directMessageRepositoryProvider.overrideWithValue(
                ControlledDmRepository(),
              ),
              liveChannelsProvider.overrideWith(
                (ref) async => const [
                  ChatChannel(
                    id: 'channel-1',
                    slug: 'linux',
                    name: 'Linux',
                    minRoleToPost: 'MEMBER',
                  ),
                ],
              ),
            ],
            child: MaterialApp.router(
              theme: VnlfTheme.light(),
              locale: const Locale('vi'),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale('vi')],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(layout.$2)),
                child: child!,
              ),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CommunicationDirectory), findsOneWidget);
        expect(
          find.byKey(const Key('communication-channel-channel-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('communication-dm-conv-1')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('dm-chat-input')), findsNothing);
        if (layout.$1 <= 840) {
          expect(find.byType(VnlfMobileBottomNav), findsOneWidget);
        }
        await tester.tap(
          find.byKey(const Key('communication-channel-channel-1')),
        );
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/channels/linux',
        );
        expect(find.byKey(const Key('chat-input')), findsOneWidget);
        expect(paths, contains('/api/v1/channels/channel-1/messages'));
        if (layout.$1 <= 840) {
          expect(find.byType(VnlfMobileStickyHeader), findsNothing);
          expect(find.byType(VnlfMobileBottomNav), findsNothing);
        }
        router.go('/messages/conv-1');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dm-chat-input')), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const Key('dm-conversation-header')))
              .height,
          54,
        );
        if (layout.$1 > 840) {
          expect(
            tester.getSize(find.byType(CommunicationDirectory)).width,
            layout.$1 >= 1181 ? 240 : 205,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Preferences implements PreferencesStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
