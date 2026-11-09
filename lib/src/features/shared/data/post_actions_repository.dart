import 'dart:convert';

import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/post_actions.dart';

/// Article writes the website makes from a post and its "…" menu.
/// None of them is retried automatically.
final class LivePostActionsRepository implements PostActionsRepository {
  LivePostActionsRepository(this._client, {required this.hasSession});
  final ApiClient _client;
  final bool Function() hasSession;

  String _article(String id) => '/api/v1/articles/${Uri.encodeComponent(id)}';

  void _requireSession() {
    if (!hasSession()) throw const HttpFailure(401);
  }

  @override
  Future<int> setVote(String id, int value) async {
    _requireSession();
    return _client.request(
      'PUT',
      '${_article(id)}/vote',
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

  /// `POST` only adds a bookmark and `DELETE` removes it.
  @override
  Future<void> setBookmark(String id, {required bool saved}) async {
    _requireSession();
    return _client.request<void>(
      saved ? 'POST' : 'DELETE',
      '${_article(id)}/bookmark',
    );
  }

  /// `DELETE /api/v1/articles/:id` marks the owner's article as removed.
  @override
  Future<void> deletePost(String id) async {
    _requireSession();
    return _client.request<void>('DELETE', _article(id));
  }

  /// `POST /api/v1/articles/:id/hide` hides a published article for the viewer.
  @override
  Future<void> hidePost(String id) async {
    _requireSession();
    return _client.request<void>('POST', '${_article(id)}/hide');
  }
}

final class FixturePostActionsRepository implements PostActionsRepository {
  @override
  Future<int> setVote(String id, int value) async => value;
  @override
  Future<void> setBookmark(String id, {required bool saved}) async {}
  @override
  Future<void> deletePost(String id) async {}
  @override
  Future<void> hidePost(String id) async {}
}
