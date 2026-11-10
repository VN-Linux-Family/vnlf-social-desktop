import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../../../data/profile_dto.dart';
import '../domain/people.dart';

/// `GET /api/v1/users/{username}/followers|following[?cursor=]`, as the
/// website's `PeopleDialog` (`people-lists.tsx`) reads them.
final class LivePeopleRepository implements PeopleRepository {
  const LivePeopleRepository(this._client);
  final ApiClient _client;

  @override
  Future<PeoplePage> list(String username, PeopleTab tab, {String? cursor}) =>
      _client.get(
        '/api/v1/users/${Uri.encodeComponent(username)}/${tab.name}',
        query: {'cursor': ?cursor},
        refresh: true,
        decode: (json) {
          final items = json['items'];
          if (items is! List) throw const ParseFailure('people.items');
          return PeoplePage(
            items: [
              for (final item in items)
                if (objectValue(item, 'people.item') case final row?)
                  PersonRow(
                    author: ProfileDto.fromJson(row).toDomain(),
                    followedByViewer: row['followedByViewer'] == true,
                    isViewer: row['isViewer'] == true,
                  ),
            ],
            nextCursor: nullableString(json['nextCursor'], 'people.nextCursor'),
          );
        },
      );
}
