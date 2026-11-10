import 'dart:async';
import 'dart:convert';

import '../../../core/session_storage_contract.dart';
import '../domain/push_distributor.dart';
import '../domain/push_subscriptions_repository.dart';

/// The UnifiedPush calls the app makes, behind a seam so tests need no
/// distributor.
abstract interface class UnifiedPushConnector {
  /// Uses the distributor picked before, or the system's default one; false
  /// when no distributor app is installed.
  Future<bool> useDefaultDistributor();

  /// Asks the distributor for an endpoint for the server's VAPID key. The
  /// answer comes later, through [UnifiedPushDistributor.endpointChanged] or
  /// [UnifiedPushDistributor.registrationFailed].
  Future<void> register({required String vapid});

  Future<void> unregister();
}

/// A distributor's endpoint with the keys the server encrypts for
/// (`PushEndpoint` and its `pubKeySet`).
typedef UnifiedPushEndpoint = ({String url, String? p256dh, String? auth});

/// The UnifiedPush distributor on this device (for example ntfy) as the
/// app's [PushDistributor]. The distributor app makes the endpoint, and the
/// connector decrypts what arrives there (RFC 8291), so the server's Web
/// Push messages work unchanged once it accepts the endpoint.
///
/// The subscription is kept in secure storage with the VAPID key it was
/// made for, because its `auth` secret is what the server encrypts with.
final class UnifiedPushDistributor implements PushDistributor {
  UnifiedPushDistributor(
    this._connector,
    this._storage, {
    this.answerTimeout = const Duration(seconds: 30),
  });

  static const storageKey = 'vnlf_unifiedpush_subscription';

  /// The endpoint the distributor replaced while nothing was waiting for an
  /// answer, kept until the app registers the new one with the server.
  static const replacedKey = 'vnlf_unifiedpush_replaced';

  final UnifiedPushConnector _connector;
  final SessionStorage _storage;
  final Duration answerTimeout;

  Completer<WebPushSubscription>? _pending;
  String? _pendingKey;

  /// Called when the distributor replaced the endpoint while nothing was
  /// waiting for one, so the app can register the new endpoint.
  void Function()? onReplaced;

  @override
  Future<HeldPushSubscription?> current() async {
    final raw = await _storage.read(storageKey);
    if (raw == null) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      await _storage.delete(storageKey);
      return null;
    }
    if (json is! Map<String, dynamic> ||
        json['endpoint'] is! String ||
        json['p256dh'] is! String ||
        json['auth'] is! String ||
        json['serverKey'] is! String) {
      await _storage.delete(storageKey);
      return null;
    }
    return (
      subscription: WebPushSubscription(
        endpoint: json['endpoint'] as String,
        p256dh: json['p256dh'] as String,
        auth: json['auth'] as String,
      ),
      serverKey: json['serverKey'] as String,
    );
  }

  @override
  Future<WebPushSubscription> subscribe(String serverKey) async {
    if (!await _connector.useDefaultDistributor()) {
      throw const PushDistributorUnavailable();
    }
    final pending = _pending = Completer<WebPushSubscription>();
    _pendingKey = serverKey;
    try {
      await _connector.register(vapid: serverKey);
      return await pending.future.timeout(
        answerTimeout,
        onTimeout: () => throw const PushDistributorUnavailable(),
      );
    } finally {
      if (identical(_pending, pending)) {
        _pending = null;
        _pendingKey = null;
      }
    }
  }

  @override
  Future<void> unsubscribe() async {
    await _connector.unregister();
    await _storage.delete(storageKey);
    await _storage.delete(replacedKey);
  }

  /// `onNewEndpoint`: answers a pending [subscribe], or records that the
  /// distributor replaced the endpoint, as a browser's
  /// `pushsubscriptionchange`.
  Future<void> endpointChanged(UnifiedPushEndpoint endpoint) async {
    final pending = _pending;
    final p256dh = endpoint.p256dh;
    final auth = endpoint.auth;
    if (p256dh == null || auth == null) {
      // Without keys the server cannot encrypt for this endpoint.
      if (pending != null && !pending.isCompleted) {
        pending.completeError(const PushDistributorUnavailable());
      }
      return;
    }
    final held = await current();
    final serverKey = _pendingKey ?? held?.serverKey;
    if (serverKey == null) return;
    final subscription = WebPushSubscription(
      endpoint: endpoint.url,
      p256dh: p256dh,
      auth: auth,
    );
    await _storage.write(
      storageKey,
      jsonEncode({
        'endpoint': subscription.endpoint,
        'p256dh': subscription.p256dh,
        'auth': subscription.auth,
        'serverKey': serverKey,
      }),
    );
    if (pending != null && !pending.isCompleted) {
      pending.complete(subscription);
    } else if (held != null && held.subscription.endpoint != endpoint.url) {
      // Keep the first endpoint that was registered with the server.
      if (await _storage.read(replacedKey) == null) {
        await _storage.write(replacedKey, held.subscription.endpoint);
      }
      onReplaced?.call();
    }
  }

  /// `onRegistrationFailed`.
  void registrationFailed(String reason) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(PushRegistrationRefused(reason));
    }
  }

  /// `onUnregistered`: the distributor dropped the app, for example because
  /// it was uninstalled.
  Future<void> unregistered() async {
    await _storage.delete(storageKey);
    await _storage.delete(replacedKey);
  }

  /// The endpoint the server still has after the distributor replaced it,
  /// or null.
  Future<String?> replacedEndpoint() => _storage.read(replacedKey);

  Future<void> forgetReplacedEndpoint() => _storage.delete(replacedKey);
}
