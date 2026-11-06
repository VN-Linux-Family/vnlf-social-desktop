import '../../../core/api_client.dart';
import '../../../data/field_reader.dart';
import '../../../data/projects_dto.dart';
import '../domain/project_directory.dart';

final class ApiProjectDirectoryRepository implements ProjectDirectoryRepository {
  const ApiProjectDirectoryRepository(this.client);
  final ApiClient client;

  @override
  Future<ProjectDirectoryPage> fetch(ProjectFilters filters, {String? cursor, bool refresh = false}) => client.get(
    '/api/v1/projects',
    query: filters.toQuery(cursor: cursor),
    refresh: refresh,
    decode: (json) {
      final page = ProjectsPageDto.fromJson(json).toDomain();
      final next = page.nextCursor;
      if (next != null && (next.isEmpty || next.length > 12)) throw const ParseFailure('nextCursor');
      final facets = objectValue(json['facets'], 'facets');
      List<ProjectFacet> read(String key, String name) => objectList(facets?[key], 'facets.$key').map((row) => ProjectFacet(stringValue(row[name], 'facets.$key.$name'), intValue(row['count'], 'facets.$key.count'))).toList();
      return ProjectDirectoryPage(page: page, types: read('types', 'type'), languages: read('languages', 'name'));
    },
  );
}
