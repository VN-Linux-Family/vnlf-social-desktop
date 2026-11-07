import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/app/providers.dart';
import 'package:vnlfsocialapp/src/domain/models.dart';
import 'package:vnlfsocialapp/src/features/direct_messages/presentation/direct_message_state.dart';
import 'package:vnlfsocialapp/src/features/realtime/data/community_socket_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/chat_realtime_bindings.dart';
import 'package:vnlfsocialapp/src/features/realtime/presentation/community_realtime_providers.dart';

import '../direct_messages/direct_message_controller_test.dart'
    show ControlledDmRepository;
import 'community_provider_test.dart' show FakeConnection;

void main() {
  testWidgets('an invalid direct-link id does not crash the realtime wrapper', (
    tester,
  ) async {
    final socket = FakeConnection();
    final client = CommunitySocketClient(connector: () async => socket);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStateProvider.overrideWith(
            (_) => const Session(
              userId: 'owner',
              displayName: 'Owner',
              role: 'MEMBER',
            ),
          ),
          communitySocketProvider.overrideWithValue(client),
          directMessageRepositoryProvider.overrideWithValue(
            ControlledDmRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DmRealtimeBinding(
              conversationId: 'bad-id',
              child: Text('route'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('route'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await client.dispose();
  });
}
