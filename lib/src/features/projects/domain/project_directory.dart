import '../../../domain/models.dart';

const projectTypes = [
  'APP',
  'TOOL',
  'LIBRARY',
  'DISTRO',
  'CUSTOMIZE',
  'EXTENSION',
  'VIETNAMESE',
  'SYSTEM',
  'SELFHOST',
  'GAME',
  'LEARNING',
  'OTHER',
];
const projectSorts = [
  'featured',
  'new',
  'stars',
  'rating',
  'updated',
  'trending',
];

final class ProjectFilters {
  const ProjectFilters({
    this.type = '',
    this.language = '',
    this.seeking = false,
    this.query = '',
    this.sort = 'featured',
  });
  final String type;
  final String language;
  final bool seeking;
  final String query;
  final String sort;

  ProjectFilters copyWith({
    String? type,
    String? language,
    bool? seeking,
    String? query,
    String? sort,
  }) => ProjectFilters(
    type: type ?? this.type,
    language: language ?? this.language,
    seeking: seeking ?? this.seeking,
    query: query ?? this.query,
    sort: sort ?? this.sort,
  );

  Map<String, String> toQuery({String? cursor}) => {
    if (type.isNotEmpty) 'type': type,
    if (language.isNotEmpty) 'language': language,
    if (seeking) 'seeking': '1',
    if (query.isNotEmpty) 'q': query,
    'sort': sort,
    'cursor': ?cursor,
  };
}

final class ProjectFacet {
  const ProjectFacet(this.name, this.count);
  final String name;
  final int count;
}

final class ProjectDirectoryPage {
  ProjectDirectoryPage({
    required this.page,
    required List<ProjectFacet> types,
    required List<ProjectFacet> languages,
  }) : types = List.unmodifiable(types),
       languages = List.unmodifiable(languages);
  final ProjectsPage page;
  final List<ProjectFacet> types;
  final List<ProjectFacet> languages;
}

abstract interface class ProjectDirectoryRepository {
  Future<ProjectDirectoryPage> fetch(
    ProjectFilters filters, {
    String? cursor,
    bool refresh = false,
  });
}
