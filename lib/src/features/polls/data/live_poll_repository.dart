import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/poll_models.dart';
import '../domain/poll_repository.dart';
import 'poll_dto.dart';

final class LivePollRepository implements PollRepository {
  const LivePollRepository(this._client);
  final ApiClient _client;

  @override
  Future<Poll> vote(String pollId, String? optionId) {
    final id = _uuid(pollId);
    if (optionId != null) _uuid(optionId);
    return _client.request(
      'POST',
      '/api/v1/polls/$id/vote',
      body: jsonEncode({'optionId': optionId}),
      decode: (json) {
        final poll = PollDto(json).acknowledged();
        if (poll.id != id || poll.viewerOptionId != optionId) {
          throw const ParseFailure('poll.vote.acknowledgment');
        }
        return poll;
      },
    );
  }

  @override
  Future<Poll> edit(String pollId, PollInput input) {
    final id = _uuid(pollId);
    return _client.request(
      'PUT',
      '/api/v1/polls/$id',
      body: jsonEncode(_body(input)),
      decode: (json) {
        final poll = PollDto(json).acknowledged();
        if (poll.id != id || !_matches(poll, input)) {
          throw const ParseFailure('poll.edit.acknowledgment');
        }
        return poll;
      },
    );
  }

  @override
  Future<Poll?> setDraftPoll(String articleId, PollInput? input) {
    final id = _uuid(articleId);
    return _client.request(
      'PUT',
      '/api/v1/articles/$id/poll',
      body: jsonEncode({'poll': input == null ? null : _body(input)}),
      decode: (json) {
        if (!json.containsKey('poll')) {
          throw const ParseFailure('poll.draft.acknowledgment');
        }
        final raw = objectValue(json['poll'], 'poll');
        if (input == null) {
          if (raw != null) {
            throw const ParseFailure('poll.draft.acknowledgment');
          }
          return null;
        }
        if (raw == null) throw const ParseFailure('poll.draft.acknowledgment');
        final poll = PollDto(raw).acknowledged();
        if (!_matches(poll, input)) {
          throw const ParseFailure('poll.draft.acknowledgment');
        }
        return poll;
      },
    );
  }
}

Map<String, Object> _body(PollInput input) => {
  'question': input.question,
  'options': input.options,
};
bool _matches(Poll poll, PollInput input) =>
    poll.question == input.question &&
    poll.options.length == input.options.length &&
    Iterable<int>.generate(input.options.length)
        .every((i) => poll.options[i].label == input.options[i]);
final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
String _uuid(String value) {
  if (!_uuidPattern.hasMatch(value)) throw const ParseFailure('poll.id');
  return value;
}
