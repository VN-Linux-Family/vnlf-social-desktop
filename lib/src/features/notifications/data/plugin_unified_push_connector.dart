import 'dart:async';

import 'package:unifiedpush/unifiedpush.dart' as unifiedpush;

import 'unified_push_distributor.dart';

/// The `unifiedpush` package's calls. It has an Android connector only, so
/// only Android builds use it.
final class PluginUnifiedPushConnector implements UnifiedPushConnector {
  const PluginUnifiedPushConnector();

  @override
  Future<bool> useDefaultDistributor() =>
      unifiedpush.UnifiedPush.tryUseCurrentOrDefaultDistributor();

  @override
  Future<void> register({required String vapid}) =>
      unifiedpush.UnifiedPush.register(vapid: vapid);

  @override
  Future<void> unregister() => unifiedpush.UnifiedPush.unregister();
}

/// Starts taking UnifiedPush events in this Flutter engine: the app's own,
/// or the headless one the connector starts when a message arrives while
/// the app is closed. Endpoints and refusals go to [distributor], and each
/// message the connector could decrypt goes to [onMessage].
Future<void> listenToUnifiedPush({
  required UnifiedPushDistributor distributor,
  required Future<void> Function(List<int> content) onMessage,
}) => unifiedpush.UnifiedPush.initialize(
  onNewEndpoint: (endpoint, _) => unawaited(
    distributor.endpointChanged((
      url: endpoint.url,
      p256dh: endpoint.pubKeySet?.pubKey,
      auth: endpoint.pubKeySet?.auth,
    )),
  ),
  onRegistrationFailed: (reason, _) =>
      distributor.registrationFailed(reason.name),
  onUnregistered: (_) => unawaited(distributor.unregistered()),
  onMessage: (message, _) {
    // An undecryptable body is dropped, as a browser drops one.
    if (message.decrypted) unawaited(onMessage(message.content));
  },
);
