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

  /// The filters in a `/projects?…` address, kept only when the website
  /// would keep them (`readProjectFilters` in lib/projects.ts).
  factory ProjectFilters.fromQuery(Map<String, String> query) {
    String cut(String? value, int max) {
      final text = value ?? '';
      return text.length > max ? text.substring(0, max) : text;
    }

    final type = query['type'] ?? '';
    final sort = query['sort'] ?? '';
    return ProjectFilters(
      type: projectTypes.contains(type) ? type : '',
      language: cut(query['language'], 60),
      seeking: query['seeking'] == '1',
      query: cut(query['q'], 80),
      sort: projectSorts.contains(sort) ? sort : 'featured',
    );
  }

  /// Whether anything but the order narrows the list.
  bool get filtered =>
      type.isNotEmpty || language.isNotEmpty || seeking || query.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ProjectFilters &&
      other.type == type &&
      other.language == language &&
      other.seeking == seeking &&
      other.query == query &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(type, language, seeking, query, sort);

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

/// Runs of projects of the same tier, in the server's order (VNLF, partners,
/// members), as the website's `groupByTier`.
List<List<ProjectItem>> groupByTier(List<ProjectItem> items) {
  final groups = <List<ProjectItem>>[];
  for (final item in items) {
    if (groups.isEmpty || groups.last.first.tier != item.tier) {
      groups.add([item]);
    } else {
      groups.last.add(item);
    }
  }
  return groups;
}
