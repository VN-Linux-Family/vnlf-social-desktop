import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';

final class MentionCandidate {
  const MentionCandidate({required this.id, required this.username, required this.displayName, this.avatarUrl, this.style});
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final Map<String, dynamic>? style;
}

abstract interface class MentionCandidatesRepository {
  Future<List<MentionCandidate>> search(String articleId, String query);
}

final class ApiMentionCandidatesRepository implements MentionCandidatesRepository {
  ApiMentionCandidatesRepository(this.client);
  final ApiClient client;

  @override
  Future<List<MentionCandidate>> search(String articleId, String query) => client.get(
    '/api/v1/articles/${Uri.encodeComponent(articleId)}/mention-candidates',
    query: {'q': query},
    refresh: true,
    decode: (json) => List.unmodifiable(objectList(json['items'], 'mentions.items').take(8).map((item) {
      final id = stringValue(item['id'], 'mention.id');
      final username = stringValue(item['username'], 'mention.username');
      if (id.isEmpty || username.isEmpty) throw const ParseFailure('mention.identity');
      final style = objectValue(item['style'], 'mention.style');
      return MentionCandidate(
        id: id,
        username: username,
        displayName: stringValue(item['displayName'], 'mention.displayName'),
        avatarUrl: nullableString(item['avatarUrl'], 'mention.avatarUrl'),
        style: style == null ? null : Map.unmodifiable(style),
      );
    })),
  );
}
