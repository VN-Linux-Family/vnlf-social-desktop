import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/post_actions.dart';

final class LivePostActionsRepository implements PostActionsRepository {
  LivePostActionsRepository(this._client, {required this.hasSession});
  final ApiClient _client;
  final bool Function() hasSession;

  @override
  Future<int> setVote(String id, int value) {
    if (!hasSession()) throw const HttpFailure(401);
    return _client.request(
      'PUT',
      '/api/v1/articles/${Uri.encodeComponent(id)}/vote',
      body: jsonEncode({'value': value}),
      decode: (json) {
        final vote = intValue(json['viewerVote'], 'vote.viewerVote');
        if (!{-1, 0, 1}.contains(vote)) {
          throw const ParseFailure('vote.viewerVote');
        }
        return vote;
      },
    );
  }

  @override
  Future<void> toggleBookmark(String id) {
    if (!hasSession()) throw const HttpFailure(401);
    return _client.request<void>(
      'POST',
      '/api/v1/articles/${Uri.encodeComponent(id)}/bookmark',
    );
  }
}

final class FixturePostActionsRepository implements PostActionsRepository {
  @override
  Future<int> setVote(String id, int value) async => value;
  @override
  Future<void> toggleBookmark(String id) async {}
}
