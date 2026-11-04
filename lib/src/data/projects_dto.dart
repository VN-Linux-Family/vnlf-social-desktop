import '../domain/models.dart';
import 'field_reader.dart';
import 'profile_dto.dart';

final class ProjectItemDto {
  ProjectItemDto._(this._json);
  factory ProjectItemDto.fromJson(Map<String, dynamic> json) {
    final dto = ProjectItemDto._(objectValue(json, 'item')!);
    dto.toDomain();
    return dto;
  }
  final Map<String, dynamic> _json;
  ProjectItem toDomain() {
    final owner = objectValue(_json['owner'], 'owner');
    return ProjectItem(
      id: stringValue(_json['id'], 'id'),
      name: stringValue(_json['name'], 'name'),
      slug: stringValue(_json['slug'], 'slug'),
      tagline: stringValue(_json['tagline'], 'tagline'),
      type: stringValue(_json['type'], 'type'),
      tier: stringValue(_json['tier'], 'tier'),
      relation: stringValue(_json['relation'], 'relation'),
      seeking: boolValue(_json['seeking'], 'seeking'),
      featured: boolValue(_json['featured'], 'featured'),
      status: stringValue(_json['status'], 'status'),
      logoUrl: nullableString(_json['logoUrl'], 'logoUrl'),
      accentColor: nullableString(_json['accentColor'], 'accentColor'),
      owner: owner == null ? null : ProfileDto.fromJson(owner).toDomain(),
      repo: objectValue(_json['repo'], 'repo'),
      rating: objectValue(_json['rating'], 'rating'),
      commentCount: intValue(_json['commentCount'], 'commentCount'),
      approvedAt: dateValue(_json['approvedAt'], 'approvedAt'),
    );
  }
}

final class ProjectsPageDto {
  ProjectsPageDto.fromJson(Map<String, dynamic> json)
    : items = objectList(
        json['items'],
        'items',
      ).map(ProjectItemDto.fromJson).toList(growable: false),
      nextCursor = nullableString(json['nextCursor'], 'nextCursor');
  final List<ProjectItemDto> items;
  final String? nextCursor;
  ProjectsPage toDomain() => ProjectsPage(
    items: items.map((item) => item.toDomain()).toList(),
    nextCursor: nextCursor,
  );
}
