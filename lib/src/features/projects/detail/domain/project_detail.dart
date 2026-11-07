import '../../../../domain/models.dart';

abstract interface class ProjectDetailRepository {
  Future<ProjectDetail> fetch(String slug, {bool refresh = false});
}

final class ProjectDetail {
  const ProjectDetail({
    required this.id,
    required this.slug,
    required this.name,
    required this.tagline,
    required this.intro,
    required this.type,
    required this.tier,
    required this.relation,
    required this.status,
    required this.ownerName,
    required this.ownerUsername,
    required this.logoUrl,
    required this.seeking,
    required this.seekingNote,
    required this.links,
    required this.media,
    required this.rating,
    required this.myRating,
    required this.ratingDistribution,
    required this.canRate,
    required this.repo,
    required this.discussionSlug,
    required this.reviewNote,
    required this.hasPendingChanges,
  });
  final String id, slug, name, tagline, intro, type, tier, relation, status;
  final String ownerName, ownerUsername;
  final String? logoUrl;
  final bool seeking;
  final String seekingNote;
  final List<ProjectDetailLink> links;
  final List<ProjectDetailMedia> media;
  final ProjectDetailRating rating;
  final int? myRating;
  final List<int> ratingDistribution;
  final bool canRate;
  final ProjectDetailRepo? repo;
  final String? discussionSlug, reviewNote;
  final bool hasPendingChanges;
}

final class ProjectDetailLink {
  const ProjectDetailLink(this.kind, this.url);
  final String kind, url;
}

final class ProjectDetailMedia {
  const ProjectDetailMedia(this.url, this.fullUrl, this.width, this.height);
  final String url, fullUrl;
  final int? width, height;
}

final class ProjectDetailRating {
  const ProjectDetailRating(this.average, this.count);
  final double? average;
  final int count;
}

final class ProjectDetailRepo {
  const ProjectDetailRepo({
    required this.owner,
    required this.name,
    required this.url,
    required this.homepage,
    required this.stars,
    required this.forks,
    required this.contributors,
    required this.openIssues,
    required this.openPrs,
    required this.languages,
    required this.license,
    required this.topics,
    required this.releaseTag,
    required this.releaseUrl,
    required this.unavailable,
  });
  final String owner, name, url;
  final String? homepage, license, releaseTag, releaseUrl;
  final int? stars, forks, contributors, openIssues, openPrs;
  final List<String> languages, topics;
  final bool unavailable;
}

sealed class ProjectDetailState {
  const ProjectDetailState();
}

final class ProjectDetailLoading extends ProjectDetailState {
  const ProjectDetailLoading();
}

final class ProjectDetailLoaded extends ProjectDetailState {
  const ProjectDetailLoaded(this.project);
  final ProjectDetail project;
}

final class ProjectDetailEmpty extends ProjectDetailState {
  const ProjectDetailEmpty();
}

final class ProjectDetailError extends ProjectDetailState {
  const ProjectDetailError(this.failure);
  final AppFailure failure;
}
