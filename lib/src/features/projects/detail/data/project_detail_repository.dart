import '../../../../core/api_client.dart';
import '../../../../data/field_reader.dart';
import '../domain/project_detail.dart';

final class ApiProjectDetailRepository implements ProjectDetailRepository {
  const ApiProjectDetailRepository(this.client);
  final ApiClient client;
  @override
  Future<ProjectDetail> fetch(String slug, {bool refresh = false}) {
    if (slug.isEmpty || slug.length > 80) throw const ParseFailure('slug');
    return client.get(
      '/api/v1/projects/${Uri.encodeComponent(slug)}',
      refresh: refresh,
      decode: (json) => ProjectDetailDto(json).toDomain(),
    );
  }
}

final class ProjectDetailDto {
  const ProjectDetailDto(this.json);
  final Map<String, dynamic> json;
  ProjectDetail toDomain() {
    final owner =
        objectValue(json['owner'], 'owner') ?? const <String, dynamic>{};
    final rating =
        objectValue(json['rating'], 'rating') ?? const <String, dynamic>{};
    final average = rating['average'];
    if (average != null && average is! num) {
      throw const ParseFailure('rating.average');
    }
    final distribution = json['ratingDistribution'];
    if (distribution != null &&
        (distribution is! List || distribution.any((v) => v is! int))) {
      throw const ParseFailure('ratingDistribution');
    }
    final repo = objectValue(json['repo'], 'repo');
    final review = objectValue(json['review'], 'review');
    final discussion = objectValue(json['discussion'], 'discussion');
    return ProjectDetail(
      id: stringValue(json['id'], 'id'),
      slug: stringValue(json['slug'], 'slug'),
      name: stringValue(json['name'], 'name'),
      tagline: stringValue(json['tagline'], 'tagline'),
      intro: stringValue(json['intro'], 'intro'),
      type: stringValue(json['type'], 'type'),
      tier: stringValue(json['tier'], 'tier'),
      relation: stringValue(json['relation'], 'relation'),
      status: stringValue(json['status'], 'status'),
      ownerName: stringValue(owner['displayName'], 'owner.displayName'),
      ownerUsername: stringValue(owner['username'], 'owner.username'),
      logoUrl: nullableString(json['logoUrl'], 'logoUrl'),
      seeking: boolValue(json['seeking'], 'seeking'),
      seekingNote: stringValue(json['seekingNote'], 'seekingNote'),
      links: List.unmodifiable(
        objectList(json['links'], 'links').map(
          (v) => ProjectDetailLink(
            stringValue(v['kind'], 'links.kind'),
            stringValue(v['url'], 'links.url'),
          ),
        ),
      ),
      media: List.unmodifiable(
        objectList(json['media'], 'media').map(
          (v) => ProjectDetailMedia(
            stringValue(v['url'], 'media.url'),
            stringValue(v['fullUrl'], 'media.fullUrl'),
            nullableInt(v['width'], 'media.width'),
            nullableInt(v['height'], 'media.height'),
          ),
        ),
      ),
      rating: ProjectDetailRating(
        (average as num?)?.toDouble(),
        intValue(rating['count'], 'rating.count'),
      ),
      myRating: nullableInt(json['myRating'], 'myRating'),
      ratingDistribution: List<int>.unmodifiable(
        (distribution as List?)?.cast<int>() ?? const [],
      ),
      canRate: boolValue(json['canRate'], 'canRate'),
      repo: repo == null ? null : _repo(repo),
      discussionSlug: nullableString(discussion?['slug'], 'discussion.slug'),
      reviewNote: nullableString(review?['note'], 'review.note'),
      hasPendingChanges: objectValue(json['changes'], 'changes') != null,
    );
  }

  ProjectDetailRepo _repo(Map<String, dynamic> v) {
    final license = objectValue(v['license'], 'repo.license');
    final release = objectValue(v['latestRelease'], 'repo.latestRelease');
    return ProjectDetailRepo(
      owner: stringValue(v['owner'], 'repo.owner'),
      name: stringValue(v['name'], 'repo.name'),
      url: stringValue(v['url'], 'repo.url'),
      homepage: nullableString(v['homepage'], 'repo.homepage'),
      stars: nullableInt(v['stars'], 'repo.stars'),
      forks: nullableInt(v['forks'], 'repo.forks'),
      contributors: nullableInt(v['contributors'], 'repo.contributors'),
      openIssues: nullableInt(v['openIssues'], 'repo.openIssues'),
      openPrs: nullableInt(v['openPrs'], 'repo.openPrs'),
      languages: List.unmodifiable(
        objectList(
          v['languages'],
          'repo.languages',
        ).map((x) => stringValue(x['name'], 'repo.languages.name')),
      ),
      license:
          nullableString(license?['spdx'], 'repo.license.spdx') ??
          nullableString(license?['name'], 'repo.license.name'),
      topics: stringList(v['topics'], 'repo.topics'),
      releaseTag: nullableString(release?['tag'], 'repo.latestRelease.tag'),
      releaseUrl: nullableString(release?['url'], 'repo.latestRelease.url'),
      unavailable: boolValue(v['unavailable'], 'repo.unavailable'),
    );
  }
}
