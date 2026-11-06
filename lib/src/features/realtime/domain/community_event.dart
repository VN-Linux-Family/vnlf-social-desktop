import 'dart:convert';

import '../../../domain/models.dart';

sealed class CommunityFrame {
  const CommunityFrame();
  static CommunityFrame decode(Object? raw) {
    try {
      final String text;
      if (raw is String && raw.length <= 1024 * 1024) {
        text = raw;
      } else if (raw is List<int> && raw.length <= 1024 * 1024) {
        text = utf8.decode(raw);
      } else {
        throw const ParseFailure('realtime.frame');
      }
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) {
        throw const ParseFailure('realtime.frame');
      }
      if (json.containsKey('ok')) {
        final ok = json['ok'];
        final requestId = _requiredString(json['requestId']);
        if (ok is! bool) throw const ParseFailure('realtime.ack');
        final error = json['error'];
        String? code;
        var retryable = false;
        if (!ok) {
          if (error is! Map<String, dynamic>) {
            throw const ParseFailure('realtime.ack');
          }
          code = _requiredString(error['code']);
          if (error.containsKey('retryable') && error['retryable'] is! bool) {
            throw const ParseFailure('realtime.ack');
          }
          retryable = error['retryable'] == true;
        }
        return CommunityAck(
          requestId: requestId,
          ok: ok,
          data: json['data'],
          errorCode: code,
          retryable: retryable,
        );
      }
      final type = _requiredString(json['type']);
      final eventId = _requiredString(json['eventId']);
      final timestamp = DateTime.tryParse(_requiredString(json['occurredAt']));
      if (timestamp == null || !json.containsKey('data')) {
        throw const ParseFailure('realtime.event');
      }
      return CommunityEvent(
        type: type,
        eventId: eventId,
        occurredAt: timestamp,
        data: json['data'],
      );
    } catch (_) {
      // A parse failure never includes untrusted message or account content.
      throw const ParseFailure('realtime.frame');
    }
  }
}

final class CommunityAck extends CommunityFrame {
  CommunityAck({
    required this.requestId,
    required this.ok,
    Object? data,
    this.errorCode,
    this.retryable = false,
  }) : data = _freeze(data);
  final String requestId;
  final bool ok;
  final Object? data;
  final String? errorCode;
  final bool retryable;
}

final class CommunityEvent extends CommunityFrame {
  CommunityEvent({
    required this.type,
    required this.eventId,
    required this.occurredAt,
    required Object? data,
  }) : data = _freeze(data);
  final String type;
  final String eventId;
  final DateTime occurredAt;
  final Object? data;
}

String _requiredString(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const ParseFailure('realtime.frame');
  }
  return value;
}

Object? _freeze(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.unmodifiable(
      value.map((key, item) => MapEntry(key, _freeze(item))),
    );
  }
  if (value is List) return List<Object?>.unmodifiable(value.map(_freeze));
  return value;
}
