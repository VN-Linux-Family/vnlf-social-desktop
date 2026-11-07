import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/realtime/domain/community_event.dart';

void main() {
  test('raw JSON acknowledgments remain separate from event envelopes', () {
    final ack = CommunityFrame.decode(
      jsonEncode({
        'ok': true,
        'requestId': 'request-one',
        'data': {'value': 1},
      }),
    ) as CommunityAck;
    expect(ack.ok, isTrue);
    expect(ack.requestId, 'request-one');
    expect(ack.data, {'value': 1});
    final event = CommunityFrame.decode(jsonEncode(_event)) as CommunityEvent;
    expect(event.type, 'dm:message-created');
    expect(event.eventId, 'event-one');
    expect(event.occurredAt, DateTime.utc(2026, 11, 6));
  });
  test(
    'negative acknowledgments expose a code without retaining error bodies',
    () {
      final ack = CommunityFrame.decode(
        jsonEncode({
          'ok': false,
          'requestId': 'request-one',
          'error': {
            'code': 'CONVERSATION_FORBIDDEN',
            'message': 'Synthetic description',
            'retryable': false,
          },
        }),
      ) as CommunityAck;
      expect(ack.errorCode, 'CONVERSATION_FORBIDDEN');
      expect(ack.retryable, isFalse);
    },
  );
  test(
    'unknown future events and fields are tolerated and payloads are immutable',
    () {
      final event = CommunityFrame.decode(
        utf8.encode(
          jsonEncode({..._event, 'type': 'future:event', 'extra': true}),
        ),
      ) as CommunityEvent;
      expect(event.type, 'future:event');
      final data = event.data as Map;
      expect(() => data['id'] = 'changed', throwsUnsupportedError);
      expect(
        () => ((data['nested'] as List).first as Map)['value'] = 2,
        throwsUnsupportedError,
      );
      final mutable = <String, Object?>{'value': 1};
      final direct = CommunityEvent(
        type: 'future:event',
        eventId: 'direct',
        occurredAt: DateTime.utc(2026),
        data: mutable,
      );
      mutable['value'] = 2;
      expect((direct.data as Map)['value'], 1);
    },
  );
  test('malformed frames report typed fields without echoing content', () {
    for (final value in <Object>[
      'not-json',
      '[]',
      42,
      jsonEncode({'ok': 'true', 'requestId': 'one'}),
      jsonEncode({'ok': true, 'requestId': ''}),
      jsonEncode({'ok': false, 'requestId': 'one'}),
      jsonEncode({..._event, 'eventId': null}),
      jsonEncode({..._event, 'occurredAt': 'bad-date'}),
      jsonEncode({..._event}..remove('data')),
    ]) {
      expect(() => CommunityFrame.decode(value), throwsA(isA<ParseFailure>()));
    }
  });
}

const _event = <String, Object?>{
  'type': 'dm:message-created',
  'eventId': 'event-one',
  'occurredAt': '2026-11-06T00:00:00Z',
  'data': {
    'id': 'synthetic-message',
    'nested': [
      {'value': 1},
    ],
  },
};
