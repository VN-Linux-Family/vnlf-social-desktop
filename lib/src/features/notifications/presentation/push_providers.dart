import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/session_storage.dart';
import '../../shared/presentation/feature_samples.dart';
import '../data/live_push_subscriptions_repository.dart';
import '../data/local_notification_service.dart';
import '../data/plugin_unified_push_connector.dart';
import '../data/push_registration.dart';
import '../data/unified_push_distributor.dart';
import '../domain/push_message.dart';
import '../domain/push_subscriptions_repository.dart';
import 'push_message_presenter.dart';

/// The argument the UnifiedPush connector starts the app's entrypoint with
/// when a message arrives while the app is closed.
const unifiedPushBackgroundArg = '--unifiedpush-bg';

/// This device's push service: a UnifiedPush distributor in Android builds
/// that talk to a server, none elsewhere (the package has only an Android
/// connector).
final pushDistributorProvider = Provider<UnifiedPushDistributor?>((ref) {
  if (offlineFeatures || ref.watch(ioTransportProvider) == null) return null;
  if (!Platform.isAndroid) return null;
  return UnifiedPushDistributor(
    const PluginUnifiedPushConnector(),
    ref.watch(sessionStorageProvider),
  );
});

final pushSubscriptionsRepositoryProvider =
    Provider<PushSubscriptionsRepository>(
      (ref) => LivePushSubscriptionsRepository(ref.watch(apiClientProvider)),
    );

/// Turns this device's push notifications on and off; null where the
/// device has no push service.
final pushRegistrationProvider = Provider<PushRegistration?>((ref) {
  final distributor = ref.watch(pushDistributorProvider);
  if (distributor == null) return null;
  return PushRegistration(
    ref.watch(pushSubscriptionsRepositoryProvider),
    distributor,
  );
});

/// Shows a decrypted push body the way `push-sw.js` does, or drops it.
Future<void> presentPushContent(
  List<int> content,
  PushMessagePresenter presenter,
) async {
  final message = PushMessage.decode(content);
  if (message != null) await presenter.present(message);
}

/// The headless entry the UnifiedPush connector starts when a message
/// arrives while the app is closed: it only shows notifications. An endpoint
/// the distributor replaces meanwhile is stored, and the app registers it
/// with the server on its next launch.
Future<void> runUnifiedPushInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = LocalNotificationService();
  await notifications.initialize();
  final presenter = PushMessagePresenter(
    show: notifications.showNotification,
    appInFront: () => false,
    website: Uri.parse(defaultApiBaseUrl()),
  );
  await listenToUnifiedPush(
    distributor: UnifiedPushDistributor(
      const PluginUnifiedPushConnector(),
      const SecureSessionStorage(),
    ),
    onMessage: (content) => presentPushContent(content, presenter),
  );
}

/// Takes UnifiedPush events while the app runs, and registers an endpoint
/// the distributor replaced, as the website's service worker does on
/// `pushsubscriptionchange`.
final class PushServiceBinding {
  PushServiceBinding(this._ref);

  final WidgetRef _ref;
  bool _syncing = false;

  Future<void> start() async {
    final distributor = _ref.read(pushDistributorProvider);
    if (distributor == null) return;
    final presenter = PushMessagePresenter(
      show: _ref.read(localNotificationServiceProvider).showNotification,
      appInFront: () =>
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      website: Uri.parse(_ref.read(apiBaseUrlProvider)),
    );
    distributor.onReplaced = () => unawaited(syncReplacedEndpoint());
    await listenToUnifiedPush(
      distributor: distributor,
      onMessage: (content) => presentPushContent(content, presenter),
    );
    await syncReplacedEndpoint();
  }

  /// Registers the endpoint that replaced an older one, once a member is
  /// signed in. Never retried: a failure keeps the record for the next
  /// launch or the next replacement.
  Future<void> syncReplacedEndpoint() async {
    final distributor = _ref.read(pushDistributorProvider);
    final registration = _ref.read(pushRegistrationProvider);
    if (distributor == null || registration == null || _syncing) return;
    if (_ref.read(sessionStateProvider) == null) return;
    final previous = await distributor.replacedEndpoint();
    if (previous == null) return;
    _syncing = true;
    try {
      await registration.replace(previous);
      await distributor.forgetReplacedEndpoint();
    } on Object catch (error) {
      debugPrint('Push endpoint update failed: ${error.runtimeType}');
    } finally {
      _syncing = false;
    }
  }
}
