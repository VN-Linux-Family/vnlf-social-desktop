import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../domain/search_results.dart';
import 'search_results_dto.dart';

final class LiveSearchRepository implements SearchRepository {
  const LiveSearchRepository(this._client);
  final ApiClient _client;

  @override
  Future<SearchResults> search(String query) {
    final keyword = query.trim();
    if (keyword.length < 2) return Future.value(SearchResults());
    return _client.get(
      '/api/v1/search',
      query: {'q': keyword},
      decode: (json) => SearchResultsDto(json).toDomain(),
    );
  }

  @override
  Future<List<SearchTopic>> popularTopics() => _client.get(
    '/api/v1/tags/suggest',
    decode: (json) => objectList(
      json['items'],
      'tags.items',
    ).map(topicFromJson).where((topic) => (topic.count ?? 0) > 0).toList(),
  );
}
