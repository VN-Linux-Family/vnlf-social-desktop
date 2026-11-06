import 'dart:async';

import '../../../core/request_identity.dart';
import '../../../domain/models.dart';
import '../domain/community_event.dart';

final class PendingCommunityRequest {
  PendingCommunityRequest(this.id, this.future);
  final String id;
  final Future<CommunityAck> future;
}

/// Correlation only: expired or disconnected requests are never resent.
final class CommunityRequests {
  CommunityRequests(this.timeout);
  final Duration timeout;
  final _pending = <String, (Completer<CommunityAck>, Timer)>{};

  PendingCommunityRequest register() {
    if (_pending.length >= 32) throw const TransportFailure();
    final id = newRequestIdentity();
    final result = Completer<CommunityAck>();
    final timer = Timer(timeout, () => fail(id, const TransportFailure()));
    _pending[id] = (result, timer);
    return PendingCommunityRequest(id, result.future);
  }

  void complete(CommunityAck ack) {
    final entry = _pending.remove(ack.requestId);
    if (entry == null) return;
    entry.$2.cancel();
    if (ack.ok) {
      entry.$1.complete(ack);
    } else {
      final code = ack.errorCode;
      final status = switch (code) {
        'AUTH_REQUIRED' || 'SESSION_REVOKED' => 401,
        'CHANNEL_FORBIDDEN' || 'CONVERSATION_FORBIDDEN' => 403,
        'RATE_LIMITED' => 429,
        _ => 400,
      };
      entry.$1.completeError(HttpFailure(status, code: code));
    }
  }

  void fail(String id, AppFailure failure) {
    final entry = _pending.remove(id);
    if (entry == null) return;
    entry.$2.cancel();
    entry.$1.completeError(failure);
  }

  void failAll(AppFailure failure) {
    final entries = _pending.values.toList();
    _pending.clear();
    for (final entry in entries) {
      entry.$2.cancel();
      entry.$1.completeError(failure);
    }
  }
}
