import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vnlfsocialapp/src/core/api_client.dart';
import 'package:vnlfsocialapp/src/features/feedback/data/live_feedback_repository.dart';

const ticketId = '01a142c4-3482-79ad-be96-ff39844fdfd3';
const clientId = '5b0d87a8-6202-4e78-a713-1f41c6f1bcf2';
const ticketJson = <String, dynamic>{
  'id': ticketId,
  'reference': 'VNLF-44DDFDF3',
  'kind': 'FEEDBACK',
  'status': 'IN_REVIEW',
  'detail': 'Tiếng Việt: ặ ữ ờ ẫ ệ',
  'pagePath': '/feedback',
  'attachmentCount': 1,
  'createdAt': '2026-11-01T02:03:04.000Z',
  'updatedAt': '2026-11-02T02:03:04.000Z',
  'resolvedAt': null,
  'messageCount': 1,
  'staffReplied': true,
};

void main() {
  test(
    'history and member thread use confirmed own-account routes and fields',
    () async {
      final requests = <ApiRequest>[];
      final repository = LiveFeedbackRepository(
        _client((request) async {
          requests.add(request);
          if (request.path.endsWith('/mine')) {
            return _json({
              'items': [
                ticketJson,
                {...ticketJson, 'id': '01a142c4-3482-79ad-be96-ff39844fdfd4'},
              ],
            });
          }
          return _json({
            'ticket': ticketJson,
            'messages': [
              {
                'id': 'message-1',
                'staff': true,
                'mine': false,
                'content': 'Đội VNLF đã nhận.',
                'createdAt': '2026-11-02T08:00:00.000Z',
                'author': null,
              },
              {
                'id': 'message-2',
                'staff': false,
                'mine': true,
                'content': 'Cảm ơn!',
                'createdAt': '2026-11-02T09:00:00.000Z',
                'author': {
                  'id': 'member-1',
                  'username': 'test',
                  'displayName': 'Người thử nghiệm',
                },
              },
            ],
          });
        }),
      );

      final history = await repository.loadMine();
      final thread = await repository.loadThread(ticketId);
      expect(requests.map((r) => r.path), [
        '/api/v1/feedback/mine',
        '/api/v1/feedback/$ticketId/messages',
      ]);
      expect(history.map((ticket) => ticket.reference), [
        'VNLF-44DDFDF3',
        'VNLF-44DDFDF3',
      ]);
      expect(history.first.status.name, 'inReview');
      expect(thread.ticket.staffReplied, isTrue);
      expect(
        thread.messages.first.authorName,
        isNull,
      ); // Member contract redacts staff identity.
      expect(thread.messages.last.authorName, 'Người thử nghiệm');
      expect(thread.messages.last.mine, isTrue);
      expect(() => thread.messages.clear(), throwsUnsupportedError);
    },
  );

  test('message send retains the idempotency key and requires matching member acknowledgment', () async {
    final requests = <ApiRequest>[];
    final repository = LiveFeedbackRepository(
      _client((request) async {
        requests.add(request);
        return _json({
          'id': 'message-1',
          'staff': false,
          'mine': true,
          'content': 'Em đã thử lại.',
          'createdAt': '2026-11-02T09:00:00.000Z',
          'author': null,
        });
      }),
    );

    await repository.sendMessage(
      ticketId: ticketId,
      clientMessageId: clientId,
      content: '  Em đã thử lại.  ',
    );
    await repository.sendMessage(
      ticketId: ticketId,
      clientMessageId: clientId,
      content: 'Em đã thử lại.',
    );
    expect(requests.map((request) => request.method), ['POST', 'POST']);
    expect(
      requests.map((request) => request.path),
      List.filled(2, '/api/v1/feedback/$ticketId/messages'),
    );
    for (final request in requests) {
      expect(jsonDecode(request.body!), {
        'clientMessageId': clientId,
        'content': 'Em đã thử lại.',
      });
    }

    final invalidAck = LiveFeedbackRepository(
      _client(
        (_) async => _json({
          'id': 'message-2',
          'staff': true,
          'mine': false,
          'content': 'not your message',
          'createdAt': '2026-11-02T09:00:00.000Z',
          'author': null,
        }),
      ),
    );
    await expectLater(
      invalidAck.sendMessage(
        ticketId: ticketId,
        clientMessageId: clientId,
        content: 'Em đã thử lại.',
      ),
      throwsA(isA<ParseFailure>()),
    );
  });

  test('POST failure is not automatically retried and malformed inputs never reach transport', () async {
    var calls = 0;
    final repository = LiveFeedbackRepository(
      _client((_) async {
        calls++;
        return ApiResponse(statusCode: 503, body: '{}');
      }),
    );
    await expectLater(
      repository.sendMessage(
        ticketId: ticketId,
        clientMessageId: clientId,
        content: 'A valid message',
      ),
      throwsA(isA<HttpFailure>()),
    );
    expect(calls, 1);
    await expectLater(
      repository.sendMessage(
        ticketId: 'not-an-id',
        clientMessageId: 'short',
        content: ' ',
      ),
      throwsA(isA<ParseFailure>()),
    );
    expect(calls, 1);
  });
}

ApiClient _client(ApiTransport transport) => ApiClient(
  transport: transport,
  throttleInterval: Duration.zero,
  cacheDuration: Duration.zero,
  retryDelay: (_) async {},
);

ApiResponse _json(Map<String, dynamic> value) =>
    ApiResponse(statusCode: 200, body: jsonEncode(value));
