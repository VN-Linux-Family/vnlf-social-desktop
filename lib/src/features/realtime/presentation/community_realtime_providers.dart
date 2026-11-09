import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/android_background_service.dart';
import '../../../core/desktop_tray_service.dart';
import '../data/community_socket_client.dart';
import '../data/io_community_connection.dart';
import '../domain/community_connection.dart';

/// The Android foreground service runs only while it keeps a signed-in
/// realtime connection alive for background notifications.
final androidBackgroundServiceWantedProvider = Provider<bool>((ref) {
  final session = ref.watch(sessionStateProvider);
  return ref.watch(androidPlatformProvider) &&
      ref.watch(androidBackgroundSyncProvider) &&
      session != null &&
      session.userId.isNotEmpty;
});

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
  final desktopMinimize = ref.watch(desktopMinimizeToTrayProvider);
  final androidSync = ref.watch(androidBackgroundSyncProvider);
  final keepAlive =
      (DesktopTrayService.isDesktop && desktopMinimize) ||
      (AndroidBackgroundService.isAndroid && androidSync);

  final client = CommunitySocketClient(
    connector: connector,
    keepAliveInBackground: keepAlive,
  );
  final cancel = ref.watch(apiClientProvider).observeSessionInvalidation(() {
    unawaited(client.dispose());
  });
  ref.onDispose(() {
    cancel();
    unawaited(client.dispose());
  });
  return client;
});
