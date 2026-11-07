import 'package:flutter/foundation.dart';

@immutable
class PushConfig {
  const PushConfig({required this.enabled, this.publicKey});

  final bool enabled;
  final String? publicKey;

  factory PushConfig.fromJson(Map<String, dynamic> json) {
    return PushConfig(
      enabled: json['enabled'] == true,
      publicKey: json['publicKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'enabled': enabled, 'publicKey': publicKey};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          publicKey == other.publicKey;

  @override
  int get hashCode => Object.hash(enabled, publicKey);
}

@immutable
class PushSubscriptionPayload {
  const PushSubscriptionPayload({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  final String endpoint;
  final String p256dh;
  final String auth;

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'keys': {'p256dh': p256dh, 'auth': auth},
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushSubscriptionPayload &&
          runtimeType == other.runtimeType &&
          endpoint == other.endpoint &&
          p256dh == other.p256dh &&
          auth == other.auth;

  @override
  int get hashCode => Object.hash(endpoint, p256dh, auth);
}

enum PushRegistrationPhase { idle, checking, registered, disabled, failed }

@immutable
class PushRegistrationState {
  const PushRegistrationState({
    this.phase = PushRegistrationPhase.idle,
    this.endpoint,
    this.errorMessage,
  });

  final PushRegistrationPhase phase;
  final String? endpoint;
  final String? errorMessage;

  bool get isRegistered => phase == PushRegistrationPhase.registered;

  PushRegistrationState copyWith({
    PushRegistrationPhase? phase,
    String? endpoint,
    String? errorMessage,
  }) => PushRegistrationState(
    phase: phase ?? this.phase,
    endpoint: endpoint ?? this.endpoint,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
