import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/community_socket_client.dart';
import '../data/io_community_connection.dart';
import '../domain/community_connection.dart';

final communityConnectorProvider = Provider<CommunityConnector?>((ref) {
  final transport = ref.watch(ioTransportProvider);
  if (transport == null) return null;
  final api = ref.watch(apiClientProvider);
  // Capture a fresh scope for each attempt, while provider disposal binds owner.
  return () => IoCommunityConnection.connect(transport, api.captureSession());
});

final communitySocketProvider = Provider<CommunitySocketClient?>((ref) {
  final session = ref.watch(sessionStateProvider);
  final connector = ref.watch(communityConnectorProvider);
  if (session == null || session.userId.isEmpty || connector == null) {
    return null;
  }
  final client = CommunitySocketClient(connector: connector);
  final cancel = ref.watch(apiClientProvider).observeSessionInvalidation(() {
    unawaited(client.dispose());
  });
  ref.onDispose(() {
    cancel();
    unawaited(client.dispose());
  });
  return client;
});
