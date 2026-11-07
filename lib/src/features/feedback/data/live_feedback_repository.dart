import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/feedback_models.dart';

final class LiveFeedbackRepository implements FeedbackRepository {
  const LiveFeedbackRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<FeedbackTicket>> loadMine({bool refresh = false}) async {
    final result = await _client.get<Map<String, dynamic>>(
      '/api/v1/feedback/mine',
      refresh: refresh,
      decode: (json) => json,
    );
    return objectList(
      result['items'],
      'feedback.items',
    ).map((item) => _ticket(item, 'feedback.ticket')).toList(growable: false);
  }

  @override
  Future<FeedbackThread> loadThread(
    String ticketId, {
    bool refresh = false,
  }) async {
    final id = _pathId(ticketId);
    final json = await _client.get<Map<String, dynamic>>(
      '/api/v1/feedback/$id/messages',
      refresh: refresh,
      decode: (value) => value,
    );
    final ticket = _ticket(
      objectValue(json['ticket'], 'feedback.ticket') ??
          (throw const ParseFailure('feedback.ticket')),
      'feedback.ticket',
    );
    if (ticket.id != id) throw const ParseFailure('feedback.ticket.id');
    return FeedbackThread(
      ticket: ticket,
      messages: objectList(
        json['messages'],
        'feedback.messages',
      ).map(_message).toList(growable: false),
    );
  }

  @override
  Future<FeedbackMessage> sendMessage({
    required String ticketId,
    required String clientMessageId,
    required String content,
  }) async {
    final id = _pathId(ticketId);
    final clientId = clientMessageId.trim();
    final bodyText = content.trim();
    if (clientId.length < 8 ||
        clientId.length > 100 ||
        bodyText.isEmpty ||
        bodyText.length > 4000) {
      throw const ParseFailure('feedback.message.input');
    }
    final message = await _client.request<FeedbackMessage>(
      'POST',
      '/api/v1/feedback/$id/messages',
      body: jsonEncode({'clientMessageId': clientId, 'content': bodyText}),
      decode: (json) {
        final result = _message(json);
        if (!result.mine || result.staff || result.content != bodyText) {
          throw const ParseFailure('feedback.message.acknowledgement');
        }
        return result;
      },
    );
    return message;
  }
}

FeedbackTicket _ticket(Map<String, dynamic> json, String path) {
  final id = stringValue(json['id'], '$path.id');
  final reference = stringValue(json['reference'], '$path.reference');
  if (id.isEmpty || reference.isEmpty) throw ParseFailure('$path.identity');
  return FeedbackTicket(
    id: id,
    reference: reference,
    kind: switch (stringValue(json['kind'], '$path.kind')) {
      'FEEDBACK' => FeedbackKind.feedback,
      'BUG' => FeedbackKind.bug,
      'OS_SUPPORT' => FeedbackKind.osSupport,
      'DRIVER_SUPPORT' => FeedbackKind.driverSupport,
      _ => throw ParseFailure('$path.kind'),
    },
    status: switch (stringValue(json['status'], '$path.status')) {
      'OPEN' => FeedbackStatus.open,
      'IN_REVIEW' => FeedbackStatus.inReview,
      'RESOLVED' => FeedbackStatus.resolved,
      'CLOSED' => FeedbackStatus.closed,
      'DEFERRED' => FeedbackStatus.deferred,
      _ => throw ParseFailure('$path.status'),
    },
    detail: stringValue(json['detail'], '$path.detail'),
    pagePath: stringValue(json['pagePath'], '$path.pagePath'),
    attachmentCount: intValue(json['attachmentCount'], '$path.attachmentCount'),
    createdAt: _date(json['createdAt'], '$path.createdAt'),
    updatedAt: _date(json['updatedAt'], '$path.updatedAt'),
    resolvedAt: json['resolvedAt'] == null
        ? null
        : _date(json['resolvedAt'], '$path.resolvedAt'),
    messageCount: intValue(json['messageCount'], '$path.messageCount'),
    staffReplied: _requiredBool(json['staffReplied'], '$path.staffReplied'),
  );
}

FeedbackMessage _message(Map<String, dynamic> json) {
  final id = stringValue(json['id'], 'feedback.message.id');
  final content = stringValue(json['content'], 'feedback.message.content');
  if (id.isEmpty || content.isEmpty) {
    throw const ParseFailure('feedback.message');
  }
  final author = objectValue(json['author'], 'feedback.message.author');
  final authorName = author == null
      ? null
      : stringValue(
          author['displayName'],
          'feedback.message.author.displayName',
        );
  return FeedbackMessage(
    id: id,
    staff: _requiredBool(json['staff'], 'feedback.message.staff'),
    mine: _requiredBool(json['mine'], 'feedback.message.mine'),
    content: content,
    createdAt: _date(json['createdAt'], 'feedback.message.createdAt'),
    authorName: authorName,
  );
}

DateTime _date(Object? value, String path) {
  final text = stringValue(value, path);
  final date = DateTime.tryParse(text);
  if (date == null) throw ParseFailure(path);
  return date.toUtc();
}

String _pathId(String value) {
  final id = value.trim();
  if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id)) {
    throw const ParseFailure('feedback.id');
  }
  return Uri.encodeComponent(id);
}

bool _requiredBool(Object? value, String path) {
  if (value is! bool) throw ParseFailure(path);
  return value;
}
