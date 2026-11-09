import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/core/preferences_storage.dart';
import 'package:vnlfsocialapp/src/design_system/design_system.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/channels/domain/channel_models.dart';
import 'package:vnlfsocialapp/src/features/channels/presentation/live_channel_state.dart';
import 'package:vnlfsocialapp/src/features/communication/presentation/communication_directory.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/domain/direct_message_models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';

import '../direct_messages/direct_message_controller_test.dart'
    show ControlledDmRepository;

void main() {
  testWidgets(
    'one directory filters channels and DMs, persists collapse and routes selection',
    (tester) async {
      final prefs = _Preferences();
      final repo = ControlledDmRepository();
      final router = await _pump(tester, repo, prefs);
      final channel = find.byKey(const Key('communication-channel-channel-1'));
      final dm = find.byKey(const Key('communication-dm-conv-1'));
      expect(channel, findsOneWidget);
      expect(dm, findsOneWidget);
      await tester.tap(find.byKey(const Key('communication-toggle-channels')));
      await tester.pumpAndSettle();
      expect(channel, findsNothing);
      expect(dm, findsOneWidget);
      expect(prefs.values['vnlf-channels-collapsed'], '1');
      await tester.enterText(
        find.byKey(const Key('communication-search')),
        'linux',
      );
      await tester.pumpAndSettle();
      expect(channel, findsOneWidget);
      expect(dm, findsNothing);
      await tester.enterText(find.byKey(const Key('communication-search')), '');
      await tester.pumpAndSettle();
      expect(channel, findsNothing);
      expect(dm, findsOneWidget);
      await tester.tap(dm);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/messages/conv-1',
      );
      expect(channel, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a confirmed request action is not repeated when refreshing the inbox fails',
    (tester) async {
      final repo = _RequestRepository();
      await _pump(tester, repo, _Preferences());
      final accept = find.byKey(const Key('communication-accept-conv-1'));
      expect(accept, findsOneWidget);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(repo.accepts, 1);
      expect(accept, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<GoRouter> _pump(
  WidgetTester tester,
  ControlledDmRepository repo,
  _Preferences prefs,
) async {
  final router = GoRouter(
    routes: [
      for (final path in ['/channels', '/channels/:slug', '/messages/:id'])
        GoRoute(
          path: path,
          builder: (context, state) =>
              const Scaffold(body: CommunicationDirectory()),
        ),
    ],
    initialLocation: '/channels',
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionStateProvider.overrideWith(
          (ref) => const Session(userId: 'test-user', displayName: 'Bạn'),
        ),
        directMessageRepositoryProvider.overrideWithValue(repo),
        preferencesStorageProvider.overrideWithValue(prefs),
        liveChannelsProvider.overrideWith(
          (ref) async => const [
            ChatChannel(
              id: 'channel-1',
              slug: 'linux',
              name: 'Linux thử nghiệm',
              minRoleToPost: 'MEMBER',
            ),
          ],
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: VnlfTheme.light(),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
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

class _RequestRepository extends ControlledDmRepository {
  _RequestRepository() {
    conversation = conversation.copyWith(
      status: DmConversationStatus.requested,
      viewerState: DmViewerState.requestRequired,
      canSend: false,
    );
  }
  int accepts = 0;
  @override
  Future<void> acceptRequest(String conversationId) async {
    accepts++;
    readFailure = const TransportFailure();
  }
}
